//
//  simd_quatf.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 19/07/25.
//

import simd
import RealityKit

extension simd_quatf {
    /// Creates a quaternion that rotates a forward-facing vector (`-Z`) to look at the user from a given origin.
    func lookAtUser(from origin: SIMD3<Float>, to cameraTransform: simd_float4x4) -> simd_quatf {
        let cameraPosition = cameraTransform.columns.3.xyz
        let direction = normalize(cameraPosition - origin)
        return simd_quatf(from: [0, 0, -1], to: direction)
    }
}
