//
//  Dictionary+MD5.swift
//  Config
//
//  Created by Sebastian Skuse on 30/06/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation
import CommonCrypto

extension Dictionary {

    func hashRepresentation() throws -> String {
        let options: JSONSerialization.WritingOptions
        if #available(OSX 10.13, *) {
            options = .sortedKeys
        } else {
            options = []
        }
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        var digestData = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { messageBytes in
            _ = CC_MD5(messageBytes.baseAddress!, CC_LONG(data.count), &digestData)
        }
        let resultData = Data(digestData)

        return resultData.map { String(format: "%02hhx", $0) }.joined()
    }
}
