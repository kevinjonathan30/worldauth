// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "LAPACKE-iOS",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "LAPACKE-iOS",
            targets: ["LAPACKE", "_LapackeLink"]),
    ],
    dependencies: [.package(path: "../BLAS-LAPACK-AppStore-Workaround")],
    targets: [
        .binaryTarget(name: "LAPACKE", url: "https://github.com/kewlbear/LAPACKE-iOS/releases/download/0.0.20210414/LAPACKE.xcframework.zip", checksum: "22911ba53822023c27eaa6925a197f0ef67da504c9915d39973752fe1f0a5b79"),
        .target(
            name: "_LapackeLink",
            dependencies: ["BLAS-LAPACK-AppStore-Workaround"],
            linkerSettings: [.linkedFramework("Accelerate")]),
    ]
)
