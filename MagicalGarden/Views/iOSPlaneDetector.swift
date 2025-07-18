//
//  iOSPlaneDetector.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import SwiftUI
import RealityKit
import ARKit

final class iOSPlaneDetector: NSObject, PlaneDetectionProtocol, ObservableObject, ARSessionDelegate {    

    @Published var isDetecting = false
    @Published var detectedPlanes: [String: AnchorEntity] = [:]
    
    var onPlaneDetected: ((AnchorEntity, ARPlaneAnchor) -> Void)?
    private(set) var arView: ARView!
    private var hasStartedDetection = false
    
    func makeARView() -> ARView {
        let view = ARView(frame: .zero)
        view.session.delegate = self
        self.arView = view
        return view
    }
    
    func startDetection() async throws {
        guard !hasStartedDetection else { return }
        
        await MainActor.run { self.isDetecting = true }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        await arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        hasStartedDetection = true
    }
    
    @MainActor func stopDetection() {
        arView?.session.pause()
        hasStartedDetection = false
        
        self.isDetecting = false
        self.detectedPlanes.removeAll()
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARPlaneAnchor }) {
            let anchorEntity = AnchorEntity(anchor: anchor)
            
            Task { @MainActor in
                self.detectedPlanes[anchor.identifier.uuidString] = anchorEntity
            }

            onPlaneDetected?(anchorEntity, anchor) // Pass both
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARPlaneAnchor }) {
            if let existingAnchor = detectedPlanes[anchor.identifier.uuidString] {
                Task { @MainActor in
                    existingAnchor.transform = Transform(matrix: anchor.transform)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARPlaneAnchor }) {
            Task { @MainActor in
                if let removedAnchor = self.detectedPlanes.removeValue(forKey: anchor.identifier.uuidString) {
                    removedAnchor.removeFromParent()
                }
            }
        }
    }
    
    private func session(_ session: ARSession, didFailWithError error: Error) async {
        print("AR Session failed: \(error)")
        await MainActor.run {
            self.isDetecting = false
        }
    }
    
    private func sessionWasInterrupted(_ session: ARSession) async {
        await MainActor.run {
            self.isDetecting = false
        }
    }
}

struct PlaneDetectingARView: UIViewRepresentable {
    @ObservedObject var detector: iOSPlaneDetector
    
    func makeUIView(context: Context) -> ARView { detector.makeARView() }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
