//
//  GenerationBehaviour.swift
//
//
//  Created by drh on 22/01/2024.
//

import Foundation

/// Struct for configuring configuration generation behaviour.
struct GenerationBehaviour {
    /// When enabled, will create warnings on generation failures rather than fatal errors.
    let developerMode: Bool
    
    init(developerMode: Bool = false) {
        self.developerMode = developerMode
    }
}
