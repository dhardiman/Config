//
//  EnumConfigurationTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class EnumConfigurationTests: XCTestCase {
    func testItCanHandleAnEnumConfiguration() {
        expect(EnumConfiguration.canHandle(config: enumConfiguration)).to(beTrue())
    }

    func testItWontHandleAConfigurationWithoutATemplate() {
        expect(EnumConfiguration.canHandle(config: [:])).to(beFalse())
    }

    func testItWontHandleAConfigurationWithADifferentName() {
        let conf: [String: Any] = [
            "template": [
                "name": "Something"
            ]
        ]
        expect(EnumConfiguration.canHandle(config: conf)).to(beFalse())
    }

    func testItInitialisesFromAValidDictionary() throws {
        let config = try EnumConfiguration(config: enumConfiguration, name: "Test", scheme: "Any", source: URL(fileURLWithPath: "/"))
        expect(config.name).to(equal("Test"))
        expect(config.scheme).to(equal("Any"))
        expect(config.type).to(equal("String"))
        expect(config.properties).to(haveCount(3))
    }

    func testItThrowsANoTypeErrorForAnInvalidConfig() {
        do {
            _ = try EnumConfiguration(config: invalidEnumConfiguration, name: "Test", scheme: "Any", source: URL(fileURLWithPath: "/"))
            fail("Expected an error to be thrown")
        } catch let error as EnumConfiguration.EnumError {
            if error != .noType {
                fail("Wrong error type thrown")
            }
        } catch {
            fail("Wrong error type thrown")
        }
    }

    func testItThrowsAnUnknownTypeErrorForAnUnsupportedRawType() {
        do {
            _ = try EnumConfiguration(config: intEnumConfiguration, name: "Test", scheme: "Any", source: URL(fileURLWithPath: "/"))
            fail("Expected an error to be thrown")
        } catch let error as EnumConfiguration.EnumError {
            if error != .unknownType {
                fail("Wrong error type thrown")
            }
        } catch {
            fail("Wrong error type thrown")
        }
    }

    func testItCanOutputAConfigFile() throws {
        let config = try EnumConfiguration(config: enumConfiguration, name: "Test", scheme: "scheme", source: URL(fileURLWithPath: "/"))
        let expectedOutput = """
        // Test auto-generated from scheme
        import Foundation

        public enum Test: String {
            case emptyCase
            case firstCase = #"Some Value"#
            case secondCase = #"Overridden Value"#
        }

        """
        expect(config.description).to(equal(expectedOutput))
    }
}

let enumConfiguration: [String: Any] = [
    "template": [
        "name": "enum",
        "rawType": "String"
    ],
    "firstCase": [
        "description": "A description",
        "defaultValue": "Some Value"
    ],
    "secondCase": [
        "defaultValue": "Another Value",
        "overrides": [
            "scheme": "Overridden Value"
        ]
    ],
    "emptyCase": [
        "defaultValue": ""
    ]
]

let intEnumConfiguration: [String: Any] = [
    "template": [
        "name": "enum",
        "rawType": "Int"
    ],
    "firstCase": [
        "defaultValue": 0
    ],
    "secondCase": [
        "defaultValue": 1,
        "overrides": [
            "scheme": 1
        ]
    ]
]

let invalidEnumConfiguration: [String: Any] = [
    "template": [
        "name": "enum"
    ]
]
