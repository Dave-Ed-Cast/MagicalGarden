//
//  iOSPlaneDetector.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import SwiftUI
import RealityKit
import ARKit

@Observable
final class iOSPlaneDetector: NSObject, PlaneDetectionProtocol, ARSessionDelegate {
    
    var isDetecting = false
    var detectedPlanes: [String: AnchorEntity] = [:]
    var onPlaneDetected: ((AnchorEntity, ARPlaneAnchor) -> Void)?
    var entityChanged: [String: Bool] = [:]
    
    private(set) var arView: ARView!
    
    private var hasStartedDetection = false
    private var spawnedPlaneIDs: Set<UUID> = []
    
    func makeARView() -> ARView {
        let view = ARView(frame: .zero)
        view.session.delegate = self
        self.arView = view
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func startDetection() async throws {
        guard !hasStartedDetection else { return }
        
        await MainActor.run { self.isDetecting = true }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        await arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        hasStartedDetection = true
    }
    
    @MainActor func stopDetection() {
        arView?.session.pause()
        hasStartedDetection = false
        
        isDetecting = false
        detectedPlanes.removeAll()
        entityChanged.removeAll()
        spawnedPlaneIDs.removeAll()
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = arView else { return }
        let tapLocation = sender.location(in: view)
        
        if changeEntityStatus(at: tapLocation, in: view) { return }
        
        spawnUniqueEntity(at: tapLocation, in: view)
    }
    
    private func changeEntityStatus(at location: CGPoint, in view: ARView) -> Bool {
        guard let entity = view.entity(at: location),
              !entity.name.isEmpty,
              entity.components.has(InputTargetComponent.self),
              let modelEntity = entity as? ModelEntity
        else { return false }
        
        if entityChanged[entity.name] == false {
            let newMaterial = SimpleMaterial(color: .green, isMetallic: false)
            modelEntity.model?.materials = [newMaterial]
            entityChanged[entity.name] = true
            print("Changed entity: \(entity.name)")
        } else {
            print("Entity \(entity.name) has already been changed.")
        }
        
        return true
    }
    
    private func spawnUniqueEntity(at location: CGPoint, in view: ARView) {
        let results = view.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        guard let first = results.first,
              let planeAnchor = first.anchor as? ARPlaneAnchor,
              let anchorEntity = detectedPlanes[planeAnchor.identifier.uuidString],
              !spawnedPlaneIDs.contains(planeAnchor.identifier)
        else { return }
        
        let worldPosition = first.worldTransform.columns.3.xyz
        let localPosition = anchorEntity.convert(position: worldPosition, from: nil)
        
        spawnRedBox(at: localPosition, parent: anchorEntity)
        spawnedPlaneIDs.insert(planeAnchor.identifier)
    }
    
    private func spawnRedBox(at position: SIMD3<Float>, parent: Entity) {
        let boxMesh = MeshResource.generateBox(width: 0.1, height: 0.5, depth: 0.1)
        let redMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [redMaterial])
        
        let uniqueName = UUID().uuidString
        boxEntity.name = uniqueName
        entityChanged[uniqueName] = false
        
        let labelEntity = Entity.createTimerRing(5, radius: 0.08, thickness: 0.02) {
            if self.entityChanged[boxEntity.name] == false {
                boxEntity.components.set(InputTargetComponent())
                print("Box \(boxEntity.name) is now interactable.")
            }
        }
        
        if let bounds = boxEntity.model?.mesh.bounds {
            let visualHeight = bounds.extents.y * boxEntity.scale.y
            
            boxEntity.position = SIMD3(x: position.x, y: position.y + visualHeight / 2, z: position.z)
            boxEntity.generateCollisionShapes(recursive: true)
            
            guard let currentCameraTransform = arView.session.currentFrame?.camera.transform else {
                print("Could not get current camera transform")
                parent.addChild(boxEntity)
                return
            }
            
            let parentWorldTransform = parent.transformMatrix(relativeTo: nil)
            let boxLocalPosition = boxEntity.position
            let boxWorldPosition = parentWorldTransform * SIMD4<Float>(boxLocalPosition.x, boxLocalPosition.y, boxLocalPosition.z, 1.0)
            
            let currentCameraPosition = currentCameraTransform.columns.3.xyz
            let directionToCamera = normalize(currentCameraPosition - boxWorldPosition.xyz)
            
            let yRotation = atan2(directionToCamera.x, directionToCamera.z)
            let worldLookRotation = simd_quatf(angle: yRotation, axis: SIMD3<Float>(0, 1, 0))
            
            let parentOrientation = simd_quatf(parentWorldTransform)
            boxEntity.orientation = parentOrientation.inverse * worldLookRotation
            
            labelEntity.position = SIMD3<Float>(x: 0, y: visualHeight / 1.4, z: 0)
            
            labelEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
            
            boxEntity.addChild(labelEntity)
            parent.addChild(boxEntity)
        } else {
            print("something went wrong")
        }
    }
}
