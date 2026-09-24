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
        .package(path: "../lib/PrompterKit")
    ],
    targets: [
        .executableTarget(
            name: "VideoHQApp",
            dependencies: [
                .product(name: "PrompterKit", package: "PrompterKit")
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
