//
//  EnumConfiguration.swift
//  Config
//
//  Created by David Hardiman on 22/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

private let template = """
/* {filename} auto-generated from {configName} */
import Foundation

public enum {filename}: {type} {
{contents}
}

"""

struct EnumConfiguration: Template {
    enum EnumError: Error {
        case noType
        case unknownType
    }

    let name: String
    let configName: String
    let type: String

    let properties: [String: Property]

    init(config: [String: Any], name: String, configName: String, source: URL) throws {
        self.name = name
        self.configName = configName
        guard let template = config["template"] as? [String: String],
            let type = template["rawType"] else { throw EnumError.noType }
        self.type = type

        self.properties = try config.reduce([String: Property]()) { (properties, pair: (key: String, value: Any)) in
            guard let dict = pair.value as? [String: Any] else {
                return properties
            }
            var copy = properties
            switch type {
            case "String":
                copy[pair.key] = ConfigurationProperty<String>(key: pair.key, typeHint: "", dict: dict, patterns: OverridePattern.patterns(from: template))
            default: throw EnumError.unknownType
            }
            return copy
        }
    }

    static func canHandle(config: [String: Any]) -> Bool {
        guard let template = config["template"] as? [String: String] else { return false }
        return template["name"] == "enum"
    }

    var description: String {
        let propertyDeclarations = properties.compactMap { property -> String? in
            guard let configProperty = property.value as? ConfigurationProperty<String> else { return nil }
            let value = configProperty.value(for: self.configName)
            return "    case \(configProperty.key)" + (value.isEmpty ? "" : ##" = #"\##(value)"#"##)
        }
        .sorted()
        .joined(separator: "\n")
        return template.replacingOccurrences(of: "{filename}", with: name)
            .replacingOccurrences(of: "{configName}", with: configName)
            .replacingOccurrences(of: "{type}", with: type)
            .replacingOccurrences(of: "{contents}", with: propertyDeclarations)
    }
}
