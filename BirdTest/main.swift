//
// main.swift
// BirdTest
//
// Created by Thomas Wetmore on 17 October 2026.
// Last changed on 22 October 2026.
//

import Foundation
import BirdLib

func main () {
    do {
        print("HELLO, GOT HERE")
        try quickTest()
    } catch {
        print("Caught top error: \(error)")
    }
}

let taxaURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
let additionsURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/additions.txt")

let taxa = try readTaxa(from: taxaURL)
print("READ THE TAXA")

let taxonomy = try Taxonomy(taxa: taxa)
print("GOT THE TAXONOMY IN LINE")

func quickTest() throws {

    // Get the Taxa for this test.
    let newTaxa = try readTaxa(from: taxaURL)

    // Get the Taxonomy for this text.
    let taxonomy = try Taxonomy(taxa: newTaxa)
    print("GOT THE TAXONOMY IN THE MAIN FUNCTION")

    // Get the BirdRecords from an additions file.
    let records = try readAdditionRecords(from: additionsURL, taxonomy: taxonomy)

    // Show the Records.
    for record in records {
        print("\(record)")
    }
    print("\(records.count)")

    // 2. Open Quick file from an additions file.
    // 3. Run the loop.
    // 4. Check the results
}

main()

