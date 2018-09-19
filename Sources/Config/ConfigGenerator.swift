//
//  main.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

public class ConfigGenerator {

    public init() {}

    public func run(_ arguments: [String]) throws {
        let arguments = Arguments(argumentList: arguments)

        let configFiles = try FileManager.default.contentsOfDirectory(at: arguments.configURL, includingPropertiesForKeys: nil, options: []).filter { $0.pathExtension == "config" }

        let templates: [Template.Type] = [
            EnumConfiguration.self,
            ConfigurationFile.self
        ]

        try configFiles.forEach { url in
            guard let config = dictionaryFromJSON(at: url) else {
                throw ConfigError.badJSON
            }
            guard let template = templates.first(where: { $0.canHandle(config: config) == true }) else { throw ConfigError.noTemplate }
            let configurationFile = try template.init(config: config, name: url.deletingPathExtension().lastPathComponent, scheme: arguments.scheme, source: url.deletingLastPathComponent())
            var swiftOutput: URL
            if let filename = configurationFile.filename {
                swiftOutput = url.deletingLastPathComponent().appendingPathComponent(filename)
            } else {
                swiftOutput = url.deletingPathExtension()
            }
            if let additionalExtension = arguments.additionalExtension {
                swiftOutput.appendPathExtension(additionalExtension)
            }
            swiftOutput.appendPathExtension("swift")
            let newData = configurationFile.description
            if let currentData = try? String(contentsOf: swiftOutput), newData == currentData {
                print("Ignoring \(url.lastPathComponent) as it has not changed")
            } else {
                print("Wrote \(url.lastPathComponent)")
                try configurationFile.description.write(to: swiftOutput, atomically: true, encoding: .utf8)
            }
        }
    }

    public var usage: String {
        return Arguments.Option.all.compactMap { $0.usage }.joined(separator: "\n")
    }
}
