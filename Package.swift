// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyFlowAI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StudyFlowAI",
            targets: ["StudyFlowAI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StudyFlowAI",
            dependencies: [],
            path: ".",
            exclude: ["Package.swift", "README.md"],
            sources: [
                "StudyFlowAIApp.swift",
                "Models",
                "ViewModels",
                "Services",
                "Views",
                "Components",
                "Widgets",
                "Preview Content"
            ]
        )
    ]
)
