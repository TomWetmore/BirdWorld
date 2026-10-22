//
//  AnnualRecords.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 22 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

public func readAnnualRecords(from url: URL, taxonomy: Taxonomy) throws -> [BirdRecord] {

    let file = try DelimitedFile(url)
    var records: [BirdRecord] = []

    enum State {
        case expectingSpecies
        case readingRecords(species: Taxon)
    }

    var state = State.expectingSpecies

    // Loop over all lines in the file.
    //
    while let line = try file.getFields() {

        let fields = line.fields
        let lineNumber = line.number

    }

    return []

}
