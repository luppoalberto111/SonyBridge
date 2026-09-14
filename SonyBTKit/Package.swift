// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SonyBTKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SonyBTKit", targets: ["Client"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", exact: "1.17.1"),
    ],
    targets: [
        // Cross-platform C++ core (protocol, transport framing, models).
        .target(name: "Core", path: "Core"),
        // macOS ObjC++ bridge over the core (Bluetooth picker, command queue).
        .target(
            name: "Bridge",
            dependencies: ["Core"],
            path: "Bridge",
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
            ]
        ),
        // Swift façade: observable state + serial actor owning the bridge.
        .target(
            name: "Client",
            dependencies: [
                "Bridge",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            path: "Client"
        ),
    ],
    cxxLanguageStandard: .cxx17
)
