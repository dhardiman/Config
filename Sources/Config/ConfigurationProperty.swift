//
//  ConfigurationProperty.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

struct ConfigurationProperty<T>: Property, AssociatedPropertyKeyProviding {

    let key: String
    let description: String?
    let type: PropertyType?
    let typeHint: String
    let defaultValue: T
    let associatedProperty: String?
    let overrides: [String: T]

    var typeName: String {
        if let type = type {
            return type.typeName
        } else {
            return typeHint
        }
    }

    init?(key: String, typeHint: String, dict: [String: Any]) {
        guard let defaultValue = dict["defaultValue"] as? T else {
            return nil
        }
        self.key = key
        self.typeHint = typeHint
        self.associatedProperty = dict["associatedProperty"] as? String
        self.type = PropertyType(rawValue: typeHint)
        self.defaultValue = defaultValue
        if let overrides = dict["overrides"] as? [String: T] {
            self.overrides = overrides
        } else {
            self.overrides = [:]
        }
        self.description = dict["description"] as? String
    }

    func value(for scheme: String) -> T {
        if let override = overrides.first(where: { item in
            if associatedProperty != nil {
                return item.key == scheme
            }
            return scheme.range(of: item.key, options: .regularExpression) != nil
        }) {
            return override.value
        }
        return defaultValue
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, indentWidth: Int) -> String {
        var template: String = ""
        if let description = description {
            template += "\(String.indent(for: indentWidth))/// \(description)\n"
        }
        if requiresNonObjCDeclarations {
            template += """
            \(String.indent(for: indentWidth))@nonobjc\(isPublic ? " public" : "") static var {key}: {typeName} {
            \(String.indent(for: indentWidth + 1))return {value}
            \(String.indent(for: indentWidth))}
            """
        } else {
            template += "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")static let {key}: {typeName} = {value}"
        }
        let propertyValue = value(for: scheme)
        let outputValue: String
        if let type = type {
            outputValue = type.valueDeclaration(for: propertyValue, iv: iv, key: encryptionKey)
        } else {
            outputValue = "\(propertyValue)"
        }
        return template.replacingOccurrences(of: "{key}", with: key)
            .replacingOccurrences(of: "{typeName}", with: typeName)
            .replacingOccurrences(of: "{value}", with: outputValue)
    }

    func keyValue(for scheme: String) -> String {
        let overrideValue = overrides.first(where: { scheme.range(of: $0.key, options: .regularExpression) != nil })?.value ?? defaultValue
        guard let value = overrideValue as? String else {
            fatalError("Cannot retrieve keyValue for type \(T.self). Type must be String.")
        }
        return value
    }
}
