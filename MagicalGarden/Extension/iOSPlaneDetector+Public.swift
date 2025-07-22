//
//  iOSPlaneDetector+Public.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 18/07/25.
//

import SwiftUI
import RealityKit
import ARKit

//MARK: Completely public methods (for reading clarity)
extension iOSPlaneDetector {
    
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
    @Bindable var detector: iOSPlaneDetector
    
    func makeUIView(context: Context) -> ARView { detector.makeARView() }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

