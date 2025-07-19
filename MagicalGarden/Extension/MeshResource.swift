//
//  MeshResource.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 19/07/25.
//

import RealityKit

extension MeshResource {
    static func generateRing(radius: Float, thickness: Float, angle: Float) -> MeshResource {
        let sides = 64
        let clampedAngle = max(0.01, min(angle, 360)) //Avoid 0 or it crashes
        let filledSides = max(1, Int(Float(sides) * clampedAngle / 360.0))

        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for i in 0...filledSides {
            let theta = Float(i) / Float(sides) * 2 * .pi
            let outerX = cos(theta) * radius
            let outerY = sin(theta) * radius
            let innerX = cos(theta) * (radius - thickness)
            let innerY = sin(theta) * (radius - thickness)

            vertices.append([outerX, outerY, 0])
            vertices.append([innerX, innerY, 0])
        }

        for i in 0..<filledSides {
            let base = UInt32(i * 2)
            guard base + 3 < vertices.count else { continue }

            indices.append(contentsOf: [
                base, base + 1, base + 3,
                base, base + 3, base + 2
            ])
        }

        guard vertices.count > 0, indices.count > 0 else {
            fatalError("Invalid ring geometry: no vertices or indices.")
        }

        var meshDesc = MeshDescriptor(name: "Ring")
        meshDesc.positions = MeshBuffer(vertices)
        meshDesc.primitives = .triangles(indices)

        do {
            return try MeshResource.generate(from: [meshDesc])
        } catch {
            print("Failed to generate ring mesh: \(error)")
            fatalError("Ring mesh generation failed: \(error)")
        }
    }
}
