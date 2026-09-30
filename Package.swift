// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VideoHQ",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "video-hq", targets: ["VideoHQApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/mikecann/prompter-kit.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "VideoHQApp",
            dependencies: [
                .product(name: "PrompterKit", package: "prompter-kit")
            ],
            path: "Sources/VideoHQApp"
        ),
        .testTarget(
            name: "VideoHQAppTests",
            dependencies: ["VideoHQApp"],
            path: "tests/VideoHQAppTests"
        )
    ]
)
