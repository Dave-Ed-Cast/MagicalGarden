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
        let terrain = ModelEntity(
            mesh: .generateBox(width: 0.5, height: 0.01, depth: 0.05),
            materials: [UnlitMaterial(color: .cyan.withAlphaComponent(0.5))]
        )
        terrain.name = "Terrain"
        return terrain
    }
    
    static func playSound(named name: String, on entity: Entity) {
        guard let resource = try? AudioFileResource.load(named: name, configuration: .init(loadingStrategy: .preload)) else {
            print("Failed to load sound \(name)")
            return
        }
        entity.playAudio(resource)
    }
    
    static private func createCenteredText(_ text: String, fontSize: CGFloat = 0.07) -> ModelEntity {
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: fontSize),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        
        
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.name = "ring_timer_text"
        Task { @MainActor in
            let environment = try? await EnvironmentResource(named: "studio")
            textEntity.configureLighting(resource: environment!, withShadow: false)
        }
        if let bounds = textEntity.model?.mesh.bounds {
            let centerOffset = bounds.center
            textEntity.position = SIMD3<Float>(-centerOffset.x, -centerOffset.y, -centerOffset.z)
        }
        
        return textEntity
    }
    
    static func setNewEntity(
        _ newEntity: Entity,
        from entity: Entity,
        with component: Component,
        last: Bool = false
    ) {
        newEntity.name = entity.name
        newEntity.position = entity.position
        newEntity.orientation = entity.orientation
        newEntity.generateCollisionShapes(recursive: true)
        
        if !last {
            newEntity.components.set(InputTargetComponent())
            newEntity.components.set(component)
        }
        
        entity.parent?.addChild(newEntity)
        entity.removeFromParent()
    }
    
    static func createSphericalFillingTimer(
        _ totalTime: Int,
        radius: Float = 0.06,
        onTimerCompletion: @escaping () -> Void
    ) async -> ModelEntity {
        
        let containerEntity = ModelEntity()
        containerEntity.name = "sphere_timer_container"
        
        let outerMesh = MeshResource.generateSphere(radius: radius + 0.01)
        let outerMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)
        let outerEntity = ModelEntity(mesh: outerMesh, materials: [outerMaterial])
        containerEntity.addChild(outerEntity)
        
        let initialRadius: Float = 0.01
        let fillMesh = MeshResource.generateSphere(radius: initialRadius)
        let fillMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let fillEntity = ModelEntity(mesh: fillMesh, materials: [fillMaterial])
        fillEntity.name = "fill_sphere"
        containerEntity.addChild(fillEntity)
        
        var billboard = BillboardComponent()
        billboard.blendFactor = 0.3
        containerEntity.components.set(billboard)
        
        var remainingTime = totalTime
        let textEntity = createCenteredText("\(remainingTime)")
        textEntity.position.y = radius + 0.08
        textEntity.components.set(BillboardComponent())
        containerEntity.addChild(textEntity)
        
        var elapsedTime = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            elapsedTime += 1
            remainingTime = max(totalTime - elapsedTime, 0)
            
            let percentage = Float(elapsedTime) / Float(totalTime)
            let currentRadius = initialRadius + (radius - initialRadius) * percentage
            
            fillEntity.model?.mesh = MeshResource.generateSphere(radius: currentRadius)
            
            let fillColor = UIColor.blue.interpolate(to: .purple, with: CGFloat(percentage))
            fillEntity.model?.materials = [SimpleMaterial(color: fillColor, roughness: 0.1, isMetallic: false)]
            
            
            let newText = elapsedTime >= totalTime ? "Bloom!" : "\(remainingTime)"
            let fontSize: CGFloat = elapsedTime >= totalTime ? 0.03 : 0.07
            
            let newTextMesh = MeshResource.generateText(
                newText,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: fontSize),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            
            textEntity.model?.mesh = newTextMesh
            
            if elapsedTime >= totalTime {
                timer.invalidate()
                textEntity.name = "sphere_timer_completion_text"
                Entity.playSound(named: "SFX_2", on: textEntity)
                fillEntity.model?.materials = [SimpleMaterial(color: .purple, roughness: 0.0, isMetallic: true)]
                onTimerCompletion()
                timer.invalidate()
            }
        }
        
        return containerEntity
    }
}
