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
            let contents = try String(contentsOf: url(for: $0.key), encoding: .utf8)
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

    func testItDoesNotWriteIfTheConfigHasNotChanged() throws {
        let generator = ConfigGenerator()
        let mockPrinter = MockPrinter()
        generator.printer = mockPrinter
        try givenAConfigFile((key: "standard", value: generatorConfiguration))
        try generator.run(validOptions())
        let outputURL = url(for: "standard")
        let inputURL = configURL(for: "standard")
        let currentTouchDate = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.modificationDate] as? Date
        expect(mockPrinter.receivedMessages.first).to(equal("Existing file not present, writing \(inputURL.lastPathComponent)"))
        expect(mockPrinter.receivedMessages.last).to(equal("Wrote \(inputURL.lastPathComponent)"))
        mockPrinter.reset()
        try generator.run(validOptions())
        let newTouchDate = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.modificationDate] as? Date
        expect(currentTouchDate).to(equal(newTouchDate))
        expect(mockPrinter.receivedMessages.first).to(equal("Ignoring \(inputURL.lastPathComponent) as it has not changed"))
    }

    func testItDoesWriteIfTheConfigHasChanged() throws {
        let generator = ConfigGenerator()
        let outputURL = url(for: "standard")
        let inputURL = configURL(for: "standard")

        try givenAConfigFile((key: "standard", value: generatorConfiguration))
        try generator.run(validOptions())
        let currentTouchDate = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.modificationDate] as? Date

        let mockPrinter = MockPrinter()
        generator.printer = mockPrinter

        try givenAConfigFile((key: "standard", value: enumConfiguration))
        try generator.run(validOptions())
        let newTouchDate = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.modificationDate] as? Date
        expect(currentTouchDate).to(beLessThan(newTouchDate))
        expect(mockPrinter.receivedMessages.first).to(equal("Existing file different from new file, writing \(inputURL.lastPathComponent)\nExisting: \(expectedStrings["standard"]!), New: \(expectedStrings["enumconfig"]!.replacingOccurrences(of: "enumconfig", with: "standard"))"))
    }

    func testItCanPrintItsUsage() {
        let generator = ConfigGenerator()
        expect(generator.usage).to(equal("""
        \(Arguments.Option.scheme.usage)
        \(Arguments.Option.configPath.usage)
        \(Arguments.Option.additionalExtension.usage)
        """))
    }

    func validOptions() -> [String] {
        return [
            "",
            "--configPath", tempURL.path,
            "--scheme", "any",
            "--ext", "ext"
        ]
    }

    func givenAConfigFile(_ config: (key: String, value: [String: Any])) throws {
        try write(object: config.value, toConfigFileNamed: config.key)
    }

    func givenSomeConfigFiles() throws {
        try configFixtures.forEach {
            try givenAConfigFile($0)
        }
    }

    func write(object: Any, toConfigFileNamed name: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        try data.write(to: tempURL.appendingPathComponent(name).appendingPathExtension("config"))
    }

    private func url(for key: String) -> URL {
        return tempURL.appendingPathComponent(filenames[key] ?? key).appendingPathExtension("ext.swift")
    }

    private func configURL(for key: String) -> URL {
        return tempURL.appendingPathComponent(filenames[key] ?? key).appendingPathExtension("config")
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
        public static let float: Float = 0.0

        public static let schemeName: String = #"any"#
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

private class MockPrinter: Printing {
    var receivedMessages = [String]()

    func print(message: String) {
        receivedMessages.append(message)
    }

    func reset() {
        receivedMessages.removeAll()
    }
}
