//
//  PlaneDetectionProtocol.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import RealityKit
import Foundation

protocol PlaneDetectionProtocol {

    func startDetection() async throws
    var onPlaneDetected: ((_ anchorEntity: AnchorEntity) -> Void)? { get set }
}
