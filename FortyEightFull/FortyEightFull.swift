//
//  main.swift
//  FortyEightFull
//
//  Created by Thomas Wetmore on 3 November 2026.
//  Last changed on 13 November 2026.
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

        // Create the Taxonomy using resource files found in the directory defined
        // by the BIRDWORLD_DATA environment variable.
        guard let path = ProcessInfo.processInfo.environment["BIRDWORLD_DATA"] else {
            throw RuntimeError("BIRDWORLD_DATA is not defined")
        }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let taxaURL = directory.appendingPathComponent("taxa.txt")
        let groupsURL = directory.appendingPathComponent("groups.txt")
        let aliasesURL = directory.appendingPathComponent("aliases.txt")
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL, aliasesURL: aliasesURL)

        // Convert the command line arguments into file URLs.
        let urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }
        print("CONVERTED \(urls.count) record files.")  // TODO: DEBUG: REMOVE.

        // There must be at least one URLs for taxon-grouped record files.
        guard urls.count >= 1 else {
            throw ProgramError.argumentCount
        }

        // Process the taxon-grouped record files.
        var allRecords = [BirdRecord]()
        for url in urls {
            print("processing: \(url)")
            var records = try readTaxonGroupedRecords(from: url, taxonomy: taxonomy)

            // Filter out non-species taxa.
            records = records.filter {
                if case .species = $0.kind { return true }
                return false
            }
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

public struct RuntimeError: Error {

    var message: String

    init(_ message: String) {
        self.message = message
    }

}
