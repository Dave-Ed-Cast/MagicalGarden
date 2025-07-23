//
//  iOSPlaneDetector+Public.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 18/07/25.
//

import SwiftUI
import RealityKit
import ARKit

#if os(iOS)
//MARK: Completely public methods (for reading clarity)
extension ObjectSpawnerAndHandler {
    
    /// Adds a reference of plane and anchor to the ARView
    /// - Parameters:
    ///   - session: The ARView session
    ///   - anchors: The anchor to add
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARPlaneAnchor }) {
            let anchorEntity = AnchorEntity(anchor: anchor)
            
            Task { @MainActor in
                self.detectedPlanes[anchor.identifier.uuidString] = anchorEntity                
                onPlaneDetected?(anchorEntity, anchor)
            }
        }
    }
}

struct PlaneDetectingARView: UIViewRepresentable {
    @Bindable var detector: ObjectSpawnerAndHandler
    
    func makeUIView(context: Context) -> ARView { detector.makeARView() }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
#endif

