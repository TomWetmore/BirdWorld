//
//  MergeAdditions.swift
//  MergeAdditions
//
//  Created by Thomas Wetmore on 27 October 2026.
//  Last changed on 8 November 2026.
//
//  This program reads a species-grouped and an observer-grouped file of BirdRecords.
//  The BirdRecords are merged together and then written out as an updated species-
//  grouped file.
//

import Foundation
import BirdLib

@main
struct MergeAnnual {

    static let testOutURL = URL(fileURLWithPath: "/Users/ttw4/Desktop/BirdWorld/Resources/testout.txt")

    static func main() throws {

        // Create the Taxonomy using resource files found in the directory defined
        // by the BIRDWORLD_DATA environment variable.
        guard let path = ProcessInfo.processInfo.environment["BIRDWORLD_DATA"] else {
            throw RuntimeError("BIRDWORLD_DATA is not defined")
        }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        let taxaURL = directory.appendingPathComponent("taxa.txt")
        let groupsURL = directory.appendingPathComponent("groups.txt")
        let aliasesURL = directory.appendingPathComponent("aliases.txt")
        let taxonomy = try loadTaxonomy(from: taxaURL, groupsURL: groupsURL, aliasesURL: aliasesURL)

        // Convert the command line arguments into file URLs, and read the sightings and
        // additions files.
        var urls: [URL] = CommandLine.arguments.dropFirst().map {
            URL(fileURLWithPath: $0)
        }
        let sightingsURL = urls.removeFirst()
        let additionsURL = urls.removeFirst()


        // Get the BirdRecords from the species grouped, sightings file.
        var records = try readTaxonGroupedRecords(from: sightingsURL, taxonomy: taxonomy)
        print("\(records.count) records were read from an annual file")

        // Get the BirdRecords from an observer grouped, additions file.
        let additions = try readObserverGroupedRecords(from: additionsURL, taxonomy: taxonomy)
        print("\(additions.count) records were read from an additions file")

        // Merge the BirdRecords from the two files.
        try records.merge(additions)
        print("\(records.count) records merged from the annual and additions files")

        // Write the BirdRecords as a merged species grouped file.
        try writeAnnualRecords(records, to: testOutURL)
    }
}


public struct RuntimeError: Error {

    var message: String

    init(_ message: String) {
        self.message = message
    }

}
