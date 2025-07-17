//
//  ImmersiveView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ImmersiveView: View {
    @State private var planeDetector: (any PlaneDetectionProtocol & ObservableObject)?
    @State private var objectWillChangeSubscription: AnyCancellable?
    
    var body: some View {
        ZStack {
            #if os(iOS)
            if let iosDetector = planeDetector as? iOSPlaneDetector {
                PlaneDetectingARView(detector: iosDetector)
                    .edgesIgnoringSafeArea(.all)
            }
            #else
            RealityView { content in
                
            }
            #endif
        }
        .onAppear {
            if planeDetector == nil {
                setupPlaneDetector()
            }
            
            Task { @MainActor in
                try? await planeDetector?.startDetection()
                planeDetector?.onPlaneDetected = { anchor in
                    let box = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .green, isMetallic: false)])
                    box.position = .zero
                    anchor.addChild(box)
                    
                    #if os(iOS)
                    if let iosDetector = planeDetector as? iOSPlaneDetector {
                        iosDetector.arView.scene.addAnchor(anchor)
                        print("adding")
                    }
                    #else
                    content.add(anchor)
                    #endif
                }
            }
        }
        .onDisappear {
            objectWillChangeSubscription?.cancel()
        }
    }
    
    private func setupPlaneDetector() {
        #if os(visionOS)
        let detector = VisionPlaneDetector(root: )
        #else
        let detector = iOSPlaneDetector()
        #endif
        
        planeDetector = detector
        
        
        objectWillChangeSubscription = detector.objectWillChange.sink { _ in }
    }
}
