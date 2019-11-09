// swift-tools-version:5.0
//
//  Package.swift
//  SwiftyBot
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 - 2019 Fabrizio Brancati.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import PackageDescription

public let package = Package(
    name: "SwiftyBot",
    platforms: [
        .macOS(.v10_14)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "3.3.0")),
        .package(url: "https://github.com/FabrizioBrancati/BFKit-Swift.git", .upToNextMinor(from: "6.0.0"))
    ],
    targets: [
        .target(name: "SwiftyBot", dependencies: ["Bot"]),
        .target(name: "Bot", dependencies: [
            "Vapor",
            "Telegram",
            "Messenger",
            "Assistant"
        ]),
        .target(name: "Telegram", dependencies: [
            "Vapor",
            "BFKit",
            "Helper"
        ]),
        .target(name: "Messenger", dependencies: [
            "Vapor",
            "BFKit",
            "Helper"
        ]),
        .target(name: "Assistant", dependencies: [
            "Vapor",
            "BFKit",
            "Helper"
        ]),
        .target(name: "Helper"),
        .testTarget(name: "BotTests", dependencies: [
            "Bot",
            "Vapor",
            "Telegram",
            "Messenger"
        ]),
        .testTarget(name: "TelegramTests", dependencies: ["Telegram"]),
        .testTarget(name: "MessengerTests", dependencies: ["Messenger"]),
        .testTarget(name: "AssistantTests", dependencies: ["Assistant"]),
        .testTarget(name: "HelperTests", dependencies: ["Helper"])
    ]
)
