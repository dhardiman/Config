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
        try? FileManager.default.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil, options: [])
            .filter {
                $0.pathExtension == "config" || $0.pathExtension == "swift"
            }
            .forEach { try? FileManager.default.removeItem(at: $0) }
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
        try givenSomeConfigFiles()
        let generator = ConfigGenerator()
        try generator.run(validOptions())
        try configFixtures.forEach {
            let contents = try String(contentsOf: tempURL.appendingPathComponent(filenames[$0.key] ?? $0.key).appendingPathExtension("ext.swift"), encoding: .utf8)
            expect(contents).to(equal(expectedStrings[$0.key]))
        }
    }

    func testItThrowsAnErrorIfTheDictionaryCantBeRead() throws {
        try write(object: [], toConfigFileNamed: "invalid")
        do {
            let generator = ConfigGenerator()
            try generator.run(validOptions())
            fail("Expected error to be thrown")
        } catch let error as ConfigError {
            if error != .badJSON {
                fail("Wrong error thrown")
            }
        } catch {
            fail("Wrong error thrown")
        }
    }

    func validOptions() -> [String] {
        return [
            "",
            "--configPath", tempURL.path,
            "--name", "any",
            "--ext", "ext"
        ]
    }

    func givenSomeConfigFiles() throws {
        try configFixtures.forEach {
            try write(object: $0.value, toConfigFileNamed: $0.key)
        }
    }

    func write(object: Any, toConfigFileNamed name: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        try data.write(to: tempURL.appendingPathComponent(name).appendingPathExtension("config"))
    }
}

private let configFixtures = [
    "enumconfig":  enumConfiguration,
    "standard": generatorConfiguration,
    "extension": extensionConfiguration
]

private let filenames = [
    "extension": "UIColor+test"
]

private let expectedStrings = [
    "enumconfig": """
    /* enumconfig auto-generated from any */
    import Foundation

    public enum enumconfig: String {
        case emptyCase
        case firstCase = #"Some Value"#
        case secondCase = #"Another Value"#
    }

    """,
    "standard": """
    /* standard.swift auto-generated from any */

    import Foundation

    // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
    public enum standard {
        public static let configName: String = #"any"#

        public static let float: Float = 0.0
    }

    // swiftlint:enable force_unwrapping type_body_length file_length superfluous_disable_command

    """,
    "extension": """
    /* UIColor+test.swift auto-generated from any */

    import Foundation

    // swiftlint:disable force_unwrapping type_body_length file_length superfluous_disable_command
    public extension UIColor {

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

private let extensionConfiguration: [String: Any] = [
    "template": [
        "extensionName": "test",
        "extensionOn": "UIColor"
    ]
]
