//
//  DictionaryFromFileTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 25/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class DictionaryFromFileTests: XCTestCase {
    func testItCanLoadADictionaryFromAFile() throws {
        let json = """
        {
            "test": "hello"
        }
        """
        let tmpFile = NSTemporaryDirectory() + "temp.json"
        try json.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        let dictionary = dictionaryFromJSON(at: URL(fileURLWithPath: tmpFile))
        expect(dictionary).to(haveCount(1))
        expect(dictionary?["test"] as? String).to(equal("hello"))
    }

    func testItReturnsNilIfTheURLIsEmpty() {
        let tmpFile = NSTemporaryDirectory() + "missing.json"
        let dictionary = dictionaryFromJSON(at: URL(fileURLWithPath: tmpFile))
        expect(dictionary).to(beNil())
    }

    func testItReturnsNilForAnEmptyFile() throws {
        let tmpFile = NSTemporaryDirectory() + "empty.json"
        try "".write(toFile: tmpFile, atomically: true, encoding: .utf8)
        let dictionary = dictionaryFromJSON(at: URL(fileURLWithPath: tmpFile))
        expect(dictionary).to(beNil())
    }

    func testItReturnsNilForAnArrayFile() throws {
        let tmpFile = NSTemporaryDirectory() + "array.json"
        try "[]".write(toFile: tmpFile, atomically: true, encoding: .utf8)
        let dictionary = dictionaryFromJSON(at: URL(fileURLWithPath: tmpFile))
        expect(dictionary).to(beNil())
    }
}
