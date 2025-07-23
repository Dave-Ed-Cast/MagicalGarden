//
//  SIMD4.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 18/07/25.
//

import Foundation

extension SIMD4 {
    /// Simple way to return world coordinates of an entity
    var xyz: SIMD3<Scalar> { self[SIMD3(0, 1, 2)] }
}

