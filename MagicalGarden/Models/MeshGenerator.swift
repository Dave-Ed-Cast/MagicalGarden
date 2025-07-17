//
//  MeshGenerator.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit
import ARKit

class MeshGenerator {
    
    var root: Entity
    
    init(root: Entity) { self.root = root }
    
#if os(visionOS)
    
    @MainActor
    func run(_ planeProvider: PlaneDetectionProvider) async {
        for await update in planeProvider.anchorUpdates {
            if update.anchor.classification != .floor,
               update.anchor.classification != .table {
                continue // Skip non-floor/table planes
            }
            
            switch update.event {
            case .added, .updated:
                let entity = anchors[update.anchor.id] ?? {
                    let entity = Entity()
                    root.addChild(entity)
                    anchors[update.anchor.id] = entity
                    return entity
                }()
                
                let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.8), isMetallic: false)
                
                guard let mesh = try? await MeshResource(from: update.anchor) else { return }
                
                await MainActor.run {
                    entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
                    entity.setTransformMatrix(update.anchor.originFromAnchorTransform, relativeTo: nil)
                }
                
            case .removed:
                anchors[update.anchor.id]?.removeFromParent()
                anchors[update.anchor.id] = nil
            }
        }
    }
#endif
    
}
