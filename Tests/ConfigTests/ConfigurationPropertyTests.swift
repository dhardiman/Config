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

    func whenTheDeclarationIsWritten<T>(for configurationProperty: ConfigurationProperty<T>?, scheme: String = "any", isPublic: Bool = false, requiresNonObjC: Bool = false) throws -> String? {
        let iv = try IV(dict: [:])
        return configurationProperty?.propertyDeclaration(for: scheme, iv: iv, encryptionKey: nil, requiresNonObjCDeclarations: requiresNonObjC, isPublic: isPublic, indentWidth: 0)
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
}
