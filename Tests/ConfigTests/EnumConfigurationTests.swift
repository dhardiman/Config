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
