//
//  BirdRecord.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 23 October 2026.
//

import Foundation

// Area and Location may become their own types; leave them Strings for now.
//
typealias Area = String
typealias Location = String

/// BirdRecords are either a species or a group.
///
public enum RecordKind {

    case species(Taxon)
    case group(BirdGroup)

    public var name: String {
        switch self {
        case .species(let taxon):
            return taxon.name
        case .group(let group):
            return group.name
        }
    }
}

/// BirdRecord ("Sighting"). It has a kind (species or group), and can have optional
/// date, location, observer, and notes.
///
public struct BirdRecord: CustomStringConvertible {

    public let kind: RecordKind
    let date: Day?
    public let location: String?
    public let observer: String?
    public let notes: String?

    init(kind: RecordKind, date: Day? = nil, location: String? = nil,
         observer: String? = nil, notes: String? = nil) {

        self.kind = kind
        self.date = date
        self.location = location
        self.observer = observer
        self.notes = notes
    }

    public var description: String {
        var buffer = ""
        if let date {
            buffer += "\(date)"
        }
        buffer += " \(kind.name)"
        if let notes {
            buffer += ": \(notes)"
        }
        if let observer {
            buffer += ": \(observer)"
        }
        return buffer
    }
}
