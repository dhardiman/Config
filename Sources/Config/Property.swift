//
//  Property.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

protocol AssociatedPropertyKeyProviding {
    func keyValue(for scheme: String) -> String
}

protocol Property {
    var key: String { get }
    var typeName: String { get }
    var associatedProperty: String? { get }
    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, indentWidth: Int) -> String
}

private func dictionaryValue(_ dict: [String: Any]) -> String {
    let values = dict.sorted { $0.key < $1.key }
        .map { (key, value) -> String in
        let updatedValue: Any
        switch value {
        case is String:
            updatedValue = #""\#(value)""#
        case is NSNumber:
            updatedValue = numericValue(value as! NSNumber)
        case is [String: Any]:
            updatedValue = dictionaryValue(value as! [String: Any])
        default:
            updatedValue = value
        }
        return #""\#(key)": \#(updatedValue)"#
    }
    let contents = values.joined(separator: ", ")
    return "[\(contents.count > 0 ? contents : ":")]"
}

private func numericValue(_ number: NSNumber) -> Any {
    if case .charType = CFNumberGetType(number) {
        return number.boolValue
    }
    return number
}

func byteArrayOutput(from: [UInt8]) -> String {
    let transformedByteArray: [String] = from.map { "UInt8(\($0))" }
    return "[\(transformedByteArray.joined(separator: ", "))]"
}

enum PropertyType: String {
    case string = "String"
    case optionalString = "String?"
    case url = "URL"
    case encrypted = "Encrypted"
    case encryptionKey = "EncryptionKey"
    case int = "Int"
    case optionalInt = "Int?"
    case double = "Double"
    case float = "Float"
    case dictionary = "Dictionary"
    case bool = "Bool"
    case stringArray = "[String]"
    case colour = "Colour"
    case reference = "Reference"
    case image = "Image"
    case regex = "Regex"
    case dynamicColour = "DynamicColour"
    case dynamicColourReference = "DynamicColourReference"

    var typeName: String {
        switch self {
        case .encrypted, .encryptionKey:
            return "[UInt8]"
        case .dictionary:
            return "[String: Any]"
        case .colour, .dynamicColour, .dynamicColourReference:
            return "UIColor"
        case .image:
            return "UIImage"
        case .regex:
            return "NSRegularExpression"
        default:
            return rawValue
        }
    }

    var computedProperty: Bool {
        switch self {
        case .dynamicColour, .dynamicColourReference:
            return true
        default:
            return false
        }
    }

    var valueProvidesReturn: Bool {
        switch self {
        case .dynamicColour, .dynamicColourReference:
            return true
        default:
            return false
        }
    }

    func valueDeclaration(for value: Any, iv: IV, key: String?) -> String {
        let stringValueAllowingOptional = { (optional: Bool) -> String in
            if let string = value as? String {
                return string.isEmpty ? "\"\"" : "#\"\(string)\"#"
            } else if optional {
                return "nil"
            }
            return "#\"\(value)\"#"
        }
        switch self {
        case .string:
            return stringValueAllowingOptional(false)
        case .optionalString:
            return stringValueAllowingOptional(true)
        case .url:
            return #"URL(string: "\#(value)")!"#
        case .encryptionKey:
            return byteArrayOutput(from: Array("\(value)".utf8))
        case .encrypted:
            guard let key = key else { fatalError("No encryption key present to encrypt value") }
            guard let valueString = value as? String, let encryptedString = valueString.encrypt(key: Array(key.utf8), iv: Array(iv.hash.utf8)) else {
                fatalError("Unable to encrypt \(value) with key")
            }
            return byteArrayOutput(from: encryptedString)
        case .dictionary:
            return dictionaryValue((value as? [String: Any]) ?? [:])
        case .colour:
            return colourValue(for: value as? String)
        case .image:
            return #"UIImage(named: "\#(value)")!"#
        case .bool:
            return "\(value as! Bool)"
        case .regex:
            return "try! NSRegularExpression(pattern: \(stringValueAllowingOptional(false)), options: [])"
        case .optionalInt:
            if let int = value as? Int {
                return "\(int)"
            } else {
                return "\(value)"
            }
        case .dynamicColour:
            return dynamicColourValue(for: value as? [String: String])
        case .dynamicColourReference:
            return dynamicColourReferenceValue(for: value as? [String: String])
        default:
            return "\(value)"
        }
    }

    private func colourValue(for value: String?) -> String {
        guard let value = value else { return "No colour provided" }
        let string = value.replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt32 = 0
        Scanner(string: string).scanHexInt32(&rgbValue)
        if string.count == 2 {
            return "UIColor(white: \(CGFloat(rgbValue)) / 255.0, alpha: 1.0)"
        } else {
            return "UIColor(red: \(CGFloat((rgbValue & 0xFF0000) >> 16)) / 255.0, green: \(CGFloat((rgbValue & 0x00FF00) >> 8)) / 255.0, blue: \(CGFloat(rgbValue & 0x0000FF)) / 255.0, alpha: 1.0)"
        }
    }

    private func dynamicColourOutput(from value: [String: String]?, transform: ((String) -> String)? = nil) -> String {
        guard let value = value, let light = value["light"], let dark = value["dark"] else {
            return "Invalid dictionary. Should have a 'light' and a 'dark' value"
        }
        let lightOutput: String
        let darkOutput: String
        if let transform = transform {
            lightOutput = transform(light)
            darkOutput = transform(dark)
        } else {
            lightOutput = light
            darkOutput = dark
        }
        return dynamicColourOutputFor(light: lightOutput, dark: darkOutput)
    }

    private func dynamicColourOutputFor(light: String, dark: String) -> String {
        return """
        if #available(iOS 13, *) {
            return UIColor(dynamicProvider: {
                if $0.userInterfaceStyle == .dark {
                    return \(dark)
                } else {
                    return \(light)
                }
            })
        } else {
            return \(light)
        }
        """
    }

    private func dynamicColourValue(for value: [String: String]?) -> String {
        return dynamicColourOutput(from: value) { self.colourValue(for: $0) }
    }

    private func dynamicColourReferenceValue(for value: [String: String]?) -> String {
        return dynamicColourOutput(from: value, transform: nil)
    }
}
