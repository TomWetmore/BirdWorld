//
//  TaxonArray.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 24 October 2026.
//  Last changed on 7 November 2026.
//
//  A Taxonomy is primarily an Array<Taxon>, and it is useful to extend
//  Array<Taxon> in some contexts.

import Foundation

extension Array<Taxon> {

    /// Return the species Taxa that are at or below a Taxon in an Array<Taxon>.
    ///
    public var species: [Taxon] {

        return taxa(of: .species)
    }

    /// Return the genera Taxa that are at or below a Taxon in an Array<Taxon>.
    ///
    public var genera: [Taxon] {

        return taxa(of: .genus)
    }

    /// Return the family Taxa that are at or below a Taxon in an Array<Taxon>.
    ///
    public var families: [Taxon] {

        return taxa(of: .family)
    }

    /// Return all Taxa of a specific level that are at or below the Taxa in an Array<Taxon>.
    ///
    func taxa(of level: Level) -> [Taxon] {

        var result: [Taxon] = []

        // Internal visit funtion.
        func visit(_ taxon: Taxon) {

            if taxon.level == level {
                result.append(taxon)
                return
            }
            guard taxon.level.depth < level.depth else {
                return
            }
            for child in taxon.children {
                visit(child)
            }
        }

        // Traverse self by visiting each of its root Taxa.
        for taxon in self {
            visit(taxon)
        }
        return result
    }

    /// Show the forest of Taxa through to the specified level.
    ///
    public func show(through level: Level, indent: Int = 0) {
        for taxon in self {
            taxon.show(through: level, indent: indent)
        }
    }

    /// Assign sequential order numbers to all taxa at a specified level.
    ///
    public func assignOrder(at level: Level) {
        for (index, taxon) in taxa(of: level).enumerated() {
            taxon.order = index + 1
        }
    }
}

extension Array<Taxon> {

    /// Visit every taxon in preorder and perform a function.
    ///
    func traverse(_ action: (Taxon) throws -> Void) rethrows {

        for taxon in self {
            try action(taxon)
            try taxon.children.traverse(action)
        }
    }
}
