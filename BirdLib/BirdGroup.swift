//
//  BirdGroup.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 23 October 2026.
//  Last changed on 23 October 2026.
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

func readBirdGroups(url: URL, taxonomy: Taxonomy) throws {

    let file = try DelimitedFile(url)
    var groups: [BirdGroup] = []

    // Loop over all lines in the file.
    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        // All lines must have three fields.
        guard fields.count == 3 else {
            throw RecordFileError.invalidLine(
                lineNumber, "Group file: expected three fields")
        }

        let key = fields[0]
        let name = fields[1]
        let contents = fields[2]

        // Split the contents into individual species codes.
        let codes = contents.split(whereSeparator: \.isWhitespace).map(String.init)

        // Look up each species.
        var species: [Taxon] = []

        for code in codes {
            guard let taxon = taxonomy.getSpecies(code) else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Unknown species in group: \(code)")
            }
            species.append(taxon)
        }

        // Find the highest order number.
        guard let lastSpecies = species.max(by: { $0.order < $1.order }) else {
            throw RecordFileError.invalidLine(
                lineNumber, "Empty bird group: \(key)")
        }

        let order = lastSpecies.order

        // Construct the BirdGroup here.
        // groups.append(BirdGroup(...))
    }
}
