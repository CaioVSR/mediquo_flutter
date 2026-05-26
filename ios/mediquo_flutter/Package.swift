// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "mediquo_flutter",
  platforms: [
    .iOS("17.0")
  ],
  products: [
    .library(name: "mediquo-flutter", targets: ["mediquo_flutter"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(
      url: "https://github.com/mediquo/mediquo-ios-sdk.git",
      from: "26.1.2"
    )
  ],
  targets: [
    .target(
      name: "mediquo_flutter",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "MediQuoSDK", package: "mediquo-ios-sdk")
      ]
    )
  ]
)
