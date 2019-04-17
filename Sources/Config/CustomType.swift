//
//  CustomType.swift
//  Config
//
//  Created by David Hardiman on 15/04/2019.
//

import Foundation

struct CustomType {
    let typeName: String
    let initialiser: String

    init?(source: [String: Any]) {
        guard let typeName = source["typeName"] as? String,
              let initialiser = source["initialiser"] as? String else {
            return nil
        }
        self.typeName = typeName
        self.initialiser = initialiser
    }

    static func typeArray(from template: [String: Any]?) -> [CustomType] {
        guard let types = template?["customTypes"] as? [[String: Any]] else {
            return []
        }
        return types.compactMap { CustomType(source: $0) }
    }

    var placeholders: [Placeholder] {
        let placeholderRegex = try! NSRegularExpression(pattern: #"\{(.*?)\}"#, options: [])
        let matches = placeholderRegex.matches(in: initialiser, options: [], range: NSRange(location: 0, length: initialiser.count))
        return matches.map { Placeholder(placeholder: (initialiser as NSString).substring(with: $0.range(at: 1))) }
    }
}

struct CustomProperty: Property {
    let associatedProperty: String? = nil

    let key: String
    let description: String?
    let customType: CustomType
    let defaultValue: Any
    let overrides: [String: Any]

    init(key: String, customType: CustomType, dict: [String: Any]) {
        self.key = key
        self.customType = customType
        self.description = dict["description"] as?  String
        self.defaultValue = dict["defaultValue"]!
        self.overrides =  (dict["overrides"] as? [String: Any]) ?? [:]
    }

    var typeName: String {
        return customType.typeName
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, indentWidth: Int) -> String {
        return template(for: description, isPublic: isPublic, indentWidth: indentWidth).replacingOccurrences(of: "{key}", with: key)
            .replacingOccurrences(of: "{typeName}", with: typeName)
            .replacingOccurrences(of: "{value}", with: outputValue(for: scheme, type: customType))
    }

    private func outputValue(for scheme: String, type: CustomType) -> String {
        let value: Any
        if let override = overrides[scheme] {
            value = override
        } else {
            value = defaultValue
        }
        let template = CustomPropertyValue(value: value)
        return template.outputValue(for: scheme, type: type)
    }
}

struct CustomPropertyArray: Property {
    let associatedProperty: String? = nil

    let key: String
    let description: String?
    let customType: CustomType
    let defaultValue: [Any]
    let overrides: [String: [Any]]

    init(key: String, customType: CustomType, dict: [String: Any]) {
        self.key = key
        self.customType = customType
        self.description = dict["description"] as?  String
        self.defaultValue = dict["defaultValue"]! as! [Any]
        self.overrides =  (dict["overrides"] as? [String: [Any]]) ?? [:]
    }

    var typeName: String {
        return "[\(customType.typeName)]"
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, indentWidth: Int) -> String {
        return template(for: description, isPublic: isPublic, indentWidth: indentWidth).replacingOccurrences(of: "{key}", with: key)
            .replacingOccurrences(of: "{typeName}", with: typeName)
            .replacingOccurrences(of: "{value}", with: outputValue(for: scheme, type: customType))
    }

    private func outputValue(for scheme: String, type: CustomType) -> String {
        let value: [Any]
        if let override = overrides.first(where: { scheme.range(of: $0.key, options: .regularExpression) != nil }) {
            value = override.value
        } else {
            value = defaultValue
        }
        return "[" + value.map { CustomPropertyValue(value: $0).outputValue(for: scheme, type: type) }
            .joined(separator: ", ") + "]"
    }
}

private func valueString(from value: Any?) -> String {
    guard let value = value else { return "" }
    return "\(value)"
}

private func valueString(for placeholder: Placeholder, from dictionary: [String: Any]) -> String {
    guard let value = dictionary[placeholder.name], let unusedIV = try? IV(dict: dictionary) else { return "" }
    if let type = placeholder.type {
        return type.valueDeclaration(for: value, iv: unusedIV, key: nil)
    } else {
        return "\(value)"
    }
}

private func template(for description: String?, isPublic: Bool, indentWidth: Int) -> String {
    var template: String = ""
    if let description = description {
        template += "\(String.indent(for: indentWidth))/// \(description)\n"
    }
    template += "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")static let {key}: {typeName} = {value}"
    return template
}

private struct CustomPropertyValue {
    let value: Any

    func outputValue(for scheme: String, type: CustomType) -> String {
        switch type.placeholders.count {
        case 0:
            return type.initialiser
        case 1:
            return type.initialiser.replacingOccurrences(of: "{$0}", with: valueString(from: value))
        default:
            let dictionaryValue = value as! [String: Any]
            return type.placeholders.reduce(type.initialiser) { template, placeholder in
                template.replacingOccurrences(of: "\(placeholder)", with: valueString(for: placeholder, from: dictionaryValue))
            }
        }
    }
}

struct Placeholder: CustomStringConvertible {
    let name: String
    let type: PropertyType?

    init(placeholder: String) {
        let split = placeholder.split(separator: ":")
        name = String(split[0])
        if split.count == 2 {
            type = PropertyType(rawValue: String(split[1]))
        } else {
            type = nil
        }
    }

    var description: String {
        let typeAnnotation: String
        if let type = type {
            typeAnnotation = ":\(type.rawValue)"
        } else {
            typeAnnotation = ""
        }
        return "{\(name)\(typeAnnotation)}"
    }
}
