//
//  BirdGroup.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 23 October 2026.
//  Last changed on 24 October 2026.
//

import Foundation

final public class BirdGroup {

    let code: String  // Four letter wetmore code.
    let name: String  // Display name.
    let taxa: [Taxon]  // Taxa making it up.
    let order: Int  // "Order" of last species in the group.

    public init(code: String, name: String, taxa: [Taxon], order: Int) {

        self.code = code
        self.name = name
        self.taxa = taxa
        self.order = order
    }
}

extension BirdGroup {

    var description: String {
        return "\(code) \(name)"
    }
}

/// Read a file with group information and return an array of BirdGroups.
///
func readGroups(url: URL, taxonomy: Taxonomy) throws -> [BirdGroup] {

    let file = try DelimitedFile(url)
    var groups: [BirdGroup] = []

    // Loop over all lines in the file.
    while let line = try file.getFields() {

        let fields = line.fields
        let line = line.number

        // All lines have three fields.
        guard fields.count == 3 else {
            throw RecordFileError.invalidLine(line, "Group file: expected three fields")
        }

        let key = fields[0]
        let name = fields[1]
        let contents = fields[2]

        // Split contents into parts; each part refers to a single taxon.
        let parts = contents.split {
            $0.isWhitespace || $0 == ","
        }.map(String.init)

        // Look up each taxon.
        var taxa: [Taxon] = []
        // For each
        for part in parts {
            guard let taxon = taxonomy.getSpecies(part)
                    ?? taxonomy.higherTaxonIndex[part] else {
                throw RecordFileError.invalidLine(
                    line, "Unknown taxon in group: \(part)")
            }
            taxa.append(taxon)
        }

        // Get the species in the taxons, making sure there are some.
        let species = taxa.species
        guard !species.isEmpty else {
            throw RecordFileError.invalidLine(line, "Empty bird group: \(key)")
        }
        // Make sure all species have an order and find the highest order.
        guard species.allSatisfy({ $0.order != nil }),
            let order = species.compactMap(\.order).max() else {
            throw RecordFileError.invalidLine(line, "Missing order number in bird group: \(key)")
        }
        let group = BirdGroup(code: key, name: name, taxa: taxa, order: order)
        groups.append(group)
    }
    return groups
}
