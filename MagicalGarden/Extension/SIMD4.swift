//
//  SIMD4.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 18/07/25.
//

import Foundation

extension SIMD4 {
    var xyz: SIMD3<Scalar> { self[SIMD3(0, 1, 2)] }
}

