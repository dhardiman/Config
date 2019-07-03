//
//  Template.swift
//  Config
//
//  Created by David Hardiman on 22/09/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

protocol Template: CustomStringConvertible {
    init(config: [String: Any], name: String, configName: String, source: URL) throws

    static func canHandle(config: [String: Any]) -> Bool

    var filename: String? { get }
}

extension Template {
    var filename: String? {
        return nil
    }
}
