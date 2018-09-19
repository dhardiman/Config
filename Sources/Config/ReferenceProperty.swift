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
    }

    func value(for scheme: String) -> String {
        if let override = overrides.first(where: { item in
            return scheme.range(of: item.key, options: .regularExpression) != nil
        }) {
            return override.value
        }
        return defaultValue
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, indentWidth: Int) -> String {
        if requiresNonObjCDeclarations {
            return """
            \(String.indent(for: indentWidth))@nonobjc public static var \(key): \(typeName) {
            \(String.indent(for: indentWidth + 1))return \(value(for: scheme))
            \(String.indent(for: indentWidth))}
            """
        } else {
            return "\(String.indent(for: indentWidth))public static let \(key): \(typeName) = \(value(for: scheme))"
        }
    }
}
