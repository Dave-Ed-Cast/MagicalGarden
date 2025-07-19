//
//  VisionPlaneDetector.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import ARKit

#if os(visionOS)
@available(macOS 14.0, iOS 17.0, *)
final class VisionPlaneDetector: PlaneDetectionProtocol, ObservableObject {
    
    var root: Entity
    private let session = ARKitSession()
    private let provider = PlaneDetectionProvider()
    var onPlaneDetected: ((AnchorEntity) -> Void)?

    init(root: Entity) { self.root = root }

    func startDetection() async throws {
        guard PlaneDetectionProvider.isSupported else {
            throw NSError(domain: "PlaneDetection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not supported"])
        }
        try await session.run([provider])
        provider.onPlaneDetected = { planeAnchor in
            let anchorEntity = AnchorEntity(anchor: planeAnchor)
            self.onPlaneDetected?(anchorEntity)
        }
    }
}
#endif
