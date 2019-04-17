//
//  ConfigurationPropertyTests.swift
//  Config
//
//  Created by David Hardiman on 17/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ConfigurationPropertyTests: XCTestCase {
    func givenAStringProperty() -> ConfigurationProperty<String>? {
        return ConfigurationProperty<String>(key: "test", typeHint: "String", dict: [
            "defaultValue": "test value",
            "overrides": [
                "hello": "hello value",
                "pattern": "pattern value"
            ]
        ])
    }

    func whenTheDeclarationIsWritten<T>(for configurationProperty: ConfigurationProperty<T>?, scheme: String = "any", isPublic: Bool = false, requiresNonObjC: Bool = false, indentWidth: Int = 0) throws -> String? {
        let iv = try IV(dict: [:])
        return configurationProperty?.propertyDeclaration(for: scheme, iv: iv, encryptionKey: nil, requiresNonObjCDeclarations: requiresNonObjC, isPublic: isPublic, indentWidth: indentWidth)
    }

    func testItCanWriteADeclarationForAStringPropertyUsingTheDefaultValue() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = #"    static let test: String = "test value""#
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItAddsAPublicAccessorWhenRequired() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = #"    public static let test: String = "test value""#
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty, isPublic: true)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCaIndentADeclaration() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = #"                static let test: String = "test value""#
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty, indentWidth: 3)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItWritesNoObjCPropertiesWhenRequired() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = """
            @nonobjc static var test: String {
                return "test value"
            }
        """
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty, requiresNonObjC: true)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanGetAnOverrideForAnExactMatch() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = #"    static let test: String = "hello value""#
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty, scheme: "hello")
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanGetAnOverrideForAPatternMatch() throws {
        let stringProperty = givenAStringProperty()
        let expectedValue = #"    static let test: String = "pattern value""#
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty, scheme: "match-a-pattern")
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteADescriptionAsAComment() throws {
        let stringProperty = ConfigurationProperty<String>(key: "test", typeHint: "String", dict: [
            "defaultValue": "test value",
            "description": "A comment to add"
        ])
        let expectedValue = """
            /// A comment to add
            static let test: String = "test value"
        """
        let actualValue = try whenTheDeclarationIsWritten(for: stringProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteAURLProperty() throws {
        let urlProperty = ConfigurationProperty<String>(key: "test", typeHint: "URL", dict: [
            "defaultValue": "https://www.google.com",
        ])
        let expectedValue = #"    static let test: URL = URL(string: "https://www.google.com")!"#
        let actualValue = try whenTheDeclarationIsWritten(for: urlProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteAnIntProperty() throws {
        let intProperty = ConfigurationProperty<Int>(key: "test", typeHint: "Int", dict: [
            "defaultValue": 2,
        ])
        let expectedValue = #"    static let test: Int = 2"#
        let actualValue = try whenTheDeclarationIsWritten(for: intProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteADoubleProperty() throws {
        let doubleProperty = ConfigurationProperty<Double>(key: "test", typeHint: "Double", dict: [
            "defaultValue": 2.3,
        ])
        let expectedValue = #"    static let test: Double = 2.3"#
        let actualValue = try whenTheDeclarationIsWritten(for: doubleProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteAFloatProperty() throws {
        let floatProperty = ConfigurationProperty<Double>(key: "test", typeHint: "Float", dict: [
            "defaultValue": 2.3,
        ])
        let expectedValue = #"    static let test: Float = 2.3"#
        let actualValue = try whenTheDeclarationIsWritten(for: floatProperty)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteABoolProperty() throws {
        let floatProperty = ConfigurationProperty<Bool>(key: "test", typeHint: "Bool", dict: [
            "defaultValue": true,
            ])
        let expectedValue = #"    static let test: Bool = true"#
        let actualValue = try whenTheDeclarationIsWritten(for: floatProperty)
        expect(actualValue).to(equal(expectedValue))
    }
}
