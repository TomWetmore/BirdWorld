//
//  AnnualRecords.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 22 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

/// Read an annual records file.
///
public func readAnnualRecords(from url: URL, taxonomy: Taxonomy) throws -> [BirdRecord] {

    let file = try DelimitedFile(url)
    var records: [BirdRecord] = []
    var currentKind: RecordKind? = nil

    // Loop over the lines.
    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        // Lines have one or three fields.
        guard fields.count == 1 || fields.count == 3 else {
            throw RecordFileError.invalidLine(lineNumber, "Wrong number of fiedls")
        }

        // Handle a species or group name line.
        if fields.count == 1 {

            let key = fields[0]
            if let species = taxonomy.getSpecies(key) {
                currentKind = .species(species)
            } else if let group = taxonomy.getGroup(key) {
                currentKind = .group(group)
            } else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Unknown bird: \(key)")
            }
        // Handle a sightings line.
        } else {
            guard let currentKind else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Sighting before species heading")
            }
            let dateString = fields[0]
            let notes = fields[1]
            let observer = fields[2]

            guard let date = Day(dateString) else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Invalid date: \(dateString)")
            }
            let record = BirdRecord(kind: currentKind, date: date,
                                    location: "Plum Island", observer: observer,
                                    notes: notes)
            records.append(record)
        }
    }
    return records
}

public func writeAnnualRecords(_ records: [BirdRecord], to url: URL) throws {

    var output = ""
    var previousOrder: Int?

    for record in records {

        // Start a new species/group section.
        if record.kind.order != previousOrder {
            if previousOrder != nil {
                output += "\n"
            }

            output += "\(record.kind.name)\n"
            previousOrder = record.kind.order
        }

        // Write the observation.
        output += "\(record.annualLine)\n"
    }

    try output.write(to: url, atomically: true, encoding: .utf8)
}
