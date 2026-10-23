//
//  AnnualRecords.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 22 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

import Foundation

public func readAnnualRecords(from url: URL, taxonomy: Taxonomy) throws -> [BirdRecord] {

    let file = try DelimitedFile(url)
    var records: [BirdRecord] = []
    var currentKind: RecordKind? = nil

    // Loop over all lines in the file.
    //
    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        // Determine whether this is a heading or a sighting.
        if isHeading(fields) {

            let key = fields[0]

            if let species = taxonomy.getSpecies(key) {
                currentKind = .species(species)
            } else if let group = taxonomy.getGroup(key) {
                currentKind = .group(group)
            } else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Unknown bird: \(key)")
            }

        } else {

            // A sighting must follow a species or group heading.
            guard let kind = currentKind else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Sighting before species heading")
            }

            // Parse date, notes, and observer from fields.
            // Construct BirdRecord(kind: kind, ...)
            // Append to records.
        }
    }

    return records
}
