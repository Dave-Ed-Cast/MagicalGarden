//
//  ImmersiveView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    
    @State private var planeDetector: ObjectSpawnerAndHandler? = nil
    @State private var rotateArrow = false
        
    var body: some View {
        let root = Entity()
        
#if os(visionOS)
        RealityView { content in
            
            
            await setupPlaneDetection(root: root)
            
            if let particleBloom = try? await Entity(named: "ParticleBloom", in: realityKitContentBundle) {
                particleBloom.name = "ParticleBloom"
                particleBloom.isEnabled = false
                root.addChild(particleBloom)
            }
            
            content.add(root)
        }
        .gesture(
            SpatialTapGesture(coordinateSpace: .global)
                .targetedToAnyEntity()
                .onEnded { value in
                    print("tap!")

                    Task {
                        let worldLocation = value.convert(value.location3D, from: .global, to: root)
                        if let detector = planeDetector { await detector.handleTap(location: worldLocation) }
                    }
                }
        )
#elseif os(iOS)
        ZStack {
            if let iosDetector = planeDetector {
                PlaneDetectingARView(detector: iosDetector)
                    .edgesIgnoringSafeArea(.all)
                
                if iosDetector.detectedPlanes.isEmpty {
                    VStack(spacing: 20) {
                        Text("Slowly move the phone \nto detect surfaces.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotateArrow ? 360 : 0))
                            .animation(.linear(duration: 2.5).repeatForever(autoreverses: false), value: rotateArrow)
                            .onAppear { rotateArrow = true }
                    }
                    .padding(.top, 100)
                }
            }
        }
        .onAppear {
            if planeDetector == nil { setupPlaneDetector() }
            addPlane()
        }
#endif
    }
#if os(iOS)
    private func setupPlaneDetector() {
        let detector = ObjectSpawnerAndHandler()
        planeDetector = detector
    }
    
    private func addPlane() {
        Task {
            try? await planeDetector?.startDetection()
            planeDetector?.onPlaneDetected = { anchorEntity, arAnchor in
                
                let width = arAnchor.planeExtent.width
                let depth = arAnchor.planeExtent.height
                let height: Float = 0.05
                
                let position = SIMD3<Float>(arAnchor.center.x, 0, arAnchor.center.z)
                
                let mesh = MeshResource.generateBox(size: [width, height, depth])
                let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.3), isMetallic: false)
                let box = ModelEntity(mesh: mesh, materials: [material])
                
                box.position = position
                anchorEntity.addChild(box)
                
                if let iosDetector = planeDetector {
                    Task.detached { @MainActor in
                        iosDetector.arView.scene.addAnchor(anchorEntity)
                        print("Plane box added: \(width) x \(depth)m")
                    }
                }
            }
        }
    }
#elseif os(visionOS)
    private func setupPlaneDetection(root: Entity) async {
        let arSession = ARKitSession()
        let planeProvider = PlaneDetectionProvider()
        
        Task {
            let generator = MeshGenerator(root: root)
            let detector = ObjectSpawnerAndHandler(root: root)
            self.planeDetector = detector
            
            root.components.set(PlaneDetectorComponent(detector: detector))

            guard PlaneDetectionProvider.isSupported else {
                print("PlaneDetectionProvider is not supported on this device.")
                return
            }
            
            do { try await arSession.run([planeProvider]) }
            catch { print("Encountered an error while running providers: \(error.localizedDescription)") }
            
            await generator.run(planeProvider) { planeId, entity in
                detector.detectedPlanes[planeId.uuidString] = entity
            }
        }
    }
#endif
}
