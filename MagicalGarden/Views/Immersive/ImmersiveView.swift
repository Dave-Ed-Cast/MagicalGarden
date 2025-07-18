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
    
    let root: Entity = .init()
    
    var body: some View {
        ZStack {
#if os(iOS)
            if let iosDetector = planeDetector as? iOSPlaneDetector {
                PlaneDetectingARView(detector: iosDetector)
                    .edgesIgnoringSafeArea(.all)
            }
#else
            RealityView { content in
                content.add(root)
                let detector = VisionPlaneDetector(root: root)
            }
#endif
        }
        .onAppear {
            if planeDetector == nil { setupPlaneDetector() }
            
            Task { @MainActor in
                try? await planeDetector?.startDetection()
                planeDetector?.onPlaneDetected = { anchorEntity, arAnchor in
                    let width = arAnchor.planeExtent.width
                    let depth = arAnchor.planeExtent.height
                    let height: Float = 0.05
                    
                    let position = SIMD3<Float>(arAnchor.center.x, arAnchor.center.y / 2, arAnchor.center.z)
                    
                    let mesh = MeshResource.generateBox(size: [width, height, depth])
                    let material = SimpleMaterial(color: .green.withAlphaComponent(0.5), isMetallic: false)
                    let box = ModelEntity(mesh: mesh, materials: [material])
                    
                    box.position = position
                    anchorEntity.addChild(box)
                    
#if os(iOS)
                    if let iosDetector = planeDetector as? iOSPlaneDetector {
                        iosDetector.arView.scene.addAnchor(anchorEntity)
                        print("Plane box added: \(width) x \(depth)m")
                    }
#else
                    content.add(anchorEntity)
#endif
                }
            }
        }
    }
    
    private func setupPlaneDetector() {
        let detector = iOSPlaneDetector()
        planeDetector = detector
    }
}
