//
//  PlaneDetectionProtocol.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import Foundation
import ARKit

#if os(iOS)
protocol PlaneDetectionProtocol {
    func startDetection() async throws
    var onPlaneDetected: ((_ anchorEntity: AnchorEntity, _ planeAnchor: ARPlaneAnchor) -> Void)? { get set }
}
#endif
