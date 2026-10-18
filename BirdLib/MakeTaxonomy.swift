//
//  MakeTaxonomy.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 10/18/26.
//

import Foundation

func makeTaxonomy(from taxa: [Taxon]) -> [Taxon] {

    var roots: [Taxon] = []
    var stack: [Taxon] = []

    for taxon in taxa {

        // Remove taxa that cannot be the parent of this taxon.
        while let last = stack.last,
              last.level.depth >= taxon.level.depth {
            stack.removeLast()
        }

        if let parent = stack.last {
            parent.children.append(taxon)
            taxon.parent = parent
        } else {
            roots.append(taxon)
        }

        stack.append(taxon)
    }

    return roots
}
