// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SonyBTKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SonyBTKit", targets: ["Client"]),
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
                .linkedFramework("IOBluetoothUI"),
            ]
        ),
        // Swift façade: observable state + serial actor owning the bridge.
        .target(
            name: "Client",
            dependencies: ["Bridge"],
            path: "Client"
        ),
    ],
    cxxLanguageStandard: .cxx17
)
