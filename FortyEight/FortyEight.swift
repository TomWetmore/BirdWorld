//
//  main.swift
//  FortyEight
//
//  Created by Thomas Wetmore on 27 October 2026.
//  Last changed on 11 November 2026.
//

import Foundation
import BirdLib

@main
struct FortyEight {

    static let htmlBase = "/Users/ttw4/Desktop/BirdWorld/Resources/HTML/FortyEight/"
    static let headerURL = URL(fileURLWithPath: htmlBase + "header.html")
    static var totalReports: Int = 0

    static func main() throws {

        // Create the Taxonomy using resource files from the BIRDWORLD_DATA directory.
        guard let path = ProcessInfo.processInfo.environment["BIRDWORLD_DATA"] else {
            throw RuntimeError("BIRDWORLD_DATA is not defined")
        }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let taxaURL = directory.appendingPathComponent("taxa.txt")
        let groupsURL = directory.appendingPathComponent("groups.txt")
        let aliasesURL = directory.appendingPathComponent("aliases.txt")
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL,
                                        aliasesURL: aliasesURL)

        // Convert the command line argument to a file URL, and read a taxon-grouped file.
        var urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }
        let sightingsURL = urls.removeFirst()

        // Get the BirdRecords from a taxon-grouped file.
        var records = try readTaxonGroupedRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        // Filter out non-species taxa.
        records = records.filter {
            if case .species = $0.kind { return true }
            return false
        }

        // Get the quarter-month counts for the BirdRecords.
        let countsBySpecies = quarterMonthCounts(records)

        // Get the species in an array in taxonomic order.
        let species: [Taxon] = countsBySpecies.keys.sorted {
            $0.order! < $1.order!
        }

        // Generate an HTML page with the data.
        let html = try generateHTML(species: species, records: records,
                                    counts: countsBySpecies)
        print(html)

        // Debug for now: Show the results.
//        for taxon in species {
//            let counts = countsBySpecies[taxon]!
//            print("\(taxon.englishName!),\(counts.map(String.init).joined(separator: ","))")
//        }
    }
}

public struct RuntimeError: Error {

    var message: String

    init(_ message: String) {
        self.message = message
    }

}
