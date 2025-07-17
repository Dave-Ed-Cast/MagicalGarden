//
//  Entity.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import SwiftUI

extension Entity {
    
    static func makeTerrain() async throws -> ModelEntity {
                
        let terrain = ModelEntity(mesh: .generateBox(width: 0.5, height: 0.01, depth: 0.05), materials: [UnlitMaterial(color: .cyan.withAlphaComponent(0.5))])
        
        terrain.name = "Terrain"
        
        return terrain
    }
}
