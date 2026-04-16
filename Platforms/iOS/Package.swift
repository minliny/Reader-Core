// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReaderIOSShell",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ReaderIOSShell",
            targets: ["ReaderIOSShell"]
        ),
        .executable(
            name: "ReaderIOSShellDemo",
            targets: ["ReaderIOSShellDemo"]
        )
    ],
    dependencies: [
        .package(name: "ReaderCore", path: "../..")
    ],
    targets: [
        .target(
            name: "ReaderIOSShell",
            dependencies: [
                .product(name: "ReaderCoreModels",    package: "ReaderCore"),
                .product(name: "ReaderCoreProtocols", package: "ReaderCore"),
                .product(name: "ReaderCoreParser",    package: "ReaderCore"),
                .product(name: "ReaderCoreNetwork",   package: "ReaderCore"),
                .product(name: "ReaderPlatformAdapters", package: "ReaderCore")
            ]
        ),
        .executableTarget(
            name: "ReaderIOSShellDemo",
            dependencies: [
                .product(name: "ReaderCoreModels",    package: "ReaderCore"),
                .product(name: "ReaderCoreProtocols", package: "ReaderCore"),
                .product(name: "ReaderCoreParser",    package: "ReaderCore"),
                .product(name: "ReaderCoreNetwork",   package: "ReaderCore"),
                .product(name: "ReaderPlatformAdapters", package: "ReaderCore")
            ]
        )
    ]
)
