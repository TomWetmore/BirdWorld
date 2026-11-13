//
//  BirdRecord.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 13 November 2026.
//

import Foundation

// Area and Location may become their own types; use Strings for now.
//
typealias Area = String
typealias Location = String

/// A BirdRecord is either a species or a group.
///
public enum RecordKind {

    case species(Taxon)
    case group(BirdGroup)

    /// Return the name of BirdRecord.
    ///
    public var name: String {
        switch self {
        case .species(let taxon):
            return taxon.name
        case .group(let group):
            return group.name
        }
    }

    /// Return the order of a BirdRecord
    public var order: Int? {

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
    public let range: DayRange?
    public let location: String?
    public let observer: String?
    public let notes: String?

    init(kind: RecordKind, range: DayRange? = nil,
         location: String? = nil, observer: String? = nil, notes: String? = nil) {
        self.kind = kind
        self.range = range
        self.location = location
        self.observer = observer
        self.notes = notes
    }

    public var description: String {
        var buffer = ""
        if let range {
            buffer += "\(range)"
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
        "\(range!): \(notes ?? ""): \(observer ?? "")"
    }
}

/// From an Array of BirdRecords create the Dictionary that maps Species Taxa to their
/// quarter-month Int occurence arrays.
///
public func quarterMonthCounts (_ records: [BirdRecord]) -> [Taxon: [Int]] {

    // Create the Map from the Species to the Sets of Days on which recorded.
    var daysBySpecies: [Taxon: Set<Day>] = [:]

    for record in records {
        guard case .species(let taxon) = record.kind,
              let day = record.range?.midpoint else {
            continue
        }
        daysBySpecies[taxon, default: []].insert(day)
    }

    // Create the Map from the Species to their quarter-monthly count arrays.
    var countsBySpecies: [Taxon: [Int]] = [:]
    
    for (species, days) in daysBySpecies {
        var counts = Array(repeating: 0, count: 48)  // Each array is 48 integers.
        for day in days {
            counts[day.quarterMonthIndex] += 1
        }
        countsBySpecies[species] = counts
    }
    return countsBySpecies
}

extension Array<BirdRecord> {

    /// Sort BirdRecords by taxonomic order, then by the start of the date range.
    mutating func sortTaxonomically() throws {
        
        guard allSatisfy({ $0.kind.order != nil && $0.range != nil }) else {
            throw RecordFileError.missingOrderOrDate
        }

        sort { first, second in
            let firstOrder = first.kind.order!
            let secondOrder = second.kind.order!

            if firstOrder != secondOrder {
                return firstOrder < secondOrder
            }

            return first.range!.start < second.range!.start
        }
    }
}

extension Array<BirdRecord> {

    /// Append records and sort the combined collection.
    ///
    public mutating func merge(_ additions: [BirdRecord]) throws {
        append(contentsOf: additions)
        try sortTaxonomically()
    }
}

extension Array<BirdRecord> {

    /// Return the combined records in taxonomic order.
    func merging(_ other: [BirdRecord]) throws -> [BirdRecord] {
        var result = self
        result.append(contentsOf: other)
        try result.sortTaxonomically()
        return result
    }
}
