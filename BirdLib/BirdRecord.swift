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

    public var order: Int {

        switch self {
        case .species(let taxon):
            return taxon.order!
        case .group(let group):
            return group.order
        }
    }
}

/// BirdRecord ("Sighting"). It has a kind (species or group), and can have optional
/// date, location, observer, and notes.
///
public struct BirdRecord: CustomStringConvertible {

    public let kind: RecordKind
    public let date: Day?
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


    var annualLine: String {
        "\(date!): \(notes ?? ""): \(observer ?? "")"
    }
}

/// Create a Dictionary with species Taxa as keys and quarter-month integer arrays as
/// values.
///
public func quarterMonthCounts (_ records: [BirdRecord]) -> [Taxon: [Int]] {

    // Create a map from species Taxa to the sets of days on which recorded.
    var daysBySpecies: [Taxon: Set<Day>] = [:]
    for record in records {
        guard case .species(let taxon) = record.kind,
              let day = record.date else {
            continue
        }
        daysBySpecies[taxon, default: []].insert(day)
    }

    // Create a map from species Taxa to the arrays of their quarter-monthly counts.
    var countsBySpecies: [Taxon: [Int]] = [:]
    for (species, days) in daysBySpecies {
        var counts = Array(repeating: 0, count: 48)
        for day in days {
            counts[day.quarterMonthIndex] += 1
        }
        countsBySpecies[species] = counts
    }
    return countsBySpecies
}
