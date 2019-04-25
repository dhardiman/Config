//
//  CustomPropertyTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class CustomPropertyTests: XCTestCase {
    func testItIsCreatedCorrectly() {
        let property = CustomProperty(key: "test", customType: givenACustomType(), dict: givenADictionary())
        expect(property.key).to(equal("test"))
        expect(property.description).to(equal("A description"))
        expect(property.customType.typeName).to(equal("CustomType"))
        expect(property.defaultValue as? String).to(equal("test default value"))
        expect(property.overrides as NSDictionary).to(equal([
            "override": "overridden value"
        ] as NSDictionary))
    }

    func testItReportsItsTypeName() {
        let property = CustomProperty(key: "test", customType: givenACustomType(), dict: givenADictionary())
        expect(property.typeName).to(equal("CustomType"))
    }

    func testItOutputAPropertyDeclarationCorrectly() throws {
        let property = CustomProperty(key: "test", customType: givenACustomType(), dict: givenADictionaryWithValues())
        let expectedValue = """
            /// A description
            static let test: CustomType = CustomType(oneThing: firstValue, secondThing: secondValue)
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: false, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputAPublicPropertyDeclarationCorrectly() throws {
        let property = CustomProperty(key: "test", customType: givenACustomType(), dict: givenADictionaryWithValues())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType(oneThing: firstValue, secondThing: secondValue)
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputAPropertyDeclarationCorrectlyForAnOverriddenScheme() throws {
        let property = CustomProperty(key: "test", customType: givenACustomType(), dict: givenADictionaryWithValues())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType(oneThing: firstOverriddenValue, secondThing: secondOverriddenValue)
        """
        expect(property.propertyDeclaration(for: "override", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputsAPropertyForAnInitialiserWithoutPlaceholders() throws {
        let property = CustomProperty(key: "test", customType: givenACustomType(for:  [
            "typeName": "CustomType",
            "initialiser": "CustomType()"
        ]), dict: givenADictionaryWithValues())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType()
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputsAPropertyForASinglePlaceholder() {
        let property = CustomProperty(key: "test", customType: givenACustomType(for:  [
            "typeName": "CustomType",
            "initialiser": "CustomType(thingy: {$0})"
            ]), dict: givenADictionary())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType(thingy: test default value)
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputsAPropertyForASingleNamedPlaceholder() {
        let property = CustomProperty(key: "test", customType: givenACustomType(for:  [
            "typeName": "CustomType",
            "initialiser": "CustomType(thingy: {firstplaceholder:String})"
            ]), dict: givenADictionaryWithValues())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType(thingy: "firstValue")
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputsAPropertyForATypeWithTypeAnnotations() {
        let property = CustomProperty(key: "test", customType: givenACustomType(for: givenATypeDictionaryWithTypeAnnotations()), dict: givenADictionaryWithTypedValues())
        let expectedValue = """
            /// A description
            public static let test: CustomType = CustomType(oneThing: "firstValue", secondThing: true)
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }
}

class CustomPropertyArrayTests: XCTestCase {
    func testItIsCreatedCorrectly() {
        let property = CustomPropertyArray(key: "test", customType: givenACustomType(), dict: givenADictionaryWithSimpleArrayValues())
        expect(property.key).to(equal("test"))
        expect(property.description).to(equal("A description"))
        expect(property.customType.typeName).to(equal("CustomType"))
        expect(property.defaultValue as? [String]).to(equal(["test default value"]))
        expect(property.overrides as NSDictionary).to(equal([
            "override": ["overridden value"]
            ] as NSDictionary))
    }

    func testItReportsItsTypeName() {
        let property = CustomPropertyArray(key: "test", customType: givenACustomType(), dict: givenADictionaryWithSimpleArrayValues())
        expect(property.typeName).to(equal("[CustomType]"))
    }

    func testItOutputsAPropertyForATypeWithTypeAnnotations() {
        let property = CustomPropertyArray(key: "test", customType: givenACustomType(for: givenATypeDictionaryWithTypeAnnotations()), dict: givenADictionaryWithArrayValues())
        let expectedValue = """
            /// A description
            public static let test: [CustomType] = [CustomType(oneThing: "firstValue", secondThing: true)]
        """
        expect(property.propertyDeclaration(for: "any", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }

    func testItOutputsAPropertyForAnOverriddenScheme() {
        let property = CustomPropertyArray(key: "test", customType: givenACustomType(for: givenATypeDictionaryWithTypeAnnotations()), dict: givenADictionaryWithArrayValues())
        let expectedValue = """
            /// A description
            public static let test: [CustomType] = [CustomType(oneThing: "firstOverriddenValue", secondThing: false)]
        """
        expect(property.propertyDeclaration(for: "override", iv: try IV(dict: [:]), encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, indentWidth: 0)).to(equal(expectedValue))
    }
}

private func givenACustomType(for dictionary: [String: Any] = givenATypeDictionary()) -> CustomType {
    return CustomType(source: dictionary)!
}

private func givenADictionary() -> [String: Any] {
    return [
        "description": "A description",
        "defaultValue": "test default value",
        "overrides": [
            "override": "overridden value"
        ]
    ]
}

private func givenADictionaryWithSimpleArrayValues() -> [String: Any] {
    return [
        "description": "A description",
        "defaultValue": ["test default value"],
        "overrides": [
            "override": ["overridden value"]
        ]
    ]
}

private func givenADictionaryWithValues() -> [String: Any] {
    return [
        "description": "A description",
        "defaultValue": [
            "firstplaceholder": "firstValue",
            "secondplaceholder": "secondValue"
        ],
        "overrides": [
            "override": [
                "firstplaceholder": "firstOverriddenValue",
                "secondplaceholder": "secondOverriddenValue"
            ]
        ]
    ]
}

private func givenADictionaryWithArrayValues() -> [String: Any] {
    return [
        "description": "A description",
        "defaultValue": [
            [
                "firstplaceholder": "firstValue",
                "secondplaceholder": true
            ]
        ],
        "overrides": [
            "override": [
                [
                    "firstplaceholder": "firstOverriddenValue",
                    "secondplaceholder": false
                ]
            ]
        ]
    ]
}

private func givenADictionaryWithTypedValues() -> [String: Any] {
    return [
        "description": "A description",
        "defaultValue": [
            "firstplaceholder": "firstValue",
            "secondplaceholder": true
        ],
        "overrides": [
            "override": [
                "firstplaceholder": "firstOverriddenValue",
                "secondplaceholder": false
            ]
        ]
    ]
}
