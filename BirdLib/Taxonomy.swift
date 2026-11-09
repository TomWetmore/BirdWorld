//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 7 November 2026.
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

    // Fleshed out if BirdGroups are used.
    public private(set) var higherTaxonIndex: [String : Taxon] = [:]

    public private(set) var groups: [BirdGroup] = []

    public private(set) var groupCodeIndex: [String: BirdGroup] = [:]
    public private(set) var groupNameIndex: [String: BirdGroup] = [:]

    public private(set) var aliasIndex: [Alias: Taxon] = [:]
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

    /// Make the Taxonomy's indexes.
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
//            guard index[value] == nil else {
//                throw TaxaFileError.invalidLine(0, "duplicate \(field): \(value)")
//            }
            // Add the field to its index.
            index[value] = species
        }
        // Index the species on the code and the two names.
        for species in self.species {

            try insert(species.code, into: &codeIndex, for: species,
                field: "four letter code", requirement: requirements.code)
            try insert(species.englishName, into: &englishNameIndex, for: species,
                field: "English name", requirement: requirements.englishName)
            try insert(species.scientificName, into: &scientificNameIndex, for: species,
                field: "scientific name", requirement: requirements.scientificName)
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

    /// Look up a species Taxon using three indexes.
    ///
    public func getSpecies(_ string: String) -> Taxon? {
        codeIndex[string]
            ?? englishNameIndex[string]
            ?? scientificNameIndex[string]
            ?? aliasIndex[prepareName(string)]
    }

    /// Look up a BirdGroup using the code and name indices.
    ///
    func getGroup(_ string: String) -> BirdGroup? {

        groupCodeIndex[string] ?? groupNameIndex[string]
    }
}

/// Display methods.
///
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

///
///
extension Taxonomy {

    /// Load Aliases from an aliases DelimitedFile.
    ///
    fileprivate func loadAliases(from url: URL) throws {

        aliasIndex = try readAliases(from: url, taxonomy: self)
    }
}

/// Load a Taxonomy from a taxa file, and optionally from a groups and/or aliases file.
///
public func loadTaxonomy(from taxaURL: URL, groupsURL: URL? = nil, aliasesURL: URL? = nil)
        throws -> Taxonomy {

    let taxa = try readTaxa(from: taxaURL)
    let taxonomy = try Taxonomy(taxa: taxa)

    if let aliasesURL {
        try taxonomy.loadAliases(from: aliasesURL)
    }

    if let groupsURL {
        let groups = try readGroups(url: groupsURL, taxonomy: taxonomy)
        try taxonomy.addGroups(groups)
    }

    return taxonomy
}

/// Piggy-back Array<Taxon> methods.
///
extension Taxonomy {

    public func assignOrder(at level: Level) {

        roots.assignOrder(at: level)
    }

    /// Visit every taxon in preorder and perform a function.
    ///
    func traverse(_ action: (Taxon) throws -> Void) rethrows {

        for taxon in roots {
            try action(taxon)
            try taxon.children.traverse(action)
        }
    }

}
