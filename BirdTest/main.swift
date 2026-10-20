//
// main.swift
// BirdTest
//
// Created by Thomas Wetmore on 17 October 2026.
// Last changed on 19 October 2026.
//

import Foundation
import BirdLib

let taxon = Taxon(level: .species, englishName: "Common Loon")
print(taxon)

let url = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
let taxa = try readTaxa(from: url)

print("\(taxa.count)\n")
for taxon in taxa {
    print(taxon)
}

//
let taxonomy = Taxonomy(taxa: taxa)
print("Showing taxonomy\n")
for taxon in taxonomy.roots {
    print(taxon)
    for family in taxon.children {
        print("    \(family)")
    }
}

taxonomy.show(through: .genus)
