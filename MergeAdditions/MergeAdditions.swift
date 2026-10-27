//
//  MergeAdditions.swift
//  MergeAdditions
//
//  Created by Thomas Wetmore on 27 October 2026.
//  Last changed on 27 October 2026.
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


        // Create a Taxonomy with the current taxa and group files.
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL)

        // Get the BirdRecords from an annual file.
        let records = try readAnnualRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        // Get the BirdRecords from an additions file.
        let additions = try readAdditionRecords(from: additionsURL, taxonomy: taxonomy)
        print("\(additions.count) records were read from an additions file")

        let merged = merge(records, additions)
        print("\(merged.count) records merged from the annual and additions files")

        try writeAnnualRecords(merged, to: testOutURL)
    }
}

func merge(_ annual: [BirdRecord], _ additions: [BirdRecord]) -> [BirdRecord] {

    var records = annual
    records.append(contentsOf: additions)
    sortAnnualRecords(&records)
    return records
}

func sortAnnualRecords(_ records: inout [BirdRecord]) {
    records.sort {
        if $0.kind.order != $1.kind.order {
            return $0.kind.order < $1.kind.order
        }
        return $0.date! < $1.date!
    }
}
