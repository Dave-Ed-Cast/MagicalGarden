//
//  ImmersiveView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ImmersiveView: View {
    @State private var planeDetector: PlaneDetectionProtocol?
    @State private var rotateArrow = false
    
    let root: Entity = .init()
    
    var body: some View {
        
#if os(visionOS)
        RealityView { content in
            content.add(root)
            let detector = VisionPlaneDetector(root: root)
        }
        
#elseif os(iOS)
        ZStack {
            if let iosDetector = planeDetector as? iOSPlaneDetector {
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
        let detector = iOSPlaneDetector()
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
                let material = SimpleMaterial(color: .green.withAlphaComponent(0.3), isMetallic: false)
                let box = ModelEntity(mesh: mesh, materials: [material])
                
                box.position = position
                anchorEntity.addChild(box)
                
                if let iosDetector = planeDetector as? iOSPlaneDetector {
                    Task.detached { @MainActor in
                        iosDetector.arView.scene.addAnchor(anchorEntity)
                        print("Plane box added: \(width) x \(depth)m")
                    }
                }
            }
        }
    }
#endif
}
