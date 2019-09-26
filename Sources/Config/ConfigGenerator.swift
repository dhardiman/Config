//
//  main.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

public class ConfigGenerator {

    var printer: Printing = Printer()

    public init() {}

    public func run(_ arguments: [String]) throws {
        let arguments = try Arguments(argumentList: arguments)

        let configFiles = try FileManager.default.contentsOfDirectory(at: arguments.configURL, includingPropertiesForKeys: nil, options: []).filter { $0.pathExtension == "config" }

        let templates: [Template.Type] = [
            EnumConfiguration.self,
            ConfigurationFile.self
        ]

        try configFiles.forEach { url in
            if arguments.verbose, let configFileValue = try? String(contentsOf: url) {
                printer.print(message: "Processing config file at \(url.path):\n \(configFileValue)")
            }
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
            var shouldWrite = true
            if arguments.verbose {
                printer.print(message: "Checking existing file at \(swiftOutput.path)")
            }
            if let existingData = try? Data(contentsOf: swiftOutput), let currentData = String(data: existingData, encoding: .utf8) {
                if arguments.verbose {
                    printer.print(message: "Existing file contents: \(currentData)")
                }
                if newData == currentData {
                    shouldWrite = false
                } else {
                    printer.print(message: "Existing file at \(swiftOutput.path) different from new file, writing \(url.lastPathComponent)\nExisting: \(currentData), New: \(newData)")
                }
            } else {
                printer.print(message: "Existing file not present at \(swiftOutput.path), writing \(url.lastPathComponent)")
            }
            if shouldWrite == false {
                printer.print(message: "Ignoring \(url.lastPathComponent) as it has not changed")
            } else {
                do {
                    try configurationFile.description.write(to: swiftOutput, atomically: true, encoding: .utf8)
                    printer.print(message: "Wrote \(url.lastPathComponent) to \(swiftOutput.path)")
                } catch {
                    printer.print(message: "Failed to write to \(swiftOutput.path)")
                    throw error
                }
            }
        }
    }

    public var usage: String {
        return Arguments.Option.all.compactMap { $0.usage }.joined(separator: "\n")
    }
}

protocol Printing {
    func print(message: String)
}

struct Printer: Printing {
    func print(message: String) {
        Swift.print(message)
    }
}
