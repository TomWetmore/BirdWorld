//
//  Species.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 21 October 2026.
//

import Foundation

enum RequirementType {

    case mustbe
    case cannotbe
    case canbe
}

/// Required properties for a Species.
///
public struct SpeciesRequirements {

    var code: RequirementType = .canbe
    var englishName: RequirementType = .mustbe
    var scientificName: RequirementType = .mustbe
    var bandingCode: RequirementType = .canbe

    init(code: RequirementType = .canbe, englishName: RequirementType = .mustbe,
        scientificName: RequirementType = .mustbe, bandingCode: RequirementType = .canbe) {
        self.code = code
        self.englishName = englishName
        self.scientificName = scientificName
        self.bandingCode = bandingCode
    }


}
