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
    case url = "URL"
    case encrypted = "Encrypted"
    case encryptionKey = "EncryptionKey"
    case int = "Int"
    case double = "Double"
    case float = "Float"
    case dictionary = "Dictionary"
    case bool = "Bool"
    case stringArray = "[String]"
    case colour = "Colour"
    case reference = "Reference"
    case image = "Image"

    var typeName: String {
        switch self {
        case .encrypted, .encryptionKey:
            return "[UInt8]"
        case .dictionary:
            return "[String: Any]"
        case .colour:
            return "UIColor"
        case .image:
            return "UIImage"
        default:
            return rawValue
        }
    }

    func valueDeclaration(for value: Any, iv: IV, key: String?) -> String {
        let stringValue = {
            #""\#(value)""#
        }
        switch self {
        case .string:
            return stringValue()
        case .url:
            return "URL(string: \(stringValue()))!"
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
            return "UIImage(named: \(stringValue()))!"
        case .bool:
            return "\(value as! Bool)"
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
}
