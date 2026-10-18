//
//  ReadTaxa.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 17 October 2026.
//  Last changed on 18 October 2026.
//

import Foundation



public func readTaxa(from url: URL) throws -> [Taxon] {

    let text = try String(contentsOf: url, encoding: .utf8)
    var taxa: [Taxon] = []

    for (index, rawLine) in text.components(separatedBy: .newlines).enumerated() {

        let line = rawLine.trimmingCharacters(in: .whitespaces)

        // Ignore blank lines.
        guard !line.isEmpty else {
            continue
        }

        let fields = line
            .split(separator: ":", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard fields.count >= 2 else {
            throw TaxaFileError.invalidLine(index + 1, line)
        }

        switch fields[0] {

        case "order":
            try requireFieldCount(fields, 2, line: index + 1)
            taxa.append(Taxon(
                level: .order,
                englishName: nil,
                scientificName: fields[1],
                bandingCode: nil))

        case "family":
            try requireFieldCount(fields, 2, line: index + 1)
            taxa.append(Taxon(
                level: .family,
                code: nil,
                englishName: nil,
                scientificName: fields[1],
                bandingCode: nil))

        case "subfamily":
            try requireFieldCount(fields, 2, line: index + 1)
            taxa.append(Taxon(
                level: .subfamily,
                code: nil,
                englishName: nil,
                scientificName: fields[1],
                bandingCode: nil))

        case "genus":
            try requireFieldCount(fields, 2, line: index + 1)
            taxa.append(Taxon(
                level: .genus,
                code: nil,
                englishName: nil,
                scientificName: fields[1],
                bandingCode: nil))

        default:
            // Species:
            // code: English name: scientific name [: banding code]

            guard fields.count == 3 || fields.count == 4 else {
                throw TaxaFileError.invalidLine(index + 1, line)
            }

            taxa.append(Taxon(
                level: .species,
                code: fields[0],
                englishName: fields[1],
                scientificName: fields[2],
                bandingCode: fields.count == 4 ? fields[3] : nil))
        }
    }

    return taxa
}

enum TaxaFileError: Error {
    
    case invalidLine(Int, String)
    case wrongFieldCount(Int, Int, Int)
}

private func requireFieldCount(_ fields: [String], _ expected: Int, line: Int) throws {

    guard fields.count == expected else {
        throw TaxaFileError.wrongFieldCount(line, expected, fields.count)
    }
}
