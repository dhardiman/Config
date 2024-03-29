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

    func value(for scheme: String) -> T {
        if let override = overrides.first(where: { item in
            if associatedProperty != nil {
                return item.key == scheme
            }
            return scheme.range(of: pattern(for: item.key), options: .regularExpression) != nil
        }) {
            return override.value
        }
        return defaultValue
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, instanceProperty: Bool, indentWidth: Int, generationBehaviour: GenerationBehaviour) -> String {
        var template: String = ""
        if let description = description {
            template += "\(String.indent(for: indentWidth))/// \(description)\n"
        }
        if requiresNonObjCDeclarations {
            template += computedProperty(nonObjc: true, indentWidth: indentWidth, isPublic: isPublic, instanceProperty: instanceProperty, outputProvidesReturn: type?.valueProvidesReturn ?? false)
        } else {
            template += (type?.computedProperty ?? false) ?
                computedProperty(nonObjc: false, indentWidth: indentWidth, isPublic: isPublic, instanceProperty: instanceProperty, outputProvidesReturn: type?.valueProvidesReturn ?? false) :
                storedProperty(indentWidth: indentWidth, isPublic: isPublic, instanceProperty: instanceProperty)
        }
        let propertyValue = value(for: scheme)
        let outputValue: String
        if let type = type {
            outputValue = type.valueDeclaration(for: propertyValue, iv: iv, key: encryptionKey, generationBehaviour: generationBehaviour)
        } else {
            outputValue = "\(propertyValue)"
        }
        return template.replacingOccurrences(of: "{key}", with: key)
            .replacingOccurrences(of: "{typeName}", with: typeName)
            .replacingOccurrences(of: "{value}", with: reindent(value: outputValue, to: indentWidth))
    }

    private func reindent(value: String, to indentWidth: Int) -> String {
        let split = value.split(separator: "\n")
        guard split.count > 1 else { return value }
        return split.enumerated().map {
            guard $0.offset > 0 else { return String($0.element) }
            return String.indent(for: indentWidth + 1) + $0.element
        }
        .joined(separator: "\n")
    }

    func keyValue(for scheme: String) -> String {
        let overrideValue = overrides.first(where: { scheme.range(of: pattern(for: $0.key), options: .regularExpression) != nil })?.value ?? defaultValue
        guard let value = overrideValue as? String else {
            fatalError("Cannot retrieve keyValue for type \(T.self). Type must be String.")
        }
        return value
    }

    private func computedProperty(nonObjc: Bool, indentWidth: Int, isPublic: Bool, instanceProperty: Bool, outputProvidesReturn: Bool) -> String {
        let modifiers = [
            nonObjc ? "@nonobjc" : nil,
            isPublic ? "public" : nil,
            (instanceProperty ? "" : "static"),
            "var"
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        return """
        \(String.indent(for: indentWidth))\(modifiers) {key}: {typeName} {
        \(String.indent(for: indentWidth + 1))\(outputProvidesReturn ? "" : "return "){value}
        \(String.indent(for: indentWidth))}
        """
    }

    private func storedProperty(indentWidth: Int, isPublic: Bool, instanceProperty: Bool) -> String {
        return "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")\(instanceProperty ? "" : "static ")let {key}: {typeName} = {value}"
    }
}
