//
//  IVTests.swift
//  ConfigTests
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class IVTests: XCTestCase {
    func testItWritesAPropertyDeclarationCorrectly() throws {
        let iv = try IV(dict: ["hello": "world"])
        let expectedByteArray = "[UInt8(102), UInt8(98), UInt8(99), UInt8(50), UInt8(52), UInt8(98), UInt8(99), UInt8(99), UInt8(55), UInt8(97), UInt8(49), UInt8(55), UInt8(57), UInt8(52), UInt8(55), UInt8(53), UInt8(56), UInt8(102), UInt8(99), UInt8(49), UInt8(51), UInt8(50), UInt8(55), UInt8(102), UInt8(99), UInt8(102), UInt8(101), UInt8(98), UInt8(100), UInt8(97), UInt8(102), UInt8(54)]"
        expect(iv.propertyDeclaration(for: "", iv: iv, encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: false, instanceProperty: false, indentWidth: 0)).to(equal("    static let encryptionKeyIV: [UInt8] = \(expectedByteArray)"))
        expect(iv.propertyDeclaration(for: "", iv: iv, encryptionKey: nil, requiresNonObjCDeclarations: false, isPublic: true, instanceProperty: true, indentWidth: 0)).to(equal("    public let encryptionKeyIV: [UInt8] = \(expectedByteArray)"))
    }
}
