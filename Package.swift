// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WageTimeCalculator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WageTimeCalculator",
            targets: ["WageTimeCalculator"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WageTimeCalculator",
            path: "WageTimeCalculator"
        )
    ]
)
