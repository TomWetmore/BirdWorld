//
//  Sighting.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

// Area and Location may become their own type.
//

typealias Area = String
typealias Location = String

public struct BirdRecord: CustomStringConvertible {

    let date: Day?
    public let species: Taxon
    public let location: String?
    public let observer: String?
    public let notes: String?

    init(date: Day? = nil, species: Taxon, location: String? = nil,
         observer: String? = nil, notes: String? = nil) {

        self.date = date
        self.species = species
        self.location = location
        self.observer = observer
        self.notes = notes
    }

    public var description: String {
        var buffer = ""
        if let date {
            buffer += "\(date)"
        }
        buffer += " \(species)"
        if let notes {
            buffer += ": \(notes)"
        }
        if let observer {
            buffer += ": \(observer)"
        }

        return buffer

    }
}
