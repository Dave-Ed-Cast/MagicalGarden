//
//  iOSPlaneDetector.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import RealityKitContent
import ARKit

@Observable
final class iOSPlaneDetector: NSObject, PlaneDetectionProtocol, ARSessionDelegate {
    
    var isDetecting = false
    var detectedPlanes: [String: AnchorEntity] = [:]
    var onPlaneDetected: ((AnchorEntity, ARPlaneAnchor) -> Void)?
    var entityChanged: [String: Bool] = [:]
    
    private(set) var arView: ARView!
    private var planePlantIndex: [UUID: Int] = [:]
    private var planeActivePlants: [UUID: Set<String>] = [:]
    private var plantToPlane: [String: UUID] = [:]
    private let maxPlantsPerPlane = PlantType.allCases.count
    
    private var allPlantsBloomedSoundPlayed = false
    private var hasStartedDetection = false
    
    func makeARView() -> ARView {
        let view = ARView(frame: .zero)
        view.session.delegate = self
        self.arView = view
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        Task { @MainActor in
            guard let particleBloom = try? await Entity(named: "ParticleBloom", in: realityKitContentBundle) else {
                print("Failed to load ParticleBloom entity")
                return
            }
            
            particleBloom.name = "ParticleBloom"
            particleBloom.isEnabled = false
            
            let anchor = AnchorEntity(world: .one)
            anchor.addChild(particleBloom)
            view.scene.addAnchor(anchor)
        }
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
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = arView else { return }
        let tapLocation = sender.location(in: view)
        
        if changeEntityStatus(at: tapLocation, in: view) { return }
        
        spawnUniqueEntity(at: tapLocation, in: view)
    }
    
    private func changeEntityStatus(at location: CGPoint, in view: ARView) -> Bool {
        guard var entity = view.entity(at: location) else { return false }
        
        while let parent = entity.parent, entity.components[PlantComponent.self] == nil { entity = parent }
        
        guard let plantComp = entity.components[PlantComponent.self] else {  return false }
        
        let timerCompleted = hasTimerCompleted(in: entity)
        
        if entityChanged[plantComp.id] == false, plantComp.stage != .bloom, timerCompleted {
            entityChanged[plantComp.id] = true
            Task { await advancePlantStage(for: entity, component: plantComp) }
            return true
        } else if !timerCompleted, plantComp.stage == .growth {
            print("Timer not completed yet - wait for 'Tap to bloom!' message")
        }
        return false
    }
    
    private func hasTimerCompleted(in entity: Entity) -> Bool {
        for child in entity.children {
            if child.name == "sphere_timer_container" {
                for grandChild in child.children {
                    if grandChild.name == "sphere_timer_completion_text" { return true }
                }
            }
        }
        return false
    }
    
    private func spawnUniqueEntity(at location: CGPoint, in view: ARView) {
        let results = view.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)
        guard let first = results.first,
              let planeAnchor = first.anchor as? ARPlaneAnchor,
              let anchorEntity = detectedPlanes[planeAnchor.identifier.uuidString]
        else { return }
        
        let planeId = planeAnchor.identifier
        
        let currentIndex = planePlantIndex[planeId] ?? 0
        guard currentIndex < maxPlantsPerPlane else { return }
        
        let plantType = PlantType.allCases[currentIndex]
        let worldPosition = first.worldTransform.columns.3.xyz
        let localPosition = anchorEntity.convert(position: worldPosition, from: nil)
        
        if !isValidSpawnLocation(localPosition, on: planeId, minDistance: 0.4) { return }
        
        Task { @MainActor in
            await spawnPlantModel(at: localPosition, parent: anchorEntity, type: plantType, planeId: planeId)
        }
        
        planePlantIndex[planeId] = currentIndex + 1
    }
    
    private func isValidSpawnLocation(_ position: SIMD3<Float>, on planeId: UUID, minDistance: Float) -> Bool {
        guard let activePlants = planeActivePlants[planeId] else { return true }
        
        guard let planeAnchor = detectedPlanes[planeId.uuidString] else { return true }
        
        for plantId in activePlants {
            if let existingPlant = findPlantEntity(with: plantId, in: planeAnchor) {
                let distance = length(position - existingPlant.position)
                if distance < minDistance { return false }
            }
        }
        return true
    }
    
    private func findPlantEntity(with id: String, in parent: Entity) -> Entity? {
        if parent.name == id { return parent }
        for child in parent.children {
            if let found = findPlantEntity(with: id, in: child) { return found }
        }
        return nil
    }
    
    func spawnPlantModel(at position: SIMD3<Float>, parent: Entity, type: PlantType, planeId: UUID) async {
        let plantId = UUID().uuidString
        let modelName = "\(type.rawValue)_Growth"
        
        guard let plantEntity = try? await ModelEntity(named: modelName) else { return }
        
        await MainActor.run {
            plantEntity.name = plantId
            plantEntity.position = position
        }
        
        let randomTime = Int.random(in: 30...180)
        let timerEntity = await Entity.createSphericalFillingTimer(randomTime, radius: 0.1) {
            plantEntity.components.set(
                [
                    InputTargetComponent(),
                    PlantComponent(id: plantId, type: type, stage: .growth)
                ]
            )
            plantEntity.generateCollisionShapes(recursive: true)
        }
        
        entityChanged[plantId] = false
        plantToPlane[plantId] = planeId
        
        if planeActivePlants[planeId] == nil { planeActivePlants[planeId] = Set<String>() }
        planeActivePlants[planeId]?.insert(plantId)
        
        if let bounds = await plantEntity.model?.mesh.bounds {
            let visualHeight = await bounds.extents.y * plantEntity.scale.y
            
            await MainActor.run {
                plantEntity.position = SIMD3(x: position.x, y: position.y + visualHeight / 2, z: position.z)
                plantEntity.addChild(timerEntity)
                parent.addChild(plantEntity)
                
                Entity.playSound(named: "SFX_1", on: plantEntity)
            }
        } else {
            print("something went wrong")
        }
        
        print("Spawned \(type.rawValue) plant (\(plantId)) with timer ring on plane \(planeId)")
    }
    
    private func advancePlantStage(for entity: Entity, component: PlantComponent) async {
        guard let nextStage = component.stage.next else {
            print("Plant \(component.id) is already in final bloom stage")
            return
        }
        
        if component.stage == .growth && nextStage == .growthBloom {
            await replaceWithAnimatedModel(entity: entity, component: component)
            return
        }
        
        let modelName = "\(component.type.rawValue)_\(nextStage.rawValue)"
        
        guard let newEntity = try? await Entity(named: modelName) else {
            print("Failed to load model: \(modelName)")
            return
        }
        
        let updatedComponent = PlantComponent(id: component.id, type: component.type, stage: nextStage)
        
        await MainActor.run {
            Entity.setNewEntity(newEntity, from: entity, with: updatedComponent)
            Entity.playSound(named: "SFX_3", on: newEntity)
        }
    }
    
    private func replaceWithAnimatedModel(entity: Entity, component: PlantComponent) async {
        
        let animatedModelName = "\(component.type.rawValue)_\(component.stage.rawValue)"
        
        guard let animatedEntity = try? await Entity(named: animatedModelName) else {
            print("Error loading animated model: \(animatedModelName)")
            return
        }
        
        let updatedComponent = PlantComponent(id: component.id, type: component.type, stage: .growthBloom)
        
        await MainActor.run {
            
            if let timerEntity = entity.children.first(where: { $0.name == "ring_timer" }) { timerEntity.removeFromParent() }
            
            Entity.setNewEntity(animatedEntity, from: entity, with: updatedComponent)
            Entity.playSound(named: "SFX_4", on: animatedEntity)
            
            if let animation = animatedEntity.availableAnimations.first { animatedEntity.playAnimation(animation) }
        }
        
        do { try await Task.sleep(for: .seconds(2)) }
        catch { print("couldn't delay") }
        
        await replaceWithFinalModel(entity: animatedEntity, component: updatedComponent)
    }
    
    private func replaceWithFinalModel(entity: Entity, component: PlantComponent) async {
        let finalModelName = "\(component.type.rawValue)_Bloom"
        
        do {
            let finalEntity = try await Entity(named: finalModelName)
            let finalComponent = PlantComponent(id: component.id, type: component.type, stage: .bloom)
            
            await MainActor.run { Entity.setNewEntity(finalEntity, from: entity, with: finalComponent, last: true) }
            await checkAllPlantsBloomedAndPlaySound(finalEntity)
        } catch {
            print("Error loading final model: \(finalModelName), error: \(error)")
        }
    }
    
    private func checkAllPlantsBloomedAndPlaySound(_ entity: Entity) async {
        guard !allPlantsBloomedSoundPlayed else { return }
        
        let allBloomed = plantToPlane.keys.allSatisfy { plantId in
            entityChanged[plantId] == true
        }
        
        if allBloomed, plantToPlane.count == PlantType.allCases.count {
            allPlantsBloomedSoundPlayed = true
            
            try? await Task.sleep(for: .seconds(2))
            await Entity.playSound(named: "SFX_7", on: entity)
            await startParticleEmitter()
        }
    }
    
    @MainActor func startParticleEmitter() {
        Task {
            guard let particleBloom = arView.scene.findEntity(named: "ParticleBloom"),
            let particleEmitter = particleBloom.findEntity(named: "ParticleEmitter")
            else {
                print("couldn't find particle bloom")
                print(arView.scene.anchors)
                return
            }
            print("got it")
            
            guard var emitter = particleEmitter.components[ParticleEmitterComponent.self] else {
                print("emitter not found")
                return
            }
            emitter.isEmitting = true
            particleEmitter.components.set(emitter)
            particleEmitter.isEnabled = true
            particleBloom.isEnabled = true
            
            particleBloom.position.z -= 0.75
        }
    }
}
