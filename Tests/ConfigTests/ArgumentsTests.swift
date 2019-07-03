//
//  ArgumentsTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class ArgumentsTests: XCTestCase {
    func testItParsesCorrectArguments() throws {
        let arguments = try Arguments(argumentList: [
            "binary",
            "--name", "test-name",
            "--configPath", "/config/path",
            "--ext", "ext"
        ])
        expect(arguments.name).to(equal("test-name"))
        expect(arguments.configURL.path).to(equal("/config/path"))
        expect(arguments.additionalExtension).to(equal("ext"))
    }

    func testTheExtensionIsOptional() throws {
        let arguments = try Arguments(argumentList: [
            "binary",
            "--name", "test-name",
            "--configPath", "/config/path"
        ])
        expect(arguments.additionalExtension).to(beNil())

    }

    func testItThrowsAnExceptionWhenRequiredValuesAreNotPassed() {
        do {
            _ = try Arguments(argumentList: [
                "binary"
            ])
            fail("Error should have been thrown")
        } catch let error as Arguments.MissingArgumentError {
            expect(error.missingArguments).to(equal(["name", "configPath"]))
        } catch {
            fail("Wrong error thrown")
        }
    }

    func testItThrowsAnExceptionWhenPathIsNotPassed() {
        do {
            _ = try Arguments(argumentList: [
                "binary",
                "--name", "test-name",
            ])
            fail("Error should have been thrown")
        } catch let error as Arguments.MissingArgumentError {
            expect(error.missingArguments).to(equal(["configPath"]))
        } catch {
            fail("Wrong error thrown")
        }
    }

    func testItThrowsAnExceptionWhenConfigNameIsNotPassed() {
        do {
            _ = try Arguments(argumentList: [
                "binary",
                "--configPath", "/config/path"
            ])
            fail("Error should have been thrown")
        } catch let error as Arguments.MissingArgumentError {
            expect(error.missingArguments).to(equal(["name"]))
        } catch {
            fail("Wrong error thrown")
        }
    }
}
