//
//  PlaneDetector.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 22/07/25.
//

import RealityKit
import ARKit

#if os(iOS)
import RealityKitContent
#endif

@Observable
final class ObjectSpawnerAndHandler: NSObject {
    
    #if os(visionOS)
    var root: Entity
    var meshGenerator: MeshGenerator?
    
    init(root: Entity) {
        self.root = root
        self.meshGenerator = MeshGenerator(root: root)
    }
    
    #elseif os(iOS)
    private(set) var arView: ARView!
    var isDetecting = false
    var onPlaneDetected: ((AnchorEntity, ARPlaneAnchor) -> Void)?
    
    private var hasStartedDetection = false
    #endif
    
    var detectedPlanes: [String: AnchorEntity] = [:]
    
    private let maxPlantsPerPlane = PlantType.allCases.count
    
    private var entityChanged: [String: Bool] = [:]
    private var planePlantIndex: [UUID: Int] = [:]
    private var planeActivePlants: [UUID: Set<String>] = [:]
    private var plantToPlane: [String: UUID] = [:]    
    private var allPlantsBloomedSoundPlayed = false

    #if os(iOS)
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
        
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.prepare()
        haptic.impactOccurred()
        
        if changeEntityStatus(at: tapLocation, in: view) { return }
        
        spawnUniqueEntity(at: tapLocation, in: view)
    }
    
    private func changeEntityStatus(at location: CGPoint, in view: ARView) -> Bool {
        guard var entity = view.entity(at: location) else { return false }
        
        while let parent = entity.parent, entity.components[PlantComponent.self] == nil { entity = parent }
        
        guard let plantComp = entity.components[PlantComponent.self] else { return false }
        
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
    
    #endif
    #if os(visionOS)
    
    @MainActor
    func handleTap(location: SIMD3<Float>) async {
        guard let planeDetector = root.components[PlaneDetectorComponent.self]?.detector else {
            print("PlaneDetector not found. Falling back to interaction.")
            _ = await changeEntityStatus(at: location)
            return
        }

        var nearestPlane: AnchorEntity?
        var shortestDistance = Float.greatestFiniteMagnitude

        for plane in planeDetector.detectedPlanes.values {
            let distance = simd_distance(plane.position, location)
            if distance < shortestDistance {
                shortestDistance = distance
                nearestPlane = plane
            }
        }

        guard let anchorEntity = nearestPlane else {
            print("No nearby plane found. Falling back to interaction.")
            _ = await changeEntityStatus(at: location)
            return
        }

        let planeId = anchorEntity.components[PlaneIDComponent.self]?.id ?? UUID()
        let currentIndex = planeDetector.planePlantIndex[planeId] ?? 0
        
        let canSpawn = (currentIndex < PlantType.allCases.count) &&
                       planeDetector.isValidSpawnLocation(location, on: planeId, minDistance: 0.4)

        if canSpawn {
            
            let nextPlantType = PlantType.allCases[currentIndex]
            await planeDetector.spawnPlantModel(
                at: location,
                parent: anchorEntity,
                type: nextPlantType,
                planeId: planeId
            )
            planeDetector.planePlantIndex[planeId] = currentIndex + 1
        } else {
            _ = await changeEntityStatus(at: location)
        }
    }
    private func changeEntityStatus(at location: SIMD3<Float>) async -> Bool {
        
        // Define a radius to detect a tap on a plant entity.
        let tapThreshold: Float = 0.25 // 25cm radius.
        var closestEntity: Entity?
        var minDistance = Float.greatestFiniteMagnitude
        
        // Iterate through all known plants to find the one closest to the tap location.
        // The `plantToPlane` dictionary handily tracks all active plants.
        for plantId in plantToPlane.keys {
            
            // `root.findEntity(named:)` recursively searches for an entity with the given name.
            if let entity = await root.findEntity(named: plantId) {
                
                // Get the entity's position in world coordinates.
                let entityPosition = await entity.position(relativeTo: nil)
                let distance = simd_distance(entityPosition, location)
                
                if distance < minDistance {
                    minDistance = distance
                    closestEntity = entity
                }
            }
        }
        
        // If the closest plant is within our tap threshold, proceed.
        guard minDistance < tapThreshold, var entity = closestEntity else {
            return false
        }
        
        // This loop ensures we have the main parent entity that holds the PlantComponent,
        // in case a child part of the model was the closest entity found.
        while let parent = await entity.parent, await entity.components[PlantComponent.self] == nil {
            // We stop at the root to avoid issues.
            if parent == root { break }
            entity = parent
        }
        
        // Now, we replicate the logic from the iOS version of this function.
        guard let plantComp = await entity.components[PlantComponent.self] else { return false }
        
        let timerCompleted = hasTimerCompleted(in: entity)
        
        // Check if the plant is ready to advance to the next stage.
        if entityChanged[plantComp.id] == false, plantComp.stage != .bloom, timerCompleted {
            entityChanged[plantComp.id] = true
            Task { await advancePlantStage(for: entity, component: plantComp) }
            return true
        } else if !timerCompleted, plantComp.stage == .growth {
            print("Timer not completed yet - wait for 'Tap to bloom!' message")
        }
        
        return false
    }
    #endif
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
#if os(iOS)
            guard let particleBloom = arView.scene.findEntity(named: "ParticleBloom") else {
                print("couldn't find particle bloom")
                return
            }
#elseif os(visionOS)
            guard let particleBloom = root.findEntity(named: "ParticleBloom") else {
                print("couldn't find particle bloom")
                return
            }
            print("got it")
#endif
            
            if let particleEmitter = particleBloom.findEntity(named: "ParticleEmitter") {
                
                guard var emitter = particleEmitter.components[ParticleEmitterComponent.self] else {
                    print("emitter not found")
                    return
                }
                emitter.isEmitting = true
                particleEmitter.components.set(emitter)
                particleEmitter.isEnabled = true
                particleBloom.isEnabled = true
                
                particleBloom.position.z -= 1
            }
        }
    }
}

#if os(iOS)
extension ObjectSpawnerAndHandler: PlaneDetectionProtocol, ARSessionDelegate {}
#endif
