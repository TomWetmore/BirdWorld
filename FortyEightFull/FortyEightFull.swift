//
//  main.swift
//  FortyEightFull
//
//  Created by Thomas Wetmore on 3 November 2026.
//  Last changed on 19 November 2026.
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

        // Create the Taxonomy from resource files.
        guard let path = ProcessInfo.processInfo.environment["BIRDWORLD_DATA"] else {
            throw RuntimeError("BIRDWORLD_DATA is not defined")
        }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let taxaURL = directory.appendingPathComponent("taxa.txt")
        let groupsURL = directory.appendingPathComponent("groups.txt")
        let aliasesURL = directory.appendingPathComponent("aliases.txt")
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL, aliasesURL: aliasesURL)

        // Convert the command line arguments to file URLs.
        let urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }
        guard urls.count >= 1 else {
            throw ProgramError.argumentCount
        }

        var daysBySpecies: [Taxon: Set<Day>] = [:]
        var daysByYearBySpecies: [Year: [Taxon: Set<Day>]] = [:]

        // Process the taxon-grouped record files.
        let clock = ContinuousClock()
        let start = clock.now

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

                let year = day.components.year
                daysByYearBySpecies[year, default: [:]][taxon, default: []].insert(day)
            }
        }
        print("Read \(recordCount) records in \(start.duration(to: clock.now))")


        // Get the quarter month counts from the full set of records.
        let quarterCounts: [Taxon: [Int]] = quarterMonthCounts(daysBySpecies)

        // Get the array of species Taxa with counts in taxonomic order.
        let species = quarterCounts.keys.sorted {
            $0.order! < $1.order!
        }

        // Debug for now: Show the results.
        for taxon in species {
            let counts = quarterCounts[taxon]!
            print("\(taxon.englishName!),\(counts.map(String.init).joined(separator: ","))")
        }

        var countsByYear: [Year: [Taxon: [Int]]] = [:]

        for (year, daysBySpecies) in daysByYearBySpecies {
            countsByYear[year] = quarterMonthCounts(daysBySpecies)
        }

        // Debug for now: show the complete set of quarter counts per year per species.
        let years = countsByYear.keys.min()!...countsByYear.keys.max()!

        for taxon in species {
            print(taxon.englishName!)
            for year in years {
                let counts = countsByYear[year]?[taxon] ?? Array(repeating: 0, count: 48)
                print("\(year),\(counts.map(String.init).joined(separator: ","))")
            }
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
