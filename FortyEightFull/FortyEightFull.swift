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

        var daysBySpecies: [Taxon: Set<Day>] = [:]  // All Days a Species was seen.

        // Process the taxon-grouped record files.
        var recordCount = 0
        for url in urls {

            print("processing: \(url)")  // DEBUG
            let records = try readTaxonGroupedRecords(from: url, taxonomy: taxonomy)
            recordCount += records.count

            for record in records {
                guard case .species(let taxon) = record.kind,
                      let day = record.range?.midpoint else {
                    continue
                }
                daysBySpecies[taxon, default: []].insert(day)
            }
        }

        // Get the quarter month counts from the full set of records.
        let quarterCounts: [Taxon: [Int]] = quarterMonthCounts(daysBySpecies)

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
