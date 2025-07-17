//
//  RealityKit.RealityViewCameraContent.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit

#if os(iOS)

extension RealityKit.RealityViewCameraContent {
    func setupPlaneTracking() async {
        let configuration = SpatialTrackingSession.Configuration(
            tracking: [.camera, .plane],
            sceneUnderstanding: [.shadow, .occlusion],
            camera: .back
        )
        let session = SpatialTrackingSession()
        await session.run(configuration)
    }
}

#endif
