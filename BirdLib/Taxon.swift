//
//  Taxon.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 17 October 2026.
//  Last changed on 24 October 2026
//

import Foundation

/// Taxon is a fundamental type in the Bird World. Each Taxon represents one element in a
/// Taxonomy. Each Taxon has a Level (e.g., order, family, species), and a name. Taxa at
/// different levels are not yet there own types, though some may become so in the future.
///
public final class Taxon: CustomStringConvertible {

    public let level: Level
    public let code: String? // Wetmore four-letter code for species/groups.
    public let englishName: String?
    public let scientificName: String?
    public let bandingCode: String?  // USFWS banding code.
    public var order: Int? = nil

    public weak var parent: Taxon? = nil
    public var children: [Taxon] = []

    /// Create a Taxon. Only level is required, though without at least one name property,
    /// it will not be very interesting.
    ///
    public init(level: Level, code: String? = nil, englishName: String? = nil,
                scientificName: String? = nil, bandingCode: String? = nil) {

        self.level = level
        self.code = code
        self.englishName = englishName
        self.scientificName = scientificName
        self.bandingCode = bandingCode
    }
}

extension Taxon {

    // All species Taxa at or below a Taxon.
    var species: [Taxon] {
        [self].species
    }

    /// All genera Taxa at or below a Taxon.
    ///
    var genera: [Taxon] {
        [self].genera
    }
}

/// Methods that show a Taxon.
///
extension Taxon {

    /// The description of a single Taxon, made up of the level and the name.
    ///
    public var description: String {
        if let order {
            "\(order). \(level.rawValue): \(name)"
        } else {
            "\(level.rawValue): \(name)"
        }
    }

    /// The display name of a Taxon. Shows the available.
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

    /// Show the Taxonomy at this Taxon and below.
    ///
    public func show(through level: Level, indent: Int = 0) {

        // Don't show Taxa below the chosen level.
        guard self.level.depth <= level.depth else {
            return
        }
        print("\(String(repeating: " ", count: indent))\(self)")
        // Recurse to the children of this Taxon.
        for child in children {
            child.show(through: level, indent: indent + 4)
        }
    }
}

/// Taxon levels. The back ticks on "class" allow it to be used as an identifier.
///
public enum Level: String, CaseIterable {

    case `class`
    case order
    case suborder
    case family
    case subfamily
    case genus
    case subgenus
    case species
    case subspecies

    /// Return the depth of a Taxon, class at the top, subspecies at the bottom.
    var depth: Int {

        switch self {

        case .class:       0
        case .order:      10
        case .suborder:   20
        case .family:     30
        case .subfamily:  40
        case .genus:      50
        case .subgenus:   60
        case .species:    70
        case .subspecies: 80
        }
    }
}

extension Taxon: Hashable {

    public static func == (lhs: Taxon, rhs: Taxon) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
