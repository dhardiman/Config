//
//  CustomType.swift
//  Config
//
//  Created by David Hardiman on 15/04/2019.
//

import Foundation

struct CustomType {
    let typeName: String
    let initialiser: String

    init?(source: [String: Any]) {
        guard let typeName = source["typeName"] as? String,
              let initialiser = source["initialiser"] as? String else {
            return nil
        }
        self.typeName = typeName
        self.initialiser = initialiser
    }

    static func typeArray(from template: [String: Any]?) -> [CustomType] {
        guard let types = template?["customTypes"] as? [[String: Any]] else {
            return []
        }
        return types.compactMap { CustomType(source: $0) }
    }
}
