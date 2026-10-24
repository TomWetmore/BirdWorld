//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 24 October 2026.
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

    func getGroup(_ string: String) -> BirdGroup? {
        return nil
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
