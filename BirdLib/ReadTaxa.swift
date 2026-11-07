//
//  ReadTaxa.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 17 October 2026.
//  Last changed on 6 November 2026.
//

import Foundation

/// Read Taxa from a DelimitedFile.
///
public func readTaxa(from url: URL) throws -> [Taxon] {

    let file = try DelimitedFile(url)
    var taxa: [Taxon] = []

    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        if let level = Level(rawValue: fields[0]) {

            try requireFieldCount(fields, 2, line: lineNumber)

            taxa.append(Taxon(
                level: level,
                scientificName: fields[1]))

        } else {

            guard fields.count == 3 || fields.count == 4 else {
                throw TaxaFileError.invalidLine(
                    lineNumber,
                    fields.joined(separator: ":"))
            }

            taxa.append(Taxon(
                level: .species,
                code: fields[0],
                englishName: fields[1],
                scientificName: fields[2]))
        }
    }

    return taxa
}

enum TaxaFileError: Error {

    case invalidLine(Int, String)
    case wrongFieldCount(Int, Int, Int)
}

func requireFieldCount(_ fields: [String], _ expected: Int, line: Int) throws {

    guard fields.count == expected else {
        throw TaxaFileError.wrongFieldCount(line, expected, fields.count)
    }
}
