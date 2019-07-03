//
//  ConfigurationProperty.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

struct ConfigurationProperty<T>: Property, AssociatedPropertyKeyProviding {
    private enum Failure: Error {
        case notConvertible
    }

    let key: String
    let description: String?
    let type: PropertyType?
    let typeHint: String
    let defaultValue: T
    let associatedProperty: String?
    let overrides: [String: T]
    let patterns: [OverridePattern]

    var typeName: String {
        if let type = type {
            return type.typeName
        } else {
            return typeHint
        }
    }

    /// Returns `value` as the `ConfigurationProperty`'s value type (T).
    /// If T is Optional<Something> and conversion of `value` fails,
    /// rather than throwing an exception and bailing out this method
    /// will return `Optional.none` using `ExpressibleByNilLiteral`'s
    /// init(nilLiteral:), allowing a `ConfigurationProperty` with a nil
    /// value.
    ///
    /// - Parameter value: The value to transform.
    /// - Returns: The value as T, if possible.
    /// - Throws: If the value is not convertible to T, Failure.notConvertible
    ///   will be thrown.
    private static func transformValueToType(value: Any?) throws -> T {
        if let val = value as? T {
            return val
        }
        if let nilLiteralType = T.self as? ExpressibleByNilLiteral.Type {
            return nilLiteralType.init(nilLiteral: ()) as! T
        }

        throw Failure.notConvertible
    }

    init?(key: String, typeHint: String, dict: [String: Any], patterns: [OverridePattern] = []) {
        do {
            self.defaultValue = try ConfigurationProperty.transformValueToType(value: dict["defaultValue"])
            
            self.key = key
            self.typeHint = typeHint
            self.associatedProperty = dict["associatedProperty"] as? String
            self.type = PropertyType(rawValue: typeHint)
            self.description = dict["description"] as? String
            self.patterns = patterns

            let overrides = try? dict["overrides"]
                .flatMap { $0 as? [String: Any] }?
                .mapValues { try ConfigurationProperty.transformValueToType(value: $0) }

            self.overrides = overrides ?? [:]
        } catch {
            return nil
        }
    }

    private func pattern(for override: String) -> String {
        guard let pattern = patterns.first(where: { $0.alias == override }) else {
            return override
        }
        return pattern.pattern
    }

    func value(for configName: String) -> T {

        if let override = overrides.first(where: { item in
            if associatedProperty != nil {
                return item.key == configName
            }
            return configName.range(of: pattern(for: item.key), options: .regularExpression) != nil
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
            \(String.indent(for: indentWidth))@nonobjc\(isPublic ? " public" : "") static var {key}: {typeName} {
            \(String.indent(for: indentWidth + 1))return {value}
            \(String.indent(for: indentWidth))}
            """
        } else {
            template += "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")static let {key}: {typeName} = {value}"
        }
        let propertyValue = value(for: configName)
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

    func keyValue(for configName: String) -> String {
        let overrideValue = overrides.first(where: { configName.range(of: pattern(for: $0.key), options: .regularExpression) != nil })?.value ?? defaultValue
        guard let value = overrideValue as? String else {
            fatalError("Cannot retrieve keyValue for type \(T.self). Type must be String.")
        }
        return value
    }
}
