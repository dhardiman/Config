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
        expect(config.properties).to(haveCount(2))
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
}

let enumConfiguration: [String: Any] = [
    "template": [
        "name": "enum",
        "rawType": "String"
    ],
    "firstCase": [
        "defaultValue": "Some Value"
    ],
    "secondCase": [
        "defaultValue": "Another Value",
        "overrides": [
            "scheme": "Overridden Value"
        ]
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
