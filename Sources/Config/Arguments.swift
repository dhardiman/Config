//
//  Arguments.swift
//  Config
//
//  Created by Sebastian Skuse on 31/07/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

struct Arguments {
    let name: String
    let configURL: URL
    let additionalExtension: String?
}

extension Arguments {

    enum Option: String {
        case configName = "--name"
        case configPath = "--configPath"
        case additionalExtension = "--ext"

        static let all: [Option] = [.configName, .configPath, .additionalExtension]

        var usage: String {
            switch self {
            case .configName:
                return "\(rawValue)\t\t(Required) The configuration to generate for"
            case .configPath:
                return "\(rawValue)\t\t(Required) The path to the configuration files"
            case .additionalExtension:
                return "\(rawValue)\t\t(Optional) An additional extension slug to add before .swift in the output files. Useful for .gitignore"
            }
        }
    }

    struct MissingArgumentError: Error {
        let missingArguments: [String]
    }

    init(argumentList: [String] = CommandLine.arguments) throws {
        let argumentPairs: [Arguments.Option: String] = argumentList.arguments()

        guard let name = argumentPairs[.configName],
            let configPath = argumentPairs[.configPath] else {
            let missingArgs = [
                argumentPairs.keys.contains(.configName) ? nil : "name",
                argumentPairs.keys.contains(.configPath) ? nil : "configPath"
            ].compactMap { $0 }
            let lines: [String] = [
                "Required arguments not provided: \(missingArgs.joined(separator: ", "))",
                "Usage:",
                Arguments.Option.all.compactMap { $0.usage }.joined(separator: "\n")
            ]
            print(lines.joined(separator: "\n"))
            throw MissingArgumentError(missingArguments: missingArgs)
        }

        self.name = name
        self.configURL = URL(fileURLWithPath: configPath)
        self.additionalExtension = argumentPairs[.additionalExtension]
    }
}

extension Array where Element == String {

    public func arguments<T>() -> [T: Element] where T: RawRepresentable, T: Hashable, T.RawValue == String {
        let args = Array(suffix(from: 1))
        var arguments: [T: Element] = [:]

        stride(from: 0, to: args.count, by: 2).forEach { index in
            if let key = T(rawValue: args[index]) {
                if index + 1 < args.count {
                    let value = args[index + 1]
                    arguments[key] = value
                }
            }
        }
        return arguments
    }
}
