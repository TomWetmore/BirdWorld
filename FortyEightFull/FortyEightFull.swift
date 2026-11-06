//
//  main.swift
//  FortyEightFull
//
//  Created by Thomas Wetmore on 11/3/26.
//  Last changed on 5 November 2026.
//

import Foundation
import BirdLib

@main
struct FortyEightFull {

    static func main() {

        do {
            try doit()
        }
        catch {
            print("Caught Error: \(error)")
        }
    }

    static func doit() throws {

        // Convert the command line arguments into file URLs.
        var urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }

        // There must be at least four URLs for the taxa, groups, and aliases.
        guard urls.count > 3 else {
            throw ProgramError.argumentCount
        }
        guard !urls.isEmpty else {
            throw ProgramError.missingTaxonomyURL
        }

        // Load a Taxonomy from the first three URLs.
        let taxaURL = urls.removeFirst()
        let groupsURL = urls.removeFirst()
        let aliasesURL = urls.removeFirst()
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL,
                                        aliasesURL: aliasesURL)

        // The remaining URLs should be taxon-grouped files.
        var allRecords = [BirdRecord]()
        for url in urls {
            let records = try readTaxonGroupedRecords(from: url, taxonomy: taxonomy)
            try allRecords.merge(records)
        }
        print("\(allRecords.count)")

        // Get the quarter month counts from the full set of records.
        let quarterCounts: [Taxon: [Int]] = quarterMonthCounts(allRecords)

        // Get the array of species with counts in taxonomic order.
        let species = quarterCounts.keys.sorted {
            $0.order! < $1.order!
        }

        // Debug for now: Show the results.
        for taxon in species {
            let counts = quarterCounts[taxon]!
            print("\(taxon.englishName!),\(counts.map(String.init).joined(separator: ","))")
        }

        // Generate the HTML report.
    }
}

