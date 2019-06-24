//
//  OverridePattern.swift
//  Config
//
//  Created by David Hardiman on 24/06/2019.
//

import Foundation

struct OverridePattern {
    let alias: String
    let pattern: String

    init?(source: [String: String]) {
        guard let alias = source["alias"], let pattern = source["pattern"] else {
            return nil
        }
        self.alias = alias
        self.pattern = pattern
    }

    static func patterns(from template: [String: Any]?) -> [OverridePattern] {
        guard let types = template?["patterns"] as? [[String: String]] else {
            return []
        }
        return types.compactMap { OverridePattern(source: $0) }
    }
}
