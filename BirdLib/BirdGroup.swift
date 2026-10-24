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
func readBirdGroups(url: URL, taxonomy: Taxonomy) throws -> [BirdGroup] {

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

        // Split contents into fields.
        let codes = contents.split(whereSeparator: \.isWhitespace).map(String.init)

        // Look up each species.
        var species: [Taxon] = []

        for code in codes {
            guard let taxon = taxonomy.getSpecies(code) else {
                throw RecordFileError.invalidLine(
                    line, "Unknown species in group: \(code)")
            }
            species.append(taxon)
        }

        // Find the highest order number.
        guard !species.isEmpty else {
            throw RecordFileError.invalidLine(
                line, "Empty bird group: \(key)")
        }
        guard let order = species.compactMap(\.order).max(),
              species.allSatisfy({ $0.order != nil }) else {
            throw RecordFileError.invalidLine(
                line, "Missing order number in bird group: \(key)")
        }
        let group = BirdGroup(code: key, name: name, taxa: species, order: order)
        groups.append(group)
    }
    return groups
}
