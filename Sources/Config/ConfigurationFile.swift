//
//  ConfigurationFile.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

private let outputTemplate = """
/* {filename} auto-generated from {scheme} */

{imports}

// swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
public {entityType} {name} {
{contents}
}

// swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

"""

struct Configuration {
    let properties: [String: Property]
    let childConfigurations: [String: Configuration]

    init(config: [String: Any], referenceSource: [String: Any]?, customTypes: [CustomType], defaultType: PropertyType?, commonPatterns: [OverridePattern]) {
        properties = config.reduce([String: Property]()) { properties, pair in
            return parseNextProperty(properties: properties, pair: pair, config: config, referenceSource: referenceSource, customTypes: customTypes, defaultType: defaultType, patterns: commonPatterns)
        }
        childConfigurations = config.reduce([String: Configuration]()) { configurations, pair in
            return parseNextConfiguration(configurations: configurations, pair: pair, config: config, referenceSource: referenceSource, customTypes: customTypes, defaultType: defaultType, patterns: commonPatterns)
        }
    }

    init(properties: [String: Property], childConfigurations: [String: Configuration]) {
        self.properties = properties
        self.childConfigurations = childConfigurations
    }

    private func keyForProperty(_ property: Property, in scheme: String) -> String {
        let key: String
        /// If we've got an associated property attempt to get
        /// its keyValue (it's literal string value).
        if let associatedPropertyKey = property.associatedProperty,
            let keyProvider = properties[associatedPropertyKey] as? AssociatedPropertyKeyProviding {
            key = keyProvider.keyValue(for: scheme)
        } else {
            key = scheme
        }
        return key
    }

    // swiftlint:disable:next identifier_name IV is a well understood abbreviation
    func stringRepresentation(scheme: String, iv: IV, encryptionKey: String?, requiresNonObjcDeclarations: Bool, publicProperties: Bool, indentWidth: Int = 0) -> String {
        let separator = "\n\n"
        let propertiesString = properties.values.map({ $0.propertyDeclaration(for: keyForProperty($0, in: scheme), iv: iv, encryptionKey: encryptionKey, requiresNonObjCDeclarations: requiresNonObjcDeclarations, isPublic: publicProperties, indentWidth: indentWidth) })
            .sorted()
            .joined(separator: separator)

        let configurationsString = childConfigurations.map { (config: (key: String, value: Configuration)) in
            var className = config.key
            let startIndex = className.startIndex
            let firstLetter = className[startIndex]
            className = className.replacingCharacters(in: startIndex...startIndex, with: firstLetter.description.uppercased())
            return """
            \(String.indent(for: indentWidth))public enum \(className) {
            \(config.value.stringRepresentation(scheme: scheme, iv: iv, encryptionKey: encryptionKey, requiresNonObjcDeclarations: requiresNonObjcDeclarations, publicProperties: publicProperties, indentWidth: indentWidth + 1))
            \(String.indent(for: indentWidth))}
            """
        }
        .sorted()
        .joined(separator: separator)

        return [propertiesString, configurationsString].joined(separator: separator).trimmingCharacters(in: .newlines)
    }
}

extension String {
    private static let tabWidth = "    "

    static func indent(for width: Int) -> String {
        var requiredIndent = ""
        for _ in 0...width {
            requiredIndent += String.tabWidth
        }
        return requiredIndent
    }
}

func parseNextProperty(properties: [String: Property], pair: (key: String, value: Any), config: [String: Any], referenceSource: [String: Any]?, customTypes: [CustomType], defaultType: PropertyType?, patterns: [OverridePattern]) -> [String: Property] {
    guard let dict = pair.value as? [String: Any] else {
        return properties
    }
    guard let typeHintValue = (dict["type"] as? String ?? defaultType?.rawValue) else {
        return properties
    }
    var copy = properties
    if let typeHint = PropertyType(rawValue: typeHintValue) {
        switch typeHint {
        case .string, .url, .encrypted, .encryptionKey, .colour, .image, .regex:
            copy[pair.key] = ConfigurationProperty<String>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .optionalString:
            copy[pair.key] = ConfigurationProperty<String?>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .double, .float:
            copy[pair.key] = ConfigurationProperty<Double>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .int:
            copy[pair.key] = ConfigurationProperty<Int>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .optionalInt:
            copy[pair.key] = ConfigurationProperty<Int?>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .dictionary:
            copy[pair.key] = ConfigurationProperty<[String: Any]>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .bool:
            copy[pair.key] = ConfigurationProperty<Bool>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .stringArray:
            copy[pair.key] = ConfigurationProperty<[String]>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        case .reference:
            guard let referenceType = referenceTypeHint(for: dict, in: config, referenceSource: referenceSource) else {
                return properties
            }
            copy[pair.key] = ReferenceProperty(key: pair.key, dict: dict, typeName: referenceType.typeName)
        }
    } else {
        if let customType = customTypes.first(where: { $0.typeName == typeHintValue }) {
            copy[pair.key] = CustomProperty(key: pair.key, customType: customType, dict: dict)
        } else if let customType = customTypes.first(where: { typeHintValue.range(of: #"\[\#($0.typeName)\]"#, options: .regularExpression) != nil }) {
            copy[pair.key] = CustomPropertyArray(key: pair.key, customType: customType, dict: dict)
        }
        else {
            copy[pair.key] = ConfigurationProperty<String>(key: pair.key, typeHint: typeHintValue, dict: dict, patterns: patterns)
        }
    }
    return copy
}

private func referenceTypeHint(for dict: [String: Any], in config: [String: Any], referenceSource: [String: Any]?) -> PropertyType? {
    guard let defaultReference = dict["defaultValue"] as? String,
        let referenceDict = referenceDict(for: defaultReference, from: config, or: referenceSource),
        let referredTypeHint = referenceDict["type"] as? String,
        let referredType = PropertyType(rawValue: referredTypeHint) else {
            return nil
    }
    guard referredType == .reference else { return referredType }
    return referenceTypeHint(for: referenceDict, in: config, referenceSource: referenceSource)
}

private func referenceDict(for key: String, from config: [String: Any], or referenceSource: [String: Any]?) -> [String: Any]? {
    if let dict = config[key] as? [String: Any] {
        return dict
    }
    return referenceSource?[key] as? [String: Any]
}

func parseNextConfiguration(configurations: [String: Configuration], pair: (key: String, value: Any), config: [String: Any], referenceSource: [String: Any]?, customTypes: [CustomType], defaultType: PropertyType?, patterns: [OverridePattern]) -> [String: Configuration] {
    guard let dict = pair.value as? [String: Any], dict["defaultValue"] == nil, pair.key != "template" else {
        return configurations
    }
    var copy = configurations
    copy[pair.key] = Configuration(config: dict, referenceSource: referenceSource, customTypes: customTypes, defaultType: defaultType, commonPatterns: patterns)
    return copy
}

struct ConfigurationFile: Template {
    let scheme: String
    let name: String

    let rootConfiguration: Configuration

    let iv: IV // swiftlint:disable:this identifier_name IV is a well understood abbreviation
    let encryptionKey: String?

    let template: [String: Any]?

    let imports: [String]

    let customTypes: [CustomType]

    let commonPatterns: [OverridePattern]

    let defaultType: PropertyType?

    init(config: [String: Any], name: String, scheme: String, source: URL) throws {
        self.scheme = scheme
        self.name = name

        self.template = config["template"] as? [String: Any]

        self.imports = ["Foundation"] + ((self.template?["imports"] as? [String]) ?? [])

        self.customTypes = CustomType.typeArray(from: self.template)
        self.commonPatterns = OverridePattern.patterns(from: self.template)

        if let defaultType = template?["defaultType"] as? String {
            self.defaultType = PropertyType(rawValue: defaultType)
        } else {
            self.defaultType = nil
        }

        var referenceSource: [String: Any]?
        if let referenceSourceFileName = template?["referenceSource"] as? String {
            let referenceSourceURL = source.appendingPathComponent(referenceSourceFileName).appendingPathExtension("config")
            referenceSource = dictionaryFromJSON(at: referenceSourceURL)
        }

        iv = try IV(dict: config)

        let root = Configuration(config: config, referenceSource: referenceSource, customTypes: customTypes, defaultType: defaultType, commonPatterns: commonPatterns)
        var parsedProperties = root.properties

        encryptionKey = parsedProperties.values.compactMap { $0 as? ConfigurationProperty<String> }
            .first(where: { $0.type == .encryptionKey })?.defaultValue
        if encryptionKey != nil {
            parsedProperties[iv.key] = iv
        }
        if template?["extensionOn"] == nil, let schemeProperty = ConfigurationProperty<String>(key: "schemeName", typeHint: "String", dict: ["defaultValue": scheme], patterns: commonPatterns) {
            parsedProperties[schemeProperty.key] = schemeProperty
        }
        rootConfiguration = Configuration(properties: parsedProperties, childConfigurations: root.childConfigurations)
    }

    static func canHandle(config: [String: Any]) -> Bool {
        return true
    }

    var filename: String? {
        guard let extendedClass = template?["extensionOn"] as? String,
            let extensionName = template?["extensionName"] as? String else {
            return nil
        }
        return "\(extendedClass)+\(extensionName)"
    }

    var description: String {
        let extendedClass = template?["extensionOn"] as? String
        let requiresNonObjcDeclarations = template?["requiresNonObjC"] as? Bool ?? false
        let values = rootConfiguration.stringRepresentation(scheme: scheme, iv: iv, encryptionKey: encryptionKey, requiresNonObjcDeclarations: requiresNonObjcDeclarations, publicProperties: extendedClass == nil)

        let entityType = extendedClass != nil ? "extension" : "enum"
        let importsString = imports.sorted().map { "import \($0)" }.joined(separator: "\n")

        return outputTemplate
            .replacingOccurrences(of: "{filename}", with: "\(filename ?? name).swift")
            .replacingOccurrences(of: "{imports}", with: importsString)
            .replacingOccurrences(of: "{entityType}", with: entityType)
            .replacingOccurrences(of: "{name}", with: extendedClass ?? name)
            .replacingOccurrences(of: "{scheme}", with: scheme)
            .replacingOccurrences(of: "{contents}", with: values)
    }
}
