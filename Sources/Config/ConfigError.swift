//
//  ConfigError.swift
//  Config
//
//  Created by Sebastian Skuse on 17/10/2017.
//  Copyright © 2017. All rights reserved.
//

import Foundation

public enum ConfigError: Error {
    case badJSON
    case noTemplate
}
