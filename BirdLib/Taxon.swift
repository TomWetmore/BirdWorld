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
public enum TaxonLevel: Int {

    case order = 0
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

    public var name: String {
        switch self {
        case .order:      "order"
        case .suborder:   "suborder"
        case .family:     "family"
        case .subfamily:  "subfamily"
        case .genus:      "genus"
        case .subgenus:   "subgenus"
        case .species:    "species"
        case .subspecies: "subspecies"
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
    public let bandingCode: String?  // "Official" USFWS banding code.

    public weak var parent: Taxon? = nil
    public var children: [Taxon] = []

    public init(level: TaxonLevel, code: String? = nil, englishName: String? = nil,
                scientificName: String? = nil, bandingCode: String? = nil) {

        self.level = level
        self.code = code
        self.englishName = englishName
        self.scientificName = scientificName
        self.bandingCode = bandingCode
    }
}

/// Methods that show Taxa.
///
extension Taxon {

    /// Description of the Taxon.
    ///
    public var description: String {
        "\(level.name): \(name)\n"
    }

    /// Display name of the Taxon.
    ///
    public var name: String {
        switch (scientificName, englishName) {
        case let (scientific?, english?):
            return "\(scientific): \(english)"
        case let (scientific?, nil):
            return scientific
        case let (nil, english?):
            return english
        case (nil, nil):
            return "no name"
        }
    }
}

extension Taxon {

    public func show(through level: TaxonLevel, indent: Int = 0) {

        guard self.level.rawValue <= level.rawValue else { return }

        print("\(String(repeating: " ", count: indent))\(self)")

        for child in children {
            child.show(through: level, indent: indent + 4)
        }
    }
}

