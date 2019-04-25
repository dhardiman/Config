//
//  ConfigGeneratorTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ConfigGeneratorTests: XCTestCase {
    var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
    }

    override func tearDown() {
        tempURL = nil
        super.tearDown()
    }

    func testItThrowsAnErrorIfArgumentsAreMissing() {
        let generator = ConfigGenerator()
        do {
            try generator.run([""])
            fail("Expected an error")
        } catch {}
    }

    func testItReadsAndWritesConfigFiles() throws {
        givenSomeConfigFiles()
        let generator = ConfigGenerator()
        try generator.run(validOptions())
        try configFixtures.forEach {
            let contents = try String(contentsOf: tempURL.appendingPathComponent($0.key).appendingPathExtension("ext.swift"), encoding: .utf8)
            expect(contents).to(equal(expectedStrings[$0.key]))
        }
    }

    func validOptions() -> [String] {
        return [
            "",
            "--configPath", tempURL.path,
            "--scheme", "any",
            "--ext", "ext"
        ]
    }

    func givenSomeConfigFiles() {
        configFixtures.forEach {
            let data = try? JSONSerialization.data(withJSONObject: $0.value, options: [])
            try? data?.write(to: tempURL.appendingPathComponent($0.key).appendingPathExtension("config"))
        }
    }
}

private let configFixtures = [
    "enumconfig":  enumConfiguration,
    "standard": generatorConfiguration
]

private let expectedStrings = [
    "enumconfig": """
    /* enumconfig auto-generated from any */
    import Foundation

    public enum enumconfig: String {
        case emptyCase
        case firstCase = "Some Value"
        case secondCase = "Another Value"
    }

    """,
    "standard": """
    /* standard.swift auto-generated from any */

    import Foundation

    // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
    public enum standard {
        public static let float: Float = 0.0

        public static let schemeName: String = "any"
    }

    // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

    """
]

private let generatorConfiguration: [String: Any] = [
    "float": [
        "type": "Float",
        "defaultValue": 0.0
    ]
]
