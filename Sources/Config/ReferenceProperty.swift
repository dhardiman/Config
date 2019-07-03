//
//  ReferenceProperty.swift
//  Config
//
//  Created by David Hardiman on 17/01/2018.
//

import Foundation

struct ReferenceProperty: Property {
    let key: String
    let defaultValue: String
    let typeName: String
    let overrides: [String: String]
    let associatedProperty: String? = nil
    let description: String?

    init?(key: String, dict: [String: Any], typeName: String) {
        guard let defaultValue = dict["defaultValue"] as? String else {
            return nil
        }
        self.key = key
        self.defaultValue = defaultValue
        self.typeName = typeName
        if let overrides = dict["overrides"] as? [String: String] {
            self.overrides = overrides
        } else {
            self.overrides = [:]
        }
        self.description = dict["description"] as? String
    }

    func value(for configName: String) -> String {
        if let override = overrides.first(where: { item in
            return configName.range(of: item.key, options: .regularExpression) != nil
        }) {
            return override.value
        }
        return defaultValue
    }

    func propertyDeclaration(for configName: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, indentWidth: Int) -> String {
        var template: String = ""
        if let description = description {
            template += "\(String.indent(for: indentWidth))/// \(description)\n"
        }
        if requiresNonObjCDeclarations {
            template += """
            \(String.indent(for: indentWidth))@nonobjc\(isPublic ? " public" : "") static var \(key): \(typeName) {
            \(String.indent(for: indentWidth + 1))return \(value(for: configName))
            \(String.indent(for: indentWidth))}
            """
        } else {
            template += "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")static let \(key): \(typeName) = \(value(for: configName))"
        }
        return template
    }
}
