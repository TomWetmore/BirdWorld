//
//  main.swift
//  FortyEightFull
//
//  Created by Thomas Wetmore on 11/3/26.
//  Last changed on 3 November 2026.
//

import Foundation
import BirdLib

@main
struct FortyEightFull {

    static func main() throws {

        // Convert command line arguments into file URLs.
        var urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }
        guard !urls.isEmpty else {
            throw ProgramError.missingTaxonomyURL
        }

        // Try to load a Taxonomy from the first URL.
        let taxaURL = urls.removeFirst()
        let taxonomy = try loadTaxonomy(from: taxaURL)

        // The remaining URLs should be taxon-grouped files.
        var allRecords = [BirdRecord]()
        for url in urls {
            let records = try readTaxonGroupedRecords(from: url, taxonomy: taxonomy)
            try allRecords.merge(records)
        }

        // Generate the HTML report.
    }
}

public enum ProgramError: Error {

    case missingTaxonomyURL
}
