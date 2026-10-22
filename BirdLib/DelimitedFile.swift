//
//  DelimitedFile.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 19 October 2026.
//  Last changed on 21 October 2026.
//

import Foundation

/// Read a delimited file (URL) and return an array of array of Strings, the fields found
/// on each line. The text files used by the BirdWorld are all in colon-separated format.
///
public func readDelimitedFile(_ url: URL, separator: Character = ":") throws -> [[String]] {

    let text = try String(contentsOf: url, encoding: .utf8)

    return text
        .components(separatedBy: .newlines)  // Break the lines into strings.
        .map { $0.trimmingCharacters(in: .whitespaces) }  // Trim whitespace from the lines.
        .filter { !$0.isEmpty }  // Skip empty lines.
        .map {
            // Break the lines at the separator and trim the fields.
            $0.split(separator: separator, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
}
