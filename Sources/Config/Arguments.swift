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
    let verbose: Bool
}

extension Arguments {

    enum Option: String {
        case scheme = "--scheme"
        case configPath = "--configPath"
        case additionalExtension = "--ext"
        case verbose = "--verbose"

        static let all: [Option] = [.scheme, .configPath, .additionalExtension, .verbose]

        var usage: String {
            switch self {
            case .scheme:
                return "\(rawValue)\t\t(Required) The scheme to generate for"
            case .configPath:
                return "\(rawValue)\t\t(Required) The path to the configuration files"
            case .additionalExtension:
                return "\(rawValue)\t\t(Optional) An additional extension slug to add before .swift in the output files. Useful for .gitignore"
            case .verbose:
                return "\(rawValue)\t\t(Optional) Should extra logging be output?"
            }
        }
    }

    struct MissingArgumentError: Error {
        let missingArguments: [String]
    }

    init(argumentList: [String] = CommandLine.arguments) throws {
        let argumentPairs: [Arguments.Option: String] = argumentList.arguments()

        guard let scheme = argumentPairs[.scheme],
            let configPath = argumentPairs[.configPath] else {
            let missingArgs = [
                argumentPairs.keys.contains(.scheme) ? nil : "scheme",
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

        self.scheme = scheme
        self.configURL = URL(fileURLWithPath: configPath)
        self.additionalExtension = argumentPairs[.additionalExtension]
        self.verbose = argumentPairs[.verbose] == "true"
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
