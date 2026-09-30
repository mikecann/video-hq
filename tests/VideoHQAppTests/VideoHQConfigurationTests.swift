import Foundation
import XCTest
@testable import VideoHQApp

final class VideoHQConfigurationTests: XCTestCase {
    func testDefaultRepoRootIsThisStandalonePackage() {
        let expected = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        XCTAssertEqual(RepoLocator.repoRoot(environment: [:], bundle: .main), expected)
    }

    func testTranscriberCanBeConfiguredWithoutSiblingCheckout() throws {
        let root = URL(fileURLWithPath: "/tmp/video-hq")
        let configuration = try VideoHQConfiguration.load(
            repoRoot: root,
            fallbackDotenvURL: nil,
            environment: ["VIDEO_HQ_TRANSCRIBE_EXECUTABLE": "/tmp/transcribe checkout/transcribe"]
        )
        XCTAssertEqual(configuration.transcribeExecutableURL.path, "/tmp/transcribe checkout/transcribe")
    }

    func testTranscriberIsDiscoveredOnPath() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let launcher = directory.appendingPathComponent("transcribe")
        try Data().write(to: launcher)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcher.path)
        XCTAssertEqual(
            RepoLocator.transcribeExecutableURL(environment: ["PATH": directory.path], bundle: .main),
            launcher
        )
    }

    func testDefaultProjectsRootUsesConvexVideosFolder() {
        let root = RepoLocator.projectsRoot(environment: [:], bundle: .main)

        XCTAssertEqual(
            root,
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("dev/convex/convex-videos", isDirectory: true)
        )
    }

    func testRoughCutToolsCanBeConfiguredFromTheEnvironment() {
        let automationRoot = RepoLocator.filmoraAutomationRoot(
            environment: ["VIDEO_HQ_FILMORA_AUTOMATION_ROOT": "/tmp/filmora-tools"],
            bundle: .main
        )
        let python = RepoLocator.roughCutPythonURL(
            environment: ["VIDEO_HQ_ROUGH_CUT_PYTHON": "/tmp/media-python"],
            bundle: .main
        )

        XCTAssertEqual(automationRoot.path, "/tmp/filmora-tools")
        XCTAssertEqual(python.path, "/tmp/media-python")
    }

    func testConfigurationLoadsQuotedOpenRouterKeyFromRepoDotenv() throws {
        let repoRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: repoRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: repoRoot) }
        try """
        # local tool credentials
        SOMETHING_ELSE=ignored
        OPENROUTER_API_KEY="sk-test-value"
        NOTION_API_KEY='secret-notion-value'
        """.write(
            to: repoRoot.appendingPathComponent(".env"),
            atomically: true,
            encoding: .utf8
        )

        let configuration = try VideoHQConfiguration.load(
            repoRoot: repoRoot,
            projectsRoot: repoRoot.appendingPathComponent("Movies/Projects"),
            environment: [:]
        )

        XCTAssertEqual(configuration.openRouterAPIKey, "sk-test-value")
        XCTAssertEqual(configuration.notionAPIKey, "secret-notion-value")
        XCTAssertEqual(
            configuration.projectsRoot,
            repoRoot.appendingPathComponent("Movies/Projects")
        )
        XCTAssertEqual(
            configuration.transcribeExecutableURL,
            RepoLocator.transcribeExecutableURL(environment: [:], bundle: .main)
        )
    }

    func testConfigurationReadsExplicitCredentialFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let worktree = directory.appendingPathComponent("worktree", isDirectory: true)
        let primary = directory.appendingPathComponent("credentials", isDirectory: true)
        try FileManager.default.createDirectory(at: worktree, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: primary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let primaryDotenv = primary.appendingPathComponent(".env")
        try "OPENROUTER_API_KEY=sk-primary\n".write(
            to: primaryDotenv,
            atomically: true,
            encoding: .utf8
        )

        let configuration = try VideoHQConfiguration.load(
            repoRoot: worktree,
            fallbackDotenvURL: primaryDotenv,
            environment: [:]
        )

        XCTAssertEqual(configuration.openRouterAPIKey, "sk-primary")
    }
}
