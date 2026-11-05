//
//  BirdRecord.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 21 October 2026.
//  Last changed on 4 November 2026.
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

    // First create a map from species to the sets of days on which recorded.
    var daysBySpecies: [Taxon: Set<Day>] = [:]
    for record in records {
        guard case .species(let taxon) = record.kind,
              let day = record.date else {
            continue
        }
        daysBySpecies[taxon, default: []].insert(day)
    }

    // Then create a map from the species to quarter-monthly count arrays.
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

    /// Sort BirdRecords by taxonomic order, then date.
    mutating func sortTaxonomically() throws {

        // Check that all records have order numbers and dates.
        guard allSatisfy({
            $0.kind.order != nil && $0.date != nil
        }) else {
            throw RecordFileError.missingOrderOrDate
        }

        // Perform the sort.
        sort {
            if $0.kind.order! != $1.kind.order! {
                return $0.kind.order! < $1.kind.order!
            }
            return $0.date! < $1.date!
        }
    }
}

//extension Array<BirdRecord> {
//
//    /// Sort BirdRecords by taxonomic order, then date.
//    mutating func sortTaxonomically() {
//        sort {
//            if $0.kind.order! != $1.kind.order! {
//                return $0.kind.order! < $1.kind.order!
//            }
//            return $0.date! < $1.date!
//        }
//    }
//}

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
