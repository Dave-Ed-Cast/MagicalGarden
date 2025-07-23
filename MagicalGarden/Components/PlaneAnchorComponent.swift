//
//  PlaneAnchorComponent.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 22/07/25.
//

import ARKit
import RealityFoundation
#if os(visionOS)
struct PlaneAnchorComponent: Component { let anchor: PlaneAnchor }
struct PlaneAssociationComponent: Component { let planeId: UUID }
#endif
