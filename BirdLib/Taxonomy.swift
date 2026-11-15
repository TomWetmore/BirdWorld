//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 15 November 2026.
//

import Foundation

public final class Taxonomy {

    public let roots: [Taxon]
    public let species: [Taxon]

    /// Create a Taxonomy.
    ///
    public init(taxa: [Taxon]) throws {

        roots = makeTaxonomy(from: taxa)
        roots.assignOrder(at: .species)
        species = roots.species
        try makeIndexes()
    }

    // Stored indexes.
    //
    public private(set) var englishNameIndex: [String : Taxon] = [:]
    public private(set) var scientificNameIndex: [String : Taxon] = [:]
    public private(set) var codeIndex: [String : Taxon] = [:]

    // Fleshed out if BirdGroups are used.
    public private(set) var higherTaxonIndex: [String : Taxon] = [:]

    public private(set) var groups: [SpeciesGroup] = []

    public private(set) var groupCodeIndex: [String: SpeciesGroup] = [:]
    public private(set) var groupNameIndex: [String: SpeciesGroup] = [:]

    public private(set) var aliasIndex: [Alias: Taxon] = [:]
}

/// Create a Taxonomy from an Array of Taxa in depth-first preorder. A Taxonomy is a
/// tree if the first Taxon is the ancestor of all the others; otherwise it is a forest.
/// In both cases the Taxonomy is returned as an Array of roots. If is is a tree the
/// Array has one root.
///
/// Each taxon attaches to the nearest preceding taxon whose level is higher. If no
/// such Taxon exists, it becomes a root. Levels may skip. Roots and siblings keep their
/// input order.
///
/// The input Taxa must be distinct with no parents or children.
///
private func makeTaxonomy(from taxa: [Taxon]) -> [Taxon] {

    assert(
        taxa.allSatisfy { $0.parent == nil && $0.children.isEmpty },
        "makeTaxonomy requires taxa with no parent or children."
    )
    assert(
        Set(taxa.map { ObjectIdentifier($0) }).count == taxa.count,
        "makeTaxonomy requires distinct Taxon instances."
    )

    var roots: [Taxon] = []  // The forest of roots.
    var path: [Taxon] = []  // The current path from a root to the last Taxon.

    for taxon in taxa {

        // Remove taxa from the path that cannot be the parent of this Taxon.
        while let last = path.last,
              last.level.depth >= taxon.level.depth {
            path.removeLast()
        }

        // If the path is not empty, its last Taxon is the parent of this Taxon.
        if let parent = path.last {
            parent.children.append(taxon)
            taxon.parent = parent
        // Otherwise this Taxon is a new root Taxon.
        } else {
            roots.append(taxon)
        }

        path.append(taxon)
    }

    return roots
}

/// Taxonomy indexing.
///
extension Taxonomy {

    /// Make the Taxonomy's indexes.
    ///
    private func makeIndexes() throws {

        /// Insert an entry into one of the indexes.
        func insert(_ value: String?, into index: inout [String: Taxon],
            for taxon: Taxon, field: String) throws {

            guard let value else {
                return
            }
            // Add the value to the index (not checking for uniqueness).
            index[value] = taxon
        }

        // Index the species on the code and names.
        for species in self.species {

            try insert(species.code, into: &codeIndex, for: species,
                field: "species code")
            try insert(species.englishName, into: &englishNameIndex, for: species,
                field: "English name")
            try insert(species.scientificName, into: &scientificNameIndex, for: species,
                field: "scientific name")
        }

        // Index higher level taxa -- for now only index the scientific name.
        try roots.traverse { taxon in
            guard taxon.level.depth < Level.species.depth else { // Taxa above species.
                return
            }
            try insert(taxon.scientificName, into: &higherTaxonIndex,
                       for: taxon, field: "scientific name")
        }
    }
}

/// Lookup methods.
///
extension Taxonomy {

    /// Look up a species Taxon using four indexes.
    ///
    public func getSpecies(_ string: String) -> Taxon? {

        codeIndex[string]
            ?? englishNameIndex[string]
            ?? scientificNameIndex[string]
            ?? aliasIndex[prepareName(string)]
    }

    /// Look up a BirdGroup using the code and name indices.
    ///
    func getGroup(_ string: String) -> SpeciesGroup? {

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

    /// Add TaxonGroups to this Taxonomy and build their indexes.
    ///
    func addGroups(_ groups: [SpeciesGroup]) throws {

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
