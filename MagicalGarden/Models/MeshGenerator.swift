//
//  MeshGenerator.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import RealityKit
import ARKit
import SwiftUI
#if os(visionOS)
class MeshGenerator {
    
    var root: Entity
    
    private var anchors: [UUID: AnchorEntity] = [:]
    
    init(root: Entity) { self.root = root }
    
    /// Runs the detection of planes, and when detected it adds the ID to the `ObjectSpawnerAndHandler`
    @MainActor func run(_ planeProvider: PlaneDetectionProvider, onPlaneDetected: @escaping (UUID, AnchorEntity) -> Void) async {
        for await update in planeProvider.anchorUpdates {
            guard update.anchor.classification == .floor
                    || update.anchor.classification == .table
            else { continue }
            
            switch update.event {
            case .added:
                let anchorEntity = anchors[update.anchor.id] ?? {
                    let newAnchor = AnchorEntity()
                    newAnchor.name = "planeAnchor-\(update.anchor.id.uuidString.prefix(4))"
                    newAnchor.components.set(PlaneIDComponent(id: update.anchor.id))
                    root.addChild(newAnchor)
                    anchors[update.anchor.id] = newAnchor
                    return newAnchor
                }()
                
                guard let mesh = try? await MeshResource(from: update.anchor) else { return }
                
                let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.25), isMetallic: false)
                let modelEntity = ModelEntity(mesh: mesh, materials: [material])
                
                modelEntity.name = "planeMesh-\(update.anchor.id.uuidString.prefix(4))"
                
                modelEntity.generateCollisionShapes(recursive: false)
                modelEntity.components.set([InputTargetComponent(), PlaneAnchorComponent(anchor: update.anchor)])
                
                modelEntity.setTransformMatrix(update.anchor.originFromAnchorTransform, relativeTo: nil)
                
                anchorEntity.addChild(modelEntity)
                onPlaneDetected(update.anchor.id, anchorEntity)
                
            case .removed:
                anchors[update.anchor.id]?.removeFromParent()
                anchors[update.anchor.id] = nil
                
            default: continue
            }
        }
    }
}
#endif
