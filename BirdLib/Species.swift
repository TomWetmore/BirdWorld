//
//  Species.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 21 October 2026.
//

import Foundation

enum Requirement {

    case mustbe
    case cannotbe
    case canbe
}

/// Required properties for a Species.
///
public struct SpeciesRequirements {

    var code: Requirement = .canbe
    var englishName: Requirement = .mustbe
    var scientificName: Requirement = .mustbe
    var bandingCode: Requirement = .canbe

    init(code: Requirement = .canbe, englishName: Requirement = .mustbe,
        scientificName: Requirement = .mustbe, bandingCode: Requirement = .canbe) {
        self.code = code
        self.englishName = englishName
        self.scientificName = scientificName
        self.bandingCode = bandingCode
    }


}
