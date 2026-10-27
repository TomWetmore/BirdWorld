//
// main.swift
// BirdTest
//
// Created by Thomas Wetmore on 17 October 2026.
// Last changed on 25 October 2026.
//

import Foundation
import BirdLib

let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
let additionsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/additions.txt")
let groupsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/groups")

func main () {
    do {
        try testOne()
    } catch {
        print("Caught top error: \(error)")
    }
}

func testOne() throws {

    // Create a Taxonomy with my current taxa and group files.
    let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL)

    // Get the BirdRecords from an additions file.
    let records = try readAdditionRecords(from: additionsURL, taxonomy: taxonomy)

    // Show the Records.
    for record in records {
        print("\(record)")
    }
    print("\(records.count)")

}

main()

