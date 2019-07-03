//
//  ConfigurationFileReferenceSourceTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ConfigurationFileReferenceSourceTests: XCTestCase {
    var tempURL: URL!
    var referenceSourceURL: URL {
        return tempURL.appendingPathComponent("testSource.config")
    }

    override func setUp() {
        super.setUp()
        tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let referenceSourceData = try? JSONSerialization.data(withJSONObject: configurationReferenceSource, options: [])
        try? referenceSourceData?.write(to: referenceSourceURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: referenceSourceURL)
        tempURL = nil
        super.tearDown()
    }

    func testItOutputsAConfigurationWithAReferenceSource() throws {
        let config = try ConfigurationFile(config: configurationWithReferenceInSource, name: "Test", configName: "any", source: tempURL)
        let expectedOutput = """
        /* Test+ReferenceTest.swift auto-generated from any */

        import Foundation

        // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
        public extension Test {
            static let referenceProperty: String = property
        }

        // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

        """
        expect(config.description).to(equal(expectedOutput))
    }

    func testItOutputsAConfigurationWithAReferenceSourceUsingOverrides() throws {
        let config = try ConfigurationFile(config: configurationWithReferenceInSource, name: "Test", configName: "override", source: tempURL)
        let expectedOutput = """
        /* Test+ReferenceTest.swift auto-generated from override */

        import Foundation

        // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
        public extension Test {
            static let referenceProperty: String = otherProperty
        }

        // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

        """
        expect(config.description).to(equal(expectedOutput))
    }
}

private let configurationReferenceSource: [String: Any] = [
    "property": [
        "type": "String",
        "defaultValue": "A test"
    ],
    "otherProperty": [
        "type": "String",
        "defaultValue": "Other property"
    ]
]

private let configurationWithReferenceInSource: [String: Any] = [
    "template": [
        "referenceSource": "testSource",
        "extensionOn": "Test",
        "extensionName": "ReferenceTest"
    ],
    "referenceProperty": [
        "type": "Reference",
        "defaultValue": "property",
        "overrides": [
            "override": "otherProperty"
        ]
    ]
]
