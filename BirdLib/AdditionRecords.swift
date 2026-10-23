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

    /// States the following record loop can be in.
    ///
    enum State {

        case expectingObserver
        case expectingDate(observer: String)
        case readingRecords(observer: String, day: Day)
    }
    var state = State.expectingObserver

    // Loop over all lines in the file.
    //
    while let line = try file.getFields() {

        let fields = line.fields
        let line = line.number

        // All lines must have one or two fields.
        guard fields.count == 1 || fields.count == 2 else {
            throw RecordFileError.invalidLine(line, "Expected one or two fields")
        }
        let key = fields[0]
        let value = fields.count == 2 ? fields[1] : ""

        switch state {

        case .expectingObserver:
            guard key == "o", !value.isEmpty else {
                throw RecordFileError.invalidLine(
                    line, "Expected observer line")
            }
            state = .expectingDate(observer: value)

        case .expectingDate(let observer):
            guard key == "d", let day = Day(value) else {
                throw RecordFileError.invalidLine(
                    line, "Expected valid date line")
            }
            state = .readingRecords(observer: observer, day: day)

        case .readingRecords(let observer, let day):
            if key == "o" {
                guard !value.isEmpty else {
                    throw RecordFileError.invalidLine(
                        line, "Empty observer")
                }
                state = .expectingDate(observer: value)
                continue
            }

            let kind: RecordKind

            if let species = taxonomy.getSpecies(key) {
                kind = .species(species)
            } else if let group = taxonomy.getGroup(key) {
                kind = .group(group)
            } else {
                throw RecordFileError.invalidLine(
                    line, "Unknown bird: \(key)")
            }

            records.append(BirdRecord(
                kind: kind,
                date: day,
                //species: taxon,
                location: location,
                observer: observer,
                notes: value))
        }
    }

    // Detect a file ending immediately after an observer line.
    if case .expectingDate = state {
        throw RecordFileError.invalidLine(
            0, "Missing date at end of file")
    }

    return records
}

public enum RecordFileError: Error {
    case invalidLine(Int, String)
}
