//
//  Abbreviations.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 29 October 2026.
//  Last changed on 29 October 2026.
//

import Foundation

/// MOVE ELSEWHERE
///
public enum BirdWorldError: Error {

    case fileFormat(String)
}

/// Read the abbreviation definitions and build an index from
/// alternative bird names to their Taxa.
///
public func readAbbreviations(from url: URL, taxonomy: Taxonomy) throws -> [String: Taxon] {

    let file = try DelimitedFile(url, separator: ":")
    var abbreviations: [String: Taxon] = [:]

    while let line = try file.getFields() {

        let fields = line.fields  // Two fields: a species code and a pattern.
        let line = line.number

        guard fields.count == 2 else {
            throw BirdWorldError.fileFormat("line \(line): bad abbreviation")
        }

        let code = fields[0]
        let definition = fields[1]

        // Parse the abbreviation pattern.
        var pattern = TextPattern(definition)
        let strings = try pattern.expand()

        // Find the species identified by the code.
        guard let taxon = taxonomy.codeIndex[code] else {
            throw BirdWorldError.fileFormat("line \(line): \(code) is not a bird code")
        }

        // Normalize and insert each generated string.
        for string in strings {
            let key = prepareName(string)

            guard abbreviations[key] == nil else {
                throw BirdWorldError.fileFormat("line \(line): duplicate abbreviation \(key)")
            }

            abbreviations[key] = taxon
        }
    }

    return abbreviations
}

/// A TextPattern defines a set of strings. In BirdWorld the set of strings are all
/// valid String that can identify a species Taxon.
///
public struct TextPattern {

    private let characters: [Character]
    private var position = 0

    public init(_ source: String) {
        characters = Array(source)
    }

    /// Parse the pattern and return its possible strings.
    ///
    public mutating func expand() throws -> Set<String> {

        let strings = try parseAlternatives()

        guard position == characters.count else {
            throw PatternError("unexpected character at position \(position)")
        }
        return strings
    }

    /// Parse alternatives separated by vertical bars.
    ///
    private mutating func parseAlternatives() throws -> Set<String> {

        var result = try parseSequence()

        while consume("|") {
            result.formUnion(try parseSequence())
        }
        return result
    }

    /// Parse a sequence of adjacent pattern elements.
    ///
    private mutating func parseSequence() throws -> Set<String> {

        var result: Set<String> = [""]

        while let character = peek(), character != ")" && character != "]" && character != "|" {
            let next = try parseElement()
            result = concatenate(result, next)
        }
        return result
    }

    /// Parse one letter, optional expression, or grouped expression.
    ///
    private mutating func parseElement() throws -> Set<String> {

        if consume("[") {
            var result = try parseAlternatives()

            guard consume("]") else {
                throw PatternError("missing ] at position \(position)")
            }
            result.insert("")
            return result
        }

        if consume("(") {
            let result = try parseAlternatives()

            guard consume(")") else {
                throw PatternError("missing ) at position \(position)")
            }
            return result
        }

        guard let character = peek(), character.isLetter else {
            throw PatternError("unexpected character at position \(position)")
        }
        position += 1
        return [String(character)]
    }

    /// Concatenate every string in the first set with every string in the second set.
    ///
    private func concatenate(_ first: Set<String>, _ second: Set<String>) -> Set<String> {

        var result = Set<String>()

        for a in first {
            for b in second {
                result.insert(a + b)
            }
        }
        return result
    }

    private func peek() -> Character? {
        position < characters.count ? characters[position] : nil
    }

    private mutating func consume(_ character: Character) -> Bool {
        guard peek() == character else {
            return false
        }

        position += 1
        return true
    }
}

public struct PatternError: Error, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

/// Prepare a name by removing all non-letters and lowercasing all letters.
/// 
func prepareName(_ name: String) -> String {
    String(name.lowercased().filter { $0.isLetter })
}

