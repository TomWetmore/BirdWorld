//
//  main.swift
//  FortyEight
//
//  Created by Thomas Wetmore on 10/27/26.
//  Last changed on 27 October 2026.
//

import Foundation
import BirdLib

@main
struct FortyEight {

    static let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
    static let additionsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/additions.txt")
    static let groupsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/groups")
    static let sightingsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/pisightings2020.txt")
    static let testOutURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/testout.txt")

    static func main() throws {

        // Create a Taxonomy with the current taxa (not using groups).
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL)

        // Get the BirdRecords from an annual file.
        let records = try readAnnualRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        // Create a map from a Taxon to the days on which it was seen.
        var daysBySpecies: [Taxon: Set<Day>] = [:]

        for record in records {
            guard case .species(let taxon) = record.kind,
                  let day = record.date else {
                continue
            }
            daysBySpecies[taxon, default: []].insert(day)
        }

        // Create a map from a Taxon the arry of its quarter-monthly counts.
        var countsBySpecies: [Taxon: [Int]] = [:]

        for (species, days) in daysBySpecies {
            var counts = Array(repeating: 0, count: 48)
            for day in days {
                counts[day.quarterMonthIndex] += 1
            }
            countsBySpecies[species] = counts
        }

        let species = countsBySpecies.keys.sorted {
            $0.order! < $1.order!
        }

        for taxon in species {
            let counts = countsBySpecies[taxon]!
            print("\(taxon.englishName!),\(counts.map(String.init).joined(separator: ","))")
        }

        // Debug -- show the contents of countsBySpecies
//        print("\(countsBySpecies.count)")
//        for (species, counts) in countsBySpecies {
//            print("\(species.englishName!)", terminator: "")
//            for i in 0...47 {
//                print(",\(counts[i])", terminator: "")
//            }
//            print()
//        }
    }
}
