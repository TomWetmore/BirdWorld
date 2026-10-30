//
//  DelimitedFile.swift
//  BirdLib
//
//  Created by Thomas Wetmore on 19 October 2026.
//  Last changed on 29 October 2026.
//

import Foundation

/// A line of fields read from a delimited file.
///
public struct DelimitedLine {

    public let number: Int  // Line number.
    public let fields: [String]
}

/// Read a delimited text file one line at a time.
///
public final class DelimitedFile {

    private let handle: FileHandle
    private let separator: Character

    private var lineNumber = 0

    // Buffered input.
    private let bufferSize = 16 * 1024
    private var buffer = Data()
    private var position = 0
    private var atEOF = false

    /// Open a delimited file for reading.
    public init(_ url: URL, separator: Character = ":") throws {
        self.handle = try FileHandle(forReadingFrom: url)
        self.separator = separator
    }

    deinit {
        try? handle.close()
    }

    /// Return the next nonempty line as fields, or nil at EOF.
    public func getFields() throws -> DelimitedLine? {

        while let text = try readLine() {
            lineNumber += 1

            let line = text.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            let fields = line
                .split(separator: separator, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }

            return DelimitedLine(number: lineNumber, fields: fields)
        }

        return nil
    }

    /// Read the next physical line from the file.
    /// Recognizes LF and CRLF line endings.
    private func readLine() throws -> String? {

        while true {

            // Look for a newline in the buffered data.
            if let newline = buffer[position...].firstIndex(of: 10) {

                let bytes = buffer[position..<newline]
                position = newline + 1

                // Remove CR from CRLF.
                let line = bytes.last == 13 ? bytes.dropLast() : bytes[...]

                return String(decoding: line, as: UTF8.self)
            }

            // No newline found. Check for EOF.
            if atEOF {
                guard position < buffer.count else {
                    return nil
                }

                let bytes = buffer[position...]
                position = buffer.count

                return String(decoding: bytes, as: UTF8.self)
            }

            // Preserve any incomplete line.
            if position > 0 {
                buffer.removeSubrange(0..<position)
                position = 0
            }

            // Read another chunk.
            let data = try handle.read(upToCount: bufferSize) ?? Data()

            if data.isEmpty {
                atEOF = true
            } else {
                buffer.append(data)
            }
        }
    }
}
