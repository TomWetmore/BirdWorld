//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

public final class Taxonomy {

    public let roots: [Taxon]
    public let species: [Taxon]

    public init(taxa: [Taxon]) throws {
        roots = makeTaxonomy(from: taxa)
        species = roots.species
        try makeIndexes(SpeciesRequirements())
    }

    // Stored indexes.
    //
    public var englishNameIndex: [String : Taxon] = [:]
    public var scientificNameIndex: [String : Taxon] = [:]
    public var codeIndex: [String : Taxon] = [:]
    public var bandingCodeIndex: [String : Taxon] = [:]

}

/// Create a Taxonomy from an ordered list of Taxons.
///
private func makeTaxonomy(from taxa: [Taxon]) -> [Taxon] {

    var roots: [Taxon] = []
    var stack: [Taxon] = []

    for taxon in taxa {

        // Remove taxa that cannot be the parent of this taxon.
        while let last = stack.last,
              last.level.depth >= taxon.level.depth {
            stack.removeLast()
        }
        if let parent = stack.last {
            parent.children.append(taxon)
            taxon.parent = parent
        } else {
            roots.append(taxon)
        }
        stack.append(taxon)
    }

    return roots
}

extension Array<Taxon> {

    /// Return the species at or below a Taxon in an Array<Taxon>.
    public var species: [Taxon] {
        return taxa(of: .species)
    }

    /// Return the genera at or below a Taxon in an Array<Taxon>.
    ///
    public var genera: [Taxon] {
        return taxa(of: .genus)
    }

    /// Return the genera at or below a Taxon in an Array<Taxon>.
    ///
    public var families: [Taxon] {
        return taxa(of: .family)
    }

    /// Return all Taxa at a specific level at or below a Taxon in an Array<Taxon>.
    ///
    func taxa(of level: Level) -> [Taxon] {

        var result: [Taxon] = []

        func visit(_ taxon: Taxon) {
            if taxon.level == level {
                result.append(taxon)
                return
            }
            guard taxon.level.depth < level.depth else {
                return
            }
            for child in taxon.children {
                visit(child)
            }
        }
        for taxon in self {
            visit(taxon)
        }
        return result
    }

    /// Show the forest of Taxa through the specified level.
    public func show(through level: Level, indent: Int = 0) {
        for taxon in self {
            taxon.show(through: level, indent: indent)
        }
    }
}

/// Taxonomy indexing.
///
extension Taxonomy {

    /// Makes the species indexes.
    ///
    private func makeIndexes(_ requirements: SpeciesRequirements) throws {

        func insert(
            _ value: String?,
            into index: inout [String: Taxon],
            for species: Taxon,
            field: String,
            requirement: RequirementType
        ) throws {

            // Check the presence requirement.
            switch requirement {
            case .mustbe:
                guard value != nil else {
                    throw TaxaFileError.invalidLine(0, "missing \(field)")
                }

            case .cannotbe:
                if let value {
                    throw TaxaFileError.invalidLine(0, "unexpected \(field): \(value)")
                }

            case .canbe:
                break
            }

            // If the field is absent, there is nothing to index.
            guard let value else { return }

            // Check uniqueness.
            guard index[value] == nil else {
                throw TaxaFileError.invalidLine(0, "duplicate \(field): \(value)")
            }

            // Add the field to its index.
            index[value] = species
        }

        for species in self.species {

            try insert(
                species.code,
                into: &codeIndex,
                for: species,
                field: "four-lettter code",
                requirement: requirements.code
            )

            try insert(
                species.englishName,
                into: &englishNameIndex,
                for: species,
                field: "English name",
                requirement: requirements.englishName
            )

            try insert(
                species.scientificName,
                into: &scientificNameIndex,
                for: species,
                field: "scientific name",
                requirement: requirements.scientificName
            )

            try insert(
                species.bandingCode,
                into: &bandingCodeIndex,
                for: species,
                field: "banding code",
                requirement: requirements.bandingCode
            )
        }
    }

    func taxon(code: String) -> Taxon? {
        return codeIndex[code]
    }
    func taxon(englishName: String) -> Taxon? {
        return englishNameIndex[englishName]
    }
    func taxon(scientificName: String) -> Taxon? {
        return scientificNameIndex[scientificName]
    }
    func taxon(bandingCode: String) -> Taxon? {
        return bandingCodeIndex[bandingCode]
    }
}

/// Lookup methods.
///
extension Taxonomy {

    /// Try to find a Species Taxon from the Taxonomy using the indexes.
    ///
    func getSpecies(_ string: String) -> Taxon? {
        // Use code first
        var species = codeIndex[string]
        if species == nil {
            species = englishNameIndex[string]
        }
        if species == nil {
            species = scientificNameIndex[string]
        }
        return species
    }
}


/// Display methods.
extension Taxonomy {

    public func show(through level: Level) {
        for root in roots {
            root.show(through: level)
        }
    }
}
