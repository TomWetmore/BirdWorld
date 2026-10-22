//
//  Day.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 22 October 2026.
//  Last changed on 22 October 2026.
//

import Foundation

/// A calendar day, independent of time and time zone.
/// Internally represented as days since January 1, 1970.
public struct Day: Hashable, Comparable, CustomStringConvertible {

    public let number: Int

    /// Construct a Day from a year, month, and day.
    /// Returns nil for an invalid date.
    ///
    public init?(year: Int, month: Int, day: Int) {

        guard (1...12).contains(month) else { return nil }

        let daysInMonth = Self.daysInMonth(year: year, month: month)
        guard (1...daysInMonth).contains(day) else { return nil }

        number = Self.daysFromCivil(year, month, day)
    }

    /// Parse a date such as "18 oct 2026".
    /// Month names are case-insensitive.
    public init?(_ text: String) {

        let parts = text.split(whereSeparator: \.isWhitespace)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let year = Int(parts[2]),
              let month = Self.monthNumber(String(parts[1]))
        else {
            return nil
        }

        self.init(year: year, month: month, day: day)
    }

    /// Construct directly from an integer day number.
    public init(number: Int) {
        self.number = number
    }

    /// Return the year, month, and day.
    public var components: (year: Int, month: Int, day: Int) {
        Self.civilFromDays(number)
    }

    /// Display as "18 Oct 2026".
    public var description: String {
        let (year, month, day) = components
        return "\(day) \(Self.monthNames[month - 1]) \(year)"
    }

    /// Compare two days.
    public static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.number < rhs.number
    }

    /// Number of days between two dates.
    public static func - (lhs: Day, rhs: Day) -> Int {
        lhs.number - rhs.number
    }

    /// Add a number of days.
    public static func + (lhs: Day, rhs: Int) -> Day {
        Day(number: lhs.number + rhs)
    }

    /// Subtract a number of days.
    public static func - (lhs: Day, rhs: Int) -> Day {
        Day(number: lhs.number - rhs)
    }
}

// MARK: - Calendar calculations

private extension Day {

    static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    static func monthNumber(_ name: String) -> Int? {
        let name = name.lowercased()
        return monthNames.firstIndex {
            $0.lowercased() == name
        }.map { $0 + 1 }
    }

    static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2:
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    /// Convert Gregorian year/month/day to days since 1970-01-01.
    /// Based on Howard Hinnant's civil calendar algorithms.
    static func daysFromCivil(_ year: Int, _ month: Int, _ day: Int) -> Int {

        let y = year - (month <= 2 ? 1 : 0)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = month + (month > 2 ? -3 : 9)
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy

        return era * 146097 + doe - 719468
    }

    /// Convert days since 1970-01-01 to Gregorian year/month/day.
    static func civilFromDays(_ number: Int) -> (year: Int, month: Int, day: Int) {

        let z = number + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        var year = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let day = doy - (153 * mp + 2) / 5 + 1
        let month = mp + (mp < 10 ? 3 : -9)

        if month <= 2 {
            year += 1
        }

        return (year, month, day)
    }
}
