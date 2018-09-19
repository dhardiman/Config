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
        let data = try JSONSerialization.data(withJSONObject: self, options: [])
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))

        _ = digestData.withUnsafeMutableBytes { digestBytes in
            data.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }

        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
