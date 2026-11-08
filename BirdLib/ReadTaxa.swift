//
//  ReadTaxa.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 17 October 2026.
//  Last changed on 7 November 2026.
//

import Foundation

/// A Taxa File holds a Taxonomy in text format. Each line has two or three fields. The
/// first field for a species line is a four letter code for that species; for all other
/// lines it is a string that names the level of the Taxon (eg., class, order, family).
/// Species lines have two more fields, the English and scientific names. All other lines
/// have one field that it the scientific name of the Taxon. TODO: Consider adding English
/// names to all Taxa.

/// Read Taxa from a DelimitedFile.
///
public func readTaxa(from url: URL) throws -> [Taxon] {

    let file = try DelimitedFile(url)
    var taxa: [Taxon] = []

    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

        if let level = Level(rawValue: fields[0]) {  // If it fails it is a Species.
            try requireFieldCount(fields, 2, line: lineNumber)
            taxa.append(Taxon(level: level, scientificName: fields[1]))

        } else {
            guard fields.count == 3 else {
                throw TaxaFileError.invalidLine(lineNumber, fields.joined(separator: ":"))
            }
            taxa.append(Taxon(level: .species, code: fields[0], englishName: fields[1],
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
