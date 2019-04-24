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
            "--scheme", "test-scheme",
            "--configPath", "/config/path",
            "--ext", "ext"
        ])
        expect(arguments.scheme).to(equal("test-scheme"))
        expect(arguments.configURL.path).to(equal("/config/path"))
        expect(arguments.additionalExtension).to(equal("ext"))
    }

    func testTheExtensionIsOptional() throws {
        let arguments = try Arguments(argumentList: [
            "binary",
            "--scheme", "test-scheme",
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
            expect(error.missingArguments).to(equal(["scheme", "configPath"]))
        } catch {
            fail("Wrong error thrown")
        }
    }

    func testItThrowsAnExceptionWhenPathIsNotPassed() {
        do {
            _ = try Arguments(argumentList: [
                "binary",
                "--scheme", "test-scheme",
            ])
            fail("Error should have been thrown")
        } catch let error as Arguments.MissingArgumentError {
            expect(error.missingArguments).to(equal(["configPath"]))
        } catch {
            fail("Wrong error thrown")
        }
    }

    func testItThrowsAnExceptionWhenSchemeIsNotPassed() {
        do {
            _ = try Arguments(argumentList: [
                "binary",
                "--configPath", "/config/path"
            ])
            fail("Error should have been thrown")
        } catch let error as Arguments.MissingArgumentError {
            expect(error.missingArguments).to(equal(["scheme"]))
        } catch {
            fail("Wrong error thrown")
        }
    }
}
