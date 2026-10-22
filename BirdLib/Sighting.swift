//
//  Sighting.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 21 October 2026.
//

import Foundation

// Area and Location may become their own type.
//
typealias Area = String
typealias Location = String

public struct Sighting {

    public let date: Date
    public let species: Taxon
    public let location: String
    public let observer: String
    public let notes: String

}
