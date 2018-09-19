//
//  AESCrypt.swift
//  Config
//
//  Created by Seb Skuse on 25/05/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation
import CommonCrypto

class AESCrypt {

    private let key: [UInt8]
    private let iv: [UInt8]
    private let algoritm: CCAlgorithm
    private let options: CCOptions
    private let keyLength: size_t
    private let blockSize: size_t

    init(key: [UInt8],
         iv: [UInt8],
         algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128),
         options: CCOptions = UInt32(kCCOptionPKCS7Padding),
         keyLength: size_t = size_t(kCCKeySizeAES128),
         blockSize: size_t = size_t(kCCBlockSizeAES128)) {

        self.key = key
        self.iv = iv
        self.algoritm = algorithm
        self.options = options
        self.keyLength = keyLength
        self.blockSize = blockSize
    }

    /// Encrypt and return a series of bytes using the key and initialization vector.
    func encrypt(_ data: [UInt8]) -> [UInt8]? {
        return transform(data, operation: kCCEncrypt)
    }

    /// Decrypt and return a series of bytes using the key and initialization vector.
    func decrypt(_ data: [UInt8]) -> [UInt8]? {
        return transform(data, operation: kCCDecrypt)
    }

    private func transform(_ data: [UInt8], operation: Int) -> [UInt8]? {
        let cryptLength = size_t(data.count + blockSize)
        var cryptData = [UInt8](repeating: 0, count: cryptLength)

        var numBytesEncrypted: size_t = 0

        let cryptStatus = CCCrypt(CCOperation(operation),
                                  algoritm,
                                  options,
                                  key,
                                  keyLength,
                                  iv,
                                  data,
                                  data.count,
                                  &cryptData,
                                  cryptLength,
                                  &numBytesEncrypted)

        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
        }

        return cryptData
    }
}

extension String {

    /// Decrypt a series of bytes using the specified key and
    /// initialization vector.
    init?(encryptedData: [UInt8], key: [UInt8], iv: [UInt8]) {
        let aes = AESCrypt(key: key, iv: iv)
        guard let decodedBytes = aes.decrypt(encryptedData) else {
            return nil
        }

        self.init(bytes: decodedBytes, encoding: .utf8)
    }

    /// Returns an encrypted representation of `self`.
    ///
    /// - Parameters:
    ///   - key: The key to use to encrypt the string with.
    ///   - iv: The initialization vector to use to create
    /// the encrypted string.
    /// - Returns: An array of bytes, or nil.
    func encrypt(key: [UInt8], iv: [UInt8]) -> [UInt8]? {
        let aes = AESCrypt(key: key, iv: iv)
        return aes.encrypt(Array(self.utf8))
    }
}
