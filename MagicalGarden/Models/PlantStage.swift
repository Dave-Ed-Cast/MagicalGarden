//
//  PlantStage.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 21/07/25.
//

import RealityKit


enum PlantStage: String, Codable {
    case growth = "Growth"
    case growthBloom = "Growth+Bloom"
    case bloom = "Bloom"
}

enum PlantType: String, CaseIterable, Codable {
    case plant01 = "Plant_01"
    case plant02 = "Plant_02"
    case plant03 = "Plant_03"
}

///Stages of plant to keep track of as a component
struct PlantComponent: Component {
    var id: String
    var type: PlantType
    var stage: PlantStage
}

extension PlantStage {
    var next: PlantStage? {
        switch self {
        case .growth: return .growthBloom
        case .growthBloom: return .bloom
        case .bloom: return nil
        }
    }
}
