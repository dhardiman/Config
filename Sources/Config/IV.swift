//
//  IV.swift
//  Config
//
//  Created by David Hardiman on 21/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

struct IV: Property {
    var key: String { return "encryptionKeyIV" }
    var typeName: String { return "[UInt8]" }

    let hash: String
    let associatedProperty: String? = nil

    init(dict: [String: Any]) throws {
        hash = try dict.hashRepresentation()
    }

    func propertyDeclaration(for scheme: String, iv: IV, encryptionKey: String?, requiresNonObjCDeclarations: Bool, isPublic: Bool, instanceProperty: Bool, indentWidth: Int) -> String {
        return "\(String.indent(for: indentWidth))\(isPublic ? "public " : "")\(instanceProperty ? "" : "static ")let \(key): \(typeName) = \(byteArrayOutput(from: Array(hash.utf8)))"
    }
}
