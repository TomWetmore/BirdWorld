//
//  HTML.swift
//  FortyEight
//
//  Created by Thomas Wetmore on 28 October 2026.
//  Last changed on 29 October 2026.
//

import Foundation
import BirdLib

extension FortyEight {

    /// Generate the HTML for the FortyEight (Annual) Web Page.
    ///
    static func generateHTML(species: [Taxon], records: [BirdRecord],
                             counts: [Taxon : [Int]]) throws -> String {

        var html = try String(contentsOf: headerURL, encoding: .utf8)

        for (index, taxon) in species.enumerated() {
            if index > 0 && index.isMultiple(of: 20) {
                //html += legendHTML
                html += "HI, I'M THE LEGEND\n"
            }

            let counts = counts[taxon]!
            html += speciesHTML(taxon, counts: counts)
        }

        html += try trailer(species: species, records: records, counts: counts)
        return html
    }

    /// Generate the HTML for the trailer part of the FortyEight (Annual) Web Page.
    ///
    static func trailer(species: [Taxon], records: [BirdRecord],
                        counts: [Taxon : [Int]]) throws -> String {
        let totalSpecies = species.count
        //let totalReports = records.count
        let totalSightings = counts.values.reduce(0) {
            $0 + $1.reduce(0, +)
        }
        let today = Date.now.formatted(
            .dateTime.month(.wide).day().year()
        )
        return  """
            </table>
            <hr/>
            <p>Total species \(totalSpecies).
            Total reports \(totalReports.formatted()).
            Total sightings \(totalSightings.formatted()).</p>
            <address>
            \(today), Tom Wetmore
            </address>
            </body>
            </html>
            """
    }
}

/// Generate HTML for a single bird line with 48 gifs for the occurrence indications.
///
func speciesHTML(_ taxon: Taxon, counts: [Int]) -> String {

    var html = """
    <tr><td colspan="29" height="1" class="hl"></td></tr>
    <tr>
      <td class="species">\(taxon.englishName!)</td>
      <td align="right">\(counts.reduce(0, +))&nbsp;</td>

    """

    for month in 0..<12 {
        html += "  <td>"

        for quarter in 0..<4 {
            let count = counts[month * 4 + quarter]

            let code: String = switch count {
            case 0: "s"
            case 1: "1"
            case 2: "2"
            case 3...4: "3"
            case 5...6: "4"
            default: "5"
            }
            html += "<img src=\"\(code).gif\">"
        }
        html += "</td>\n"
    }
    html += "</tr>\n"
    
    return html
}
