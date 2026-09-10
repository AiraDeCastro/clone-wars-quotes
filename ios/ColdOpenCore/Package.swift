// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ColdOpenCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "ColdOpenCore", targets: ["ColdOpenCore"])
    ],
    targets: [
        .target(
            name: "ColdOpenCore",
            resources: [.copy("Resources/quotes.json")]
        ),
        .testTarget(
            name: "ColdOpenCoreTests",
            dependencies: ["ColdOpenCore"]
        ),
    ]
)
