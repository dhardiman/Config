//
//  EncryptionTests.swift
//  Config
//
//  Created by David Hardiman on 24/04/2019.
//

@testable import Config
import Foundation
import Nimble
import XCTest

class EncryptionTests: XCTestCase {
    func testItIsPossibleToEncryptAValue() throws {
        let iv = try IV(dict: ["test": "dict"])
        let key = "test key"
        let encrypted = "test secret".encrypt(key: Array(key.utf8), iv: Array(iv.hash.utf8))!
        let decrypted = String(encryptedData: encrypted, key: Array(key.utf8), iv: Array(iv.hash.utf8))
        expect(decrypted).to(equal("test secret"))
    }
}
