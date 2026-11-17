//
//  SpeciesGroup.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 23 October 2026.
//  Last changed on 17 November 2026.
//

import Foundation

/// A SpeciesGroup is an arbitrary group of species. Each group has an index code, and a
/// display name used in outputs. Each SpeciesGroup is defined by an Array of Strings
/// that define its species. The Strings can be species codes or species, names, or the
/// names of higher level taxa. The Strings are resolved into a list of Taxa when a
/// definition is read.
///
final public class SpeciesGroup: CustomStringConvertible {

    let code: String   // Four letter code.
    let name: String   // Display name.
    let taxa: [Taxon]  // Taxa content.
    let order: Int     // Order of last species in the group.

    /// Create a SpeciesGroup from its components.
    ///
    public init(code: String, name: String, taxa: [Taxon], order: Int) {

        self.code = code
        self.name = name
        self.taxa = taxa
        self.order = order
    }

    /// Return a description of this SpeciesGroup.
    ///
    public var description: String {

        return "\(code) \(name)"
    }
}

/// Read a DelimitedFile with group information and return an array of SpeciesGroups. Each
/// line in the file has three fields. The first is the group code and the second is its
/// display name. The third is a list of codes and names that specify the species in the
/// group.
///
func readGroups(url: URL, taxonomy: Taxonomy) throws -> [SpeciesGroup] {

    let file = try DelimitedFile(url)
    var groups: [SpeciesGroup] = []

    // Iterate over the lines.
    while let line = try file.getFields() {

        let fields = line.fields
        let line = line.number

        // Lines must have three fields.
        guard fields.count == 3 else {
            throw RecordFileError.invalidLine(line, "Group file: expected three fields")
        }

        let key = fields[0]
        let name = fields[1]
        let contents = fields[2]

        // Split contents into parts; each part refers to a Taxon.
        let parts = contents.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        //let parts = contents.split {$0.isWhitespace || $0 == ","}.map(String.init)

        // The Taxa (species or higher level) making up this SpeciesGroup.
        var taxa: [Taxon] = []

        // Each part should either be a species identified by code or name, or by a
        // higher level Taxon identified by name.
        for part in parts {

            guard let taxon = taxonomy.getSpecies(part)
                    ?? taxonomy.higherTaxonIndex[part] else {
                throw RecordFileError.invalidLine(
                    line, "Unknown taxon in group: \(part)")
            }
            taxa.append(taxon)
        }

        // Get the species in the taxons, making sure there are some. The species are not
        // retained in the SpeciesGroup. They are used to find the order of the group.
        let species = taxa.species
        guard !species.isEmpty else {
            throw RecordFileError.invalidLine(line, "Empty bird group: \(key)")
        }
        // Make sure all species have an order and find the highest order.
        guard species.allSatisfy({ $0.order != nil }),
            let order = species.compactMap(\.order).max() else {
            throw RecordFileError.invalidLine(line, "Missing order number in bird group: \(key)")
        }
        let group = SpeciesGroup(code: key, name: name, taxa: taxa, order: order)
        groups.append(group)
    }
    return groups
}
