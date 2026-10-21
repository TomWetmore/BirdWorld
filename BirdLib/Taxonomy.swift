//
//  Taxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 18 October 2026.
//  Last changed on 29 October 2026.
//

import Foundation

public final class Taxonomy {

    public let roots: [Taxon]
    public let species: [Taxon]

    public init(taxa: [Taxon]) throws {
        roots = makeTaxonomy(from: taxa)
        species = roots.species
        try makeIndexes()
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

    var species: [Taxon] {

        var result: [Taxon] = []

        func visit(_ taxon: Taxon) {
            if taxon.level == .species {
                result.append(taxon)
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
}

/// Taxonomy indexing.
///
extension Taxonomy {

    private func makeIndexes() throws {

        for species in self.species {
            guard let code = species.code else {
                throw TaxaFileError.invalidLine(0, "species mising wetmore four letter code")
            }
            codeIndex[code] = species
            guard let name = species.englishName else {
                throw TaxaFileError.invalidLine(0, "species missing English name")
            }
            englishNameIndex[name] = species
            guard let name = species.scientificName else {
                throw TaxaFileError.invalidLine(0, "species missing scientific name")
            }
            scientificNameIndex[name] = species
            if let bandingCode = species.bandingCode {
                bandingCodeIndex[bandingCode] = species
            }
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


/// Display methods.
extension Taxonomy {

    public func show(through level: TaxonLevel) {
        for root in roots {
            root.show(through: level)
        }
    }
}
