// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mozjpeg",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "mozjpeg",
            targets: ["mozjpeg"]),
    ],
    targets: [
        .target(
            name: "mozjpeg",
            dependencies: [
                .target(name: "mozjpegc")
            ]),
        .target(
            name: "mozjpegc",
            dependencies: ["libturbojpeg"],
            path: "Sources/mozjpegc",
            sources: [
                "JPEGCompression.mm",
                "MJEncoder.mm",
                "MozjpegImage.mm"
            ], publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
            ],
            linkerSettings: [.linkedFramework("Accelerate")]),
        .binaryTarget(name: "libturbojpeg", path: "Sources/libturbojpeg.xcframework")
    ]
)
