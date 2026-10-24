//
//  TaxonArray.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 24 October 2026.
//  Last changed on 24 October 2026.
//

import Foundation

extension Array<Taxon> {

    /// Return the species at or below a Taxon in an Array<Taxon>.
    ///
    public var species: [Taxon] {

        return taxa(of: .species)
    }

    /// Return the genera at or below a Taxon in an Array<Taxon>.
    ///
    public var genera: [Taxon] {

        return taxa(of: .genus)
    }

    /// Return the genera at or below a Taxon in an Array<Taxon>.
    ///
    public var families: [Taxon] {

        return taxa(of: .family)
    }

    /// Return all Taxa at a specific level at or below a Taxon in an Array<Taxon>.
    ///
    func taxa(of level: Level) -> [Taxon] {

        var result: [Taxon] = []

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
        for taxon in self {
            visit(taxon)
        }
        return result
    }

    /// Show the forest of Taxa through the specified level.
    ///
    public func show(through level: Level, indent: Int = 0) {
        for taxon in self {
            taxon.show(through: level, indent: indent)
        }
    }

    /// Assign sequential order numbers to taxa at the specified level.
    ///
    public func assignOrder(at level: Level) {
        for (index, taxon) in taxa(of: level).enumerated() {
            taxon.order = index
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
