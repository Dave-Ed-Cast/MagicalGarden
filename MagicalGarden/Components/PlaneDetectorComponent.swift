//
//  PlaneDetectorComponent.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 22/07/25.
//

import RealityFoundation
#if os(visionOS)
struct PlaneDetectorComponent: Component { var detector: ObjectSpawnerAndHandler }
#endif
