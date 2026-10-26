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

    public init(taxa: [Taxon], useGroups: Bool = false) throws {

        roots = makeTaxonomy(from: taxa)
        species = roots.species
        try makeIndexes(SpeciesRequirements(), useGroups: useGroups)
    }

    // Stored indexes.
    //
    public var englishNameIndex: [String : Taxon] = [:]
    public var scientificNameIndex: [String : Taxon] = [:]
    public var codeIndex: [String : Taxon] = [:]
    public var bandingCodeIndex: [String : Taxon] = [:]

    // Fleshed out if BirdGroups are used.
    public var higherTaxonIndex: [String : Taxon] = [:]

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
    private func makeIndexes(_ requirements: SpeciesRequirements,
                             useGroups: Bool = false) throws {

        /// Internal function that adds ...
        func insert(_ value: String?, into index: inout [String: Taxon],
            for species: Taxon, field: String, requirement: Requirement) throws {

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
            guard let value else {
                return
            }
            // Check uniqueness.
            guard index[value] == nil else {
                throw TaxaFileError.invalidLine(0, "duplicate \(field): \(value)")
            }
            // Add the field to its index.
            index[value] = species
        }
        // Index the species.
        for species in self.species {

            try insert(species.code, into: &codeIndex, for: species,
                field: "four-letter code", requirement: requirements.code)
            try insert(species.englishName, into: &englishNameIndex, for: species,
                field: "English name", requirement: requirements.englishName)
            try insert(species.scientificName, into: &scientificNameIndex, for: species,
                field: "scientific name", requirement: requirements.scientificName)
            try insert(species.bandingCode, into: &bandingCodeIndex, for: species,
                field: "banding code", requirement: requirements.bandingCode)
        }

        // Index the higher level taxa if groups are used.
        guard useGroups else {
            return
        }
        try roots.traverse { taxon in
            guard taxon.level.depth < Level.species.depth else {
                return
            }
            try insert(taxon.scientificName, into: &higherTaxonIndex,
                       for: taxon, field: "scientific name", requirement: .canbe)
        }
    }

    /// Look up a species by code.
    ///
    func taxon(code: String) -> Taxon? {

        return codeIndex[code]
    }

    /// Look up a species by English name.
    ///
    func taxon(englishName: String) -> Taxon? {

        return englishNameIndex[englishName]
    }

    /// Look up a species by scientific name.
    ///
    func taxon(scientificName: String) -> Taxon? {

        return scientificNameIndex[scientificName]
    }

    /// Look up a species by its USFWS banding code.
    ///
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

public func loadTaxonomy(from taxaURL: URL, groupsURL: URL? = nil) throws -> Taxonomy {

    let useGroups = groupsURL != nil
    let taxa = try readTaxa(from: taxaURL)
    let taxonomy = try Taxonomy(taxa: taxa, useGroups: useGroups)
    if useGroups {
        let groups = try readGroups(url: groupsURL!, taxonomy: taxonomy)
        //taxonomy.addGroups(groups)
        print("WE JUST READ \(groups.count) GROUPS")
    }
    return taxonomy
}
