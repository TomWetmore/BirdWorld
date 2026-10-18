//
//  Taxon.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 17 October 2026.
//  Last changed on 18 October 2026
//

import Foundation

/// Allowed levels in Taxonomies. (May need to add more.)
///
public enum TaxonLevel: String {

    case order
    case suborder
    case family
    case subfamily
    case genus
    case subgenus
    case species
    case subspecies
}

extension TaxonLevel {

    var depth: Int {
        switch self {
        case .order:      0
        case .suborder:   1
        case .family:     2
        case .subfamily:  3
        case .genus:      4
        case .subgenus:   5
        case .species:    6
        case .subspecies: 7
        }
    }
}

/// Taxon.
///
public final class Taxon: CustomStringConvertible {

    public let level: TaxonLevel
    public let code: String? // Wetmore four-letter code for species/groups.
    public let englishName: String?
    public let scientificName: String?
    public let bandingCode: String?  // "Official" FWS banding code.

    public weak var parent: Taxon? = nil
    public var children: [Taxon] = []

    public init(level: TaxonLevel, code: String? = nil, englishName: String? = nil,
                scientificName: String? = nil, bandingCode: String? = nil) {

            self.level = level

            self.code = nil

            self.englishName = englishName

            self.scientificName = scientificName

            self.bandingCode = bandingCode

        }

//    public init(_ description: TaxonDescription) {
//        level = description.level
//        code = description.code
//        englishName = description.englishName
//        scientificName = description.scientificName
//        bandingCode = description.bandingCode
//    }
}

/// Methods that show Taxa.
///
extension Taxon {

    public var description: String {
        "\(level.rawValue) \(englishName ?? "no name")\n"
    }
}

