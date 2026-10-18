//
// main.swift
// BirdTest
//
// Created by Thomas Wetmore on 17 October 2026.
// Last changed on 18 October 2026.
//

import Foundation
import BirdLib

let taxon = Taxon(level: TaxonLevel(rawValue: "species") ?? .species, englishName: "Common Loon")
print(taxon)

let url = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/taxa")
let taxa = try readTaxa(from: url)

print("\(taxa.count)\n")
for taxon in taxa {
    print(taxon)
}
