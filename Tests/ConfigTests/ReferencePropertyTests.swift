//
//  ReferencePropertyTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ReferencePropertyTests: XCTestCase {
    func givenAReferenceProperty() -> ReferenceProperty? {
        return ReferenceProperty(key: "test", dict: [
            "defaultValue": "testValue",
            "overrides": [
                "hello": "helloValue",
                "pattern": "patternValue"
            ]
        ], typeName: "String")
    }

    func whenTheDeclarationIsWritten(for property: ReferenceProperty?, scheme: String = "any", encryptionKey: String? = nil, isPublic: Bool = false, instanceProperty: Bool = false, requiresNonObjC: Bool = false, indentWidth: Int = 0) throws -> String? {
        let iv = try IV(dict: ["initialise": "me"])
        print("\(iv.hash)")
        return property?.propertyDeclaration(for: scheme, iv: iv, encryptionKey: encryptionKey, requiresNonObjCDeclarations: requiresNonObjC, isPublic: isPublic, instanceProperty: instanceProperty, indentWidth: indentWidth)
    }

    func testItCanWriteADeclarationForAStringPropertyUsingTheDefaultValue() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "    static let test: String = testValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItAddsAPublicAccessorWhenRequired() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "    public static let test: String = testValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property, isPublic: true)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCreatesAnInstancePropertyWhenRequired() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "    let test: String = testValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property, instanceProperty: true)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanIndentADeclaration() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "                static let test: String = testValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property, indentWidth: 3)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItWritesNoObjCPropertiesWhenRequired() throws {
        let property = givenAReferenceProperty()
        let expectedValue = """
            @nonobjc static var test: String {
                return testValue
            }
        """
        let actualValue = try whenTheDeclarationIsWritten(for: property, requiresNonObjC: true)
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanGetAnOverrideForAnExactMatch() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "    static let test: String = helloValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property, scheme: "hello")
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanGetAnOverrideForAPatternMatch() throws {
        let property = givenAReferenceProperty()
        let expectedValue = "    static let test: String = patternValue"
        let actualValue = try whenTheDeclarationIsWritten(for: property, scheme: "match-a-pattern")
        expect(actualValue).to(equal(expectedValue))
    }

    func testItCanWriteADescriptionAsAComment() throws {
        let property = ReferenceProperty(key: "test", dict: [
            "defaultValue": "testValue",
            "description": "A comment to add"
        ], typeName: "String")
        let expectedValue = """
            /// A comment to add
            static let test: String = testValue
        """
        let actualValue = try whenTheDeclarationIsWritten(for: property)
        expect(actualValue).to(equal(expectedValue))
    }
}
