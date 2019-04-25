//
//  ConfigurationFileTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ConfigurationFileTests: XCTestCase {
    func testItCanHandleAnyConfiguration() {
        expect(ConfigurationFile.canHandle(config: [:])).to(beTrue())
    }

    func testItCanBeInitialisedFromAnEmptyConfiguration() throws {
        let config = try ConfigurationFile(config: givenAConfigDictionary(), name: "Test", scheme: "any", source: URL(fileURLWithPath: "/"))
        expect(config.name).to(equal("Test"))
        expect(config.scheme).to(equal("any"))
        let testIV = try IV(dict: [:])
        expect(config.iv.hash).to(equal(testIV.hash))
        expect(config.filename).to(beNil())
        let expectedOutput = """
        /* Test.swift auto-generated from any */

        import Foundation

        // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
        public enum Test {
            public static let schemeName: String = "any"
        }

        // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

        """
        expect(config.description).to(equal(expectedOutput))
    }

    func testItCanOutputAnExtension() throws {
        let dict = givenAConfigDictionary(withTemplate: extensionTemplate)
        let config = try ConfigurationFile(config: dict, name: "Test", scheme: "any", source: URL(fileURLWithPath: "/"))
        let testIV = try IV(dict: dict)
        expect(config.iv.hash).to(equal(testIV.hash))
        expect(config.filename).to(equal("UIColor+Test"))
        let expectedOutput = """
        /* UIColor+Test.swift auto-generated from any */

        import Foundation

        // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
        public extension UIColor {

        }

        // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

        """
        expect(config.description).to(equal(expectedOutput))
    }

    func givenAConfigDictionary(withTemplate template: [String: Any]? = nil) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary["template"] = template
        return dictionary
    }
}

let extensionTemplate: [String: Any] = [
    "extensionOn": "UIColor",
    "extensionName": "Test"
]
