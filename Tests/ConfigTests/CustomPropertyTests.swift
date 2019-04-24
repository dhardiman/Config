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
    func givenACustomType() -> CustomType {
        return CustomType(source: givenATypeDictionary())!
    }

    func givenADictionary() -> [String: Any] {
        return [
            "description": "A description",
            "defaultValue": "test default value",
            "overrides": [
                "override": "overridden value"
            ]
        ]
    }

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
}
