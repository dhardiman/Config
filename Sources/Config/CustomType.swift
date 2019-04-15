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

    var placeholders: [String] {
        let placeholderRegex = try! NSRegularExpression(pattern: "{(.*?)}", options: [])
        let matches = placeholderRegex.matches(in: initialiser, options: [], range: NSRange(location: 0, length: initialiser.count))
        return matches.map { (initialiser as NSString).substring(with: $0.range(at: 1)) }
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
        var template: String = ""
        if let description = description {
            template += "\(String.indent(for: indentWidth))/// \(description)\n"
        }
        template += "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")static let {key}: {typeName} = {value}"
        return template.replacingOccurrences(of: "{key}", with: key)
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
        switch type.placeholders.count {
        case 0:
            return type.initialiser
        case 1:
            return type.initialiser.replacingOccurrences(of: "{$0}", with: valueString(from: value))
        default:
            let dictionaryValue = value as! [String: Any]
            return type.placeholders.reduce(type.initialiser) { template, placeholder in
                template.replacingOccurrences(of: "{placeholder}", with: valueString(from: dictionaryValue[placeholder] ?? defaultValue))
            }
        }
    }

    private func valueString(from value: Any) -> String {
        if value is String {
            return "\"\(value)\""
        } else {
            return "\(value)"
        }
    }
}
