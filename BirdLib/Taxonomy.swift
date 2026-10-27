//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 26 October 2026.
//

import Foundation

public final class Taxonomy {

    public let roots: [Taxon]
    public let species: [Taxon]

    public init(taxa: [Taxon]/*, useGroups: Bool = false*/) throws {

        roots = makeTaxonomy(from: taxa)
        roots.assignOrder(at: .species)
        species = roots.species
        try makeIndexes(SpeciesRequirements())
    }

    // Stored indexes.
    //
    public private(set) var englishNameIndex: [String : Taxon] = [:]
    public private(set) var scientificNameIndex: [String : Taxon] = [:]
    public private(set) var codeIndex: [String : Taxon] = [:]
    public private(set) var bandingCodeIndex: [String : Taxon] = [:]

    // Fleshed out if BirdGroups are used.
    public private(set) var higherTaxonIndex: [String : Taxon] = [:]

    public private(set) var groups: [BirdGroup] = []

    public private(set) var groupCodeIndex: [String: BirdGroup] = [:]
    public private(set) var groupNameIndex: [String: BirdGroup] = [:]

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

    /// Makes the Taxonomy's indexes.
    ///
    private func makeIndexes(_ requirements: SpeciesRequirements) throws {

        /// Internal function that adds an entry to an index.
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
        // Index the species on the two codes and the two names.
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

        // Index the higher level taxa. For now only index the scientific name.
        try roots.traverse { taxon in
            guard taxon.level.depth < Level.species.depth else { // Taxa above species.
                return
            }
            try insert(taxon.scientificName, into: &higherTaxonIndex,
                       for: taxon, field: "scientific name", requirement: .canbe)
        }
    }
}

/// Lookup methods.
///
extension Taxonomy {

    /// Lookup a Species Taxon using three indexes.
    /// May add the banding code index later.
    func getSpecies(_ string: String) -> Taxon? {

        codeIndex[string]
            ?? englishNameIndex[string]
            ?? scientificNameIndex[string]
    }

    /// Lookup a BirdGroup using the code and name indices.
    ///
    func getGroup(_ string: String) -> BirdGroup? {

        groupCodeIndex[string] ?? groupNameIndex[string]
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

extension Taxonomy {

    /// Add BirdGroups to this Taxonomy and build their indexes.
    ///
    func addGroups(_ groups: [BirdGroup]) throws {

        for group in groups {
            guard groupCodeIndex[group.code] == nil else {
                throw RecordFileError.invalidLine(
                    0, "Duplicate bird group code: \(group.code)")
            }

            guard groupNameIndex[group.name] == nil else {
                throw RecordFileError.invalidLine(
                    0, "Duplicate bird group name: \(group.name)")
            }

            groupCodeIndex[group.code] = group
            groupNameIndex[group.name] = group
        }

        self.groups = groups
    }
}

/// Load a Taxonomy from a taxa file. If a group file is provided also load the
/// BirdGroups.
///
public func loadTaxonomy(from taxaURL: URL, groupsURL: URL? = nil) throws -> Taxonomy {

    // Read the Taxa file and create the Taxonomy.
    let taxa: [Taxon] = try readTaxa(from: taxaURL)
    let taxonomy = try Taxonomy(taxa: taxa)

    // If there is a group file read the groups and add them to the Taxonomy.
    if let groupsURL {
        let groups = try readGroups(url: groupsURL, taxonomy: taxonomy)
        try taxonomy.addGroups(groups)
    }

    return taxonomy
}
