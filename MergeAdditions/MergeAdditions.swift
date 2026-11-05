//
//  MergeAdditions.swift
//  MergeAdditions
//
//  Created by Thomas Wetmore on 27 October 2026.
//  Last changed on 4 November 2026.
//

import Foundation
import BirdLib

@main
struct MergeAnnual {

    static let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
    static let additionsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/additions.txt")
    static let groupsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/groups")
    static let sightingsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/pisightings2020.txt")
    static let testOutURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/testout.txt")

    static func main() throws {

        // Create a Taxonomy from a taxa and group file.
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL)

        // Get the BirdRecords from a species grouped file.
        var records = try readTaxonGroupedRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        // Get the BirdRecords from an observer grouped file, an "additions" file.
        let additions = try readObserverGroupedRecords(from: additionsURL, taxonomy: taxonomy)
        print("\(additions.count) records were read from an additions file")

        // Merge the BirdRecords from the two files.
        try records.merge(additions)
        print("\(records.count) records merged from the annual and additions files")

        // Write the BirdRecords as a merged species grouped file.
        try writeAnnualRecords(records, to: testOutURL)
    }
}
