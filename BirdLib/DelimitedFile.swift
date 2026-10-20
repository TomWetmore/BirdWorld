//
//  DelimitedFile.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 19 October 2026.
//  Last changed on 19 October 2026.
//

import Foundation

public func readDelimitedFile(_ url: URL, separator: Character = ":") throws -> [[String]] {

    let text = try String(contentsOf: url, encoding: .utf8)

    return text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .map {
            $0.split(separator: separator, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
}
