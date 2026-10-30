// FortyEight2026.java

package com.bartonstreet.birds.programs;

import com.bartonstreet.birds.*;
import com.bartonstreet.util.*;
import com.bartonstreet.io.*;

import java.util.*;
import java.io.*;

/** This class generates an HTML file that shows the raw form of the Plum
 *  Island bird checklist. There is one code letter generated for each species
 *  for each quarter month.
 *
 *	@author Thomas Wetmore
 *	@version 1 January 2026
 */
public class FortyEight2026
{
	static BirdHandler birdHandler;
	static ColonFile currentFile;
	static Set<Bird> allSpecies = new TreeSet<Bird>();
	static boolean errorFound = false;
	static int totalReports = 0;
	static int totalSightings = 0;
	static private final Day today = Day.today();

	/** The main program that coordinates the processing of bird record files
	 *	and the generation of month quarter codes.
	 *
	 *	@param args array of file names
	 */
	static public void main (String[] args) throws IOException,
		ColonFileException
	{
		/* Check arguments. */
		if (args.length < 1) {
			System.out.println(
				"usage: java com.bartonstreet.birds.FortyEight " +
				"date file...");
			System.exit(1);
		}

		/* Create and initialize the bird handler. */
		birdHandler = new BirdHandler();
		birdHandler.initialize("resources/taxa", null, "resources/groups");

		/* Process the files mentioned on the command line. */
		for (int i = 0, n = args.length; i < n; i++)
			processRecordFile(args[i]);

		/* If errors were found quit without generating any output. */
		if (errorFound) {
			System.err.println("Fix the errors and run again.");
			System.exit(1);
		}

		/* There were no errors during processing so generate the output. */
		generateHTML();
	}

	/** Process a single records file.
	 *
	 *	@param fname the name of the records file to process.
	 */
	static private void processRecordFile (String fname)
		throws IOException, ColonFileException
	{
		currentFile = new ColonFile(fname);
		String name = null;
		Bird bird = null;
		DayRange dayRange = null;

		/* Get the first list of fields from the records file. */
		while (true) {
			List fields = currentFile.getFields();
			int lineNumber = currentFile.getLineNumber();

			/* Check if done. */
			if (fields == null) break;

			int size = fields.size();

			/* If there is one field, the line holds a bird or group name. */
			if (size == 1) {
				name = (String) fields.get(0);
				bird = birdHandler.getSpeciesByCommonName(name);
				if (bird == null) continue;

				/* If this is the first time seen, prepare species for data. */
				if (!allSpecies.contains(bird)) {
					Set<Day> data = new TreeSet<Day>();
					bird.setData(data);
					allSpecies.add(bird);
				}
				continue;
			}

			/* If there is no bird here (could be a group), continue. */
			if (bird == null) continue;

			/* Issue error if not exactly three fields. */
			if (size != 3) {
				error(lineNumber, "Illegal line");
				continue;
			}

			/* Handle a normal reporting line - frist field must hold date. */
			dayRange = DayRange.extractDayRange((String) fields.get(0));
			if (dayRange == null) {
				error(lineNumber, "Illegal record line");
				continue;
			}

			/* Convert the DayRange to a Day. */
			if (!dayRange.isSingleDay()) continue;

			long mjd = dayRange.toLong();
			Day day = Day.fromLong(mjd);

			/* Update the set of days that this bird was seen. */
			((Set<Day>) bird.getData()).add(day);
			totalReports++;

		} /* processing line from file */
	} /* processRecordFile */

	/** Given a Day return its index value, a number from 0 to 47.
	 */
	static int getIndex (Day day)
	{
		int month = day.getMonthInt();
		int index = 2; // 31 day month.
		if (month == 2)
			index = 0; // 28 or 29 day month.
		else if (month == 4 || month == 6 || month == 9 || month == 11)
			index = 1; // 30 day month.

		int b1 = 7;
		if (index == 2) b1 = 8;

		int b2 = 14;
		if (index == 1) b2 = 15;
		else if (index == 2) b2 = 16;

		int b3 = 21;
		if (index == 1) b3 = 22;
		else if (index == 2) b3 = 23;

		int da = day.getDay();
		int monthOffset = (month - 1)*4;
		if (da <= b1) return monthOffset;
		if (da <= b2) return monthOffset + 1;
		if (da <= b3) return monthOffset + 2;
		return monthOffset + 3;
	}

	/** Generate the HTML page holding the results.
	 */
	static private void generateHTML ()
	{
		generateHeading();
		generateBirdTable();
		generateTrailer();
	}

	/** Generate the HTML prior to the table.
	 */
	static private void generateHeading ()
	{
		System.out.println("<html>");
		System.out.println("<head>");
		System.out.println("<title>2026 Quarter-Month Status of the Birds of Plum Island</title>");
		System.out.println("<link rel=\"stylesheet\" type=\"text/css\" media=\"screen\"");
		System.out.println("		href=\"../../../style.css\"/>");
		System.out.println("</head>");
		System.out.println("<style type=\"text/css\">");
		System.out.println("	.species { font-family: sans-serif; background-color: #ddd; padding: 3px 0px 3px 3px;}");
		System.out.println("	.head { font-family: sans-serif; background-color: #bfd;");
		System.out.println("		font-style: oblique; }");
		System.out.println("	.codes { font-size: 110%; background-color: #bdf; font-family: monospace; align:left");
		System.out.println("		white-space: pre; }");
		System.out.println("	.vl { background: #666; width: 1px; }");
		System.out.println("	.hl { background: #666; }");
		System.out.println("	.mc {font-family: sans-serif; background-color: #ddd; width: 37px; margin: 0; padding: 3px 0px 3px 0px; }");
		System.out.println("	td { font-size: 95%; width: 0px; }");

		System.out.println("</style>");
		System.out.println("");
		System.out.println("<a href=\"../index.html\"><h5>Tom&rsquo;s Birding Page</h5></a>");
		System.out.println("<hr/>");
		System.out.println("<h2>2026 Quarter-Month Status<br/>");
		System.out.println("Birds of Plum Island, Essex County, Massachusetts</h2>");
		System.out.println("<h4>Compiled by Tom Wetmore</h4>");
		System.out.println("<hr/>");
		System.out.println("<p>");
		System.out.println("This table shows the 2026 quarter-month status of the birds of Plum Island.");
		System.out.println("It is based on data collected for inclusion");
		System.out.println("on the Plum Island sigthings web site.");
		System.out.println("The column labeled <i>N</i> shows the number");
		System.out.println("days the species has been reported in 2026.");
		System.out.println("</p>");
		System.out.println("");
		System.out.println("<hr/>");
		System.out.print("<h3 class=\"center\">Status of the Birds of Plum Island &mdash; <i>updated ");
		System.out.print(today.getMonthName() + " " + today.getDay() + ", " +  today.getYear() + " &mdash; day " + today.getDayOfYear());
		System.out.println("</i></h3>");
		System.out.println("");

		System.out.println("<table width=\"752\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">");
		System.out.println("<tr><td colspan=\"29\" height=\"1\" class=\"hl\"></td></tr>");
		System.out.println("<tr>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td width=\"286\">&nbsp;Species</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td align=\"center\"><i>N</i></td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Jan</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Feb</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Mar</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Apr</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;May</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Jun</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Jul</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Aug</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Sep</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Oct</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Nov</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("<td class=\"mc\">&nbsp;Dec</td>");
		System.out.println("<td rowspan=\"1000\" class=\"vl\"></td>");
		System.out.println("</tr>");
	}

	/** Generate the species table in HTML format.
	 */
	static private void generateBirdTable ()
	{
		/* Iterate through all the species in taxonomic order. */
		Iterator iter = allSpecies.iterator();
		System.out.println("<tr><td colspan=\"29\" height=\"1\" class=\"hl\"></td></tr>");
		int k = 0;
		while (iter.hasNext()) {
			if (k > 0 && (k % 20 == 0)) {
				System.out.println("<tr>");
				System.out.println("<td></td>");
				System.out.println("<td></td>");
				System.out.println("<td class=\"mc\">&nbsp;Jan</td>");
				System.out.println("<td class=\"mc\">&nbsp;Feb</td>");
				System.out.println("<td class=\"mc\">&nbsp;Mar</td>");
				System.out.println("<td class=\"mc\">&nbsp;Apr</td>");
				System.out.println("<td class=\"mc\">&nbsp;May</td>");
				System.out.println("<td class=\"mc\">&nbsp;Jun</td>");
				System.out.println("<td class=\"mc\">&nbsp;Jul</td>");
				System.out.println("<td class=\"mc\">&nbsp;Aug</td>");
				System.out.println("<td class=\"mc\">&nbsp;Sep</td>");
				System.out.println("<td class=\"mc\">&nbsp;Oct</td>");
				System.out.println("<td class=\"mc\">&nbsp;Nov</td>");
				System.out.println("<td class=\"mc\">&nbsp;Dec</td>");
				System.out.println("</tr>");
				System.out.println("<tr><td colspan=\"29\" height=\"1\" class=\"hl\"></td></tr>");
			}
			k++;
			Bird bird = (Bird) iter.next();
			TreeSet set = (TreeSet) bird.getData();
			int size = set.size();
			totalSightings += size;
			int[] data = new int[48];
			for (int i = 0, n = 48; i < n; i++) data[i] = 0;
			Iterator diter = set.iterator();
			while (diter.hasNext()) {
				Day day = (Day) diter.next();
				int index = getIndex(day);
				data[index]++;
			}

			// Start a new row for the next species.
			System.out.println("<tr>");

			// Output the species name column.
			System.out.println("  <td class=\"species\">"
				+ bird.getCommonName() + "</td>");

			// Output the number of sightings column.
			System.out.println("  <td " + "align=\"right\">" +
				size + "&nbsp;</td>");

			// Output a column for each month.
			for (int i = 0; i < 12; i++) {

				// Start the column for the ith month.
				System.out.print("    <td>");

				// Output the four images for the ith month.
				int offset = i*4;
				for (int j = 0; j < 4; j++) {
					int amount = data[offset + j];

					if (amount == 0) {
						System.out.print("<img src=\"s.gif\">");
					} else if (amount <= 1) {
						System.out.print("<img src=\"1.gif\">");
					} else if (amount <= 2) {
						System.out.print("<img src=\"2.gif\">");
					} else if (amount <= 4) {
						System.out.print("<img src=\"3.gif\">");
					} else if (amount <= 6) {
						System.out.print("<img src=\"4.gif\">");
					} else {
						System.out.print("<img src=\"5.gif\">");
					}
				}

				// End the column for the ith month.
				System.out.println("</td>");
			}
			System.out.println("</tr>");
			System.out.println("<tr><td colspan=\"29\" height=\"1\" class=\"hl\"></td></tr>");
		}
	}

	/** Generate the HTML trailer for the output file.
	 */
	static private void generateTrailer ()
	{
		System.out.println("</table>");
		System.out.println("<hr/>");
		System.out.println("<p>Total species " + allSpecies.size() + ".");
		IntFormat iformat = new IntFormat();
		iformat.setGroupChar(',');
		iformat.setWidth(6);
		iformat.setGroupSize(3);
		String totalString = iformat.format(totalReports);
		System.out.println("Total reports " + totalString + ".");
		totalString = iformat.format(totalSightings);
		System.out.println("Total sightings " + totalString + ".</p>");
		System.out.println("<address>");
		System.out.print(today.getMonthName() + " " + today.getDay() +
			", " + today.getYear());
		System.out.println(", Tom Wetmore");
		System.out.println("</address>");
		System.out.println("</body>");
		System.out.println("</html>");
	}

	static private void error (int line, String message)
	{
		System.err.println("error: line: " + line + "\t" + message);
		errorFound = true;
	}
}
