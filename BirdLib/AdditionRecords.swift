//
//  QuickRecords.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 22 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

/// Read an additions observation file. Each section begins with an observer line,
/// followed by a date line, followed by zero or more bird observation lines.
///
public func readAdditionRecords(from url: URL, taxonomy: Taxonomy) throws -> [BirdRecord] {

    let file = try DelimitedFile(url)
    var records: [BirdRecord] = []
    let location = "Plum Island"

    var observer: String?
    var day: Day?

    enum State {
        case expectingObserver
        case expectingDate
        case readingRecords
    }

    var state = State.expectingObserver

    // Loop over all lines in the file.
    //
    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        // All lines have one or two fields.
        guard fields.count == 1 || fields.count == 2 else {
            throw RecordFileError.invalidLine(
                lineNumber, "Expected one or two fields")
        }
        let key = fields[0]
        let value = fields.count == 2 ? fields[1] : ""

        switch state {

        case .expectingObserver:

            guard key == "o", !value.isEmpty else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Expected observer line")
            }
            observer = value
            state = .expectingDate

        case .expectingDate:

            guard key == "d", let parsedDay = Day(value) else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Expected valid date line")
            }

            day = parsedDay
            state = .readingRecords

        case .readingRecords:

            // A new observer starts another section.
            if key == "o" {
                guard !value.isEmpty else {
                    throw RecordFileError.invalidLine(
                        lineNumber, "Empty observer")
                }

                observer = value
                day = nil
                state = .expectingDate
                continue
            }

            // Otherwise, this must be a bird observation.
            guard let taxon = taxonomy.getSpecies(key) else {
                throw RecordFileError.invalidLine(
                    lineNumber, "Unknown bird: \(key)")
            }

            /*
             init(date: Date? = nil, species: Taxon, location: String? = nil,
                  observer: String? = nil, notes: String? = nil) {
             */

            records.append(BirdRecord(date: day!, species: taxon, location: location,
                                      observer: observer, notes: value))
        }
    }

    // Detect a file ending immediately after an observer line.
    if state == .expectingDate {
        throw RecordFileError.invalidLine(
            0, "Missing date at end of file")
    }

    return records
}

public enum RecordFileError: Error {
    case invalidLine(Int, String)
}
