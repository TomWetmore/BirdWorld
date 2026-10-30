//
// main.swift
// BirdTest
//
// Created by Thomas Wetmore on 17 October 2026.
// Last changed on 29 October 2026.
//

import Foundation
import BirdLib

let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
let additionsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/additions.txt")
let groupsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/groups")
let abbvsURL = URL(fileURLWithPath: "~/Desktop/BirdWorld/Resources/abbvs.txt")

func main () {
    do {
        //try testOne()
        //try testTwo()
        try testThree()
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

func testTwo() throws {
    let taxonomy = try loadTaxonomy(from: taxaURL)

    let abbvs = try readAbbreviations(from: abbvsURL, taxonomy: taxonomy)

    var count = 1
    for (str, species) in abbvs {

        print("\(count): \(str): \(species.englishName!)")
        count += 1
    }
}

func testThree() throws {
    let taxonomy = try loadTaxonomy(from: taxaURL)
    let abbvs = try readAbbreviations(from: abbvsURL, taxonomy: taxonomy)

    let sorted = abbvs.sorted {
        if $0.value.order! != $1.value.order! {
            return $0.value.order! < $1.value.order!
        }
        return $0.key < $1.key
    }

    for (index, (str, species)) in sorted.enumerated() {
        print("\(index + 1): \(str): \(species.englishName!)")
    }
}

main()

