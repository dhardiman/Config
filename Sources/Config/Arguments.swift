//
//  Arguments.swift
//  Config
//
//  Created by Sebastian Skuse on 31/07/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

struct Arguments {
    let scheme: String
    let configURL: URL
    let additionalExtension: String?
}

extension Arguments {

    enum Option: String {
        case scheme = "--scheme"
        case configPath = "--configPath"
        case additionalExtension = "--ext"

        static let all: [Option] = [.scheme, .configPath, .additionalExtension]

        var usage: String {
            switch self {
            case .scheme:
                return "\(rawValue)\t\t(Required) The scheme to generate for"
            case .configPath:
                return "\(rawValue)\t\t(Required) The path to the configuration files"
            case .additionalExtension:
                return "\(rawValue)\t\t(Optional) An additional extension slug to add before .swift in the output files. Useful for .gitignore"
            }
        }
    }

    init(argumentList: [String] = CommandLine.arguments) {
        let argumentPairs: [Arguments.Option: String] = argumentList.arguments()

        guard let scheme = argumentPairs[.scheme],
            let configPath = argumentPairs[.configPath] else {
            let lines: [String] = [
                "Required arguments not provided.",
                "Usage:",
                Arguments.Option.all.compactMap { $0.usage }.joined(separator: "\n")
            ]
            print(lines.joined(separator: "\n"))
            exit(1)
        }

        self.scheme = scheme
        self.configURL = URL(fileURLWithPath: configPath)
        self.additionalExtension = argumentPairs[.additionalExtension]
    }
}
