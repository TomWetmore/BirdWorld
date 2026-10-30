//
//  main.swift
//  FortyEight
//
//  Created by Thomas Wetmore on 27 October 2026.
//  Last changed on 28 October 2026.
//

import Foundation
import BirdLib

@main
struct FortyEight {

    static let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
    static let groupsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/groups")
    static let sightingsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/pisightings2026.txt")
    static let testOutURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/testout.txt")
    static let htmlBase = "/Users/ttw4/Desktop/BirdWorld/Resources/HTML/FortyEight/"
    static let headerURL = URL(fileURLWithPath: htmlBase + "header.html")
    static var totalReports: Int = 0

    static func main() throws {

        // Create a Taxonomy with the current taxa (not using groups).
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL)

        // Get the BirdRecords from an annual file.
        var records = try readAnnualRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        totalReports = records.count {
            if case .species = $0.kind { return true }
            return false
        }

        // Filter out the BirdGroups becuase we don't count in this report.
        records = records.filter {
            if case .species = $0.kind { return true }
            return false
        }

        // Get the quarter-month counts for the BirdRecords.
        let countsBySpecies = quarterMonthCounts(records)

        // Get the array of species with counts in taxonomic order.
        let species = countsBySpecies.keys.sorted {
            $0.order! < $1.order!
        }

        let html = try generateHTML(species: species, records: records, counts: countsBySpecies)
        print(html)

        // Debug for now: Show the results.
//        for taxon in species {
//            let counts = countsBySpecies[taxon]!
//            print("\(taxon.englishName!),\(counts.map(String.init).joined(separator: ","))")
//        }
    }
}
