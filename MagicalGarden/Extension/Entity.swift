//
//  Entity.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import SwiftUI

extension Entity {
    
    func makeTerrain() async throws -> ModelEntity {
        
        let terrain = ModelEntity(mesh: .generateBox(width: 0.5, height: 0.01, depth: 0.05), materials: [UnlitMaterial(color: .cyan.withAlphaComponent(0.5))])
        
        terrain.name = "Terrain"
        
        return terrain
    }
    
    func createTimerLabel(_ time: Int, for parentBox: Entity, onTimerCompletion: @escaping () -> Void) -> ModelEntity {
        var remainingTime = time
        
        let mesh = MeshResource.generateText(
            "\(remainingTime)",
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.06),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: mesh, materials: [material])
        textEntity.name = "text"
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            remainingTime -= 1
            
            if remainingTime <= 0 {
                timer.invalidate()
                onTimerCompletion()
            }
            
            let newMesh = MeshResource.generateText(
                "\(max(remainingTime, 0))",
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.06),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            textEntity.model?.mesh = newMesh
            
        }
        
        return textEntity
    }
    
    static func createTimerRing(
        _ totalTime: Int,
        radius: Float = 10,
        thickness: Float = 2.5,
        onTimerCompletion: @escaping () -> Void
    ) -> ModelEntity {
        var elapsedTime = 0
        
        let initialAngle: Float = 10.0
        let ringMesh = MeshResource.generateRing(radius: radius, thickness: thickness, angle: initialAngle)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        
        let ringEntity = ModelEntity(mesh: ringMesh, materials: [material])
        ringEntity.name = "ring_timer"
                
        ringEntity.generateCollisionShapes(recursive: true)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            elapsedTime += 1
            
            if elapsedTime >= totalTime {
                timer.invalidate()
                onTimerCompletion()
            }
            
            let percentage = Float(elapsedTime) / Float(totalTime)
            let newAngle = 10.0 + (350.0 * percentage)
            
            let newRingMesh = MeshResource.generateRing(radius: radius, thickness: thickness, angle: newAngle)
            ringEntity.model?.mesh = newRingMesh
        }
        
        return ringEntity
    }
}
