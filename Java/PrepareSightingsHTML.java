// PrepareSightingsHTML.java

package com.bartonstreet.birds.programs;

import com.bartonstreet.birds.*;
import com.bartonstreet.util.*;
import com.bartonstreet.io.*;

import java.util.*;
import java.io.*;

/** This class prepares the database file and HTML web page for the Plum Island
 *    bird sightings.
 *
 *    @author Thomas Wetmore
 *    @version 2022.10.30
 */
public class PrepareSightingsHTML
{
    //static private final int DAYSTOTRIM = 21; // show three weeks of data
    //static private final int DAYSTOTRIM = 14; // shows two weeks of data
    static private final int DAYSTOTRIM = 10; // shows ten days of data
    //static private final int DAYSTOTRIM = 7; // show one week of data
    //static private final int DAYSTOTRIM = 8; // show one week of data
    //static private final int DAYSTOTRIM = 15; // show 15 days of data
    //static private final int DAYSTOTRIM = 15; // show 15 days of data
    //static private final int DAYSTOTRIM = 20; // show 20 days of data

    static private final Day today = Day.today();

    /* The integer value of the latest day with a bird record. */
    static long lastDay = 0;

    /* The two input data format types, quick added later. */
    static private final int ORIGINAL = 0; // species alone, then lines of date: notes: observer
    static private final int QUICK = 1; // code: value
    static private final int COMPLETE = 2; // species: date: notes: observer

    /* The current data format input type. */
    static int formatType = ORIGINAL;

    /* Bird handler that manages the taxa tables. */
    static BirdHandler handler;

    /* Current journal file being processed. */
    static ColonFile currentFile;

    /* List of all species with observation records. */
    static TreeSet<Bird> allSpecies = new TreeSet<Bird>();

    /* True iff there were errors found in one or more input files. */
    static boolean errorFound = false;

    /** The main program that coordinates the processing of bird record files
     *    and the generation of lists of observation dates.
     *
     *    @param args array of file names
     */
    static public void main (String[] args) throws IOException,
        ColonFileException
    {
        /* Check arguments. */
        if (args.length < 1) {
            System.out.println(
                "usage: java com.bartonstreet.birds.PrepareSightingsHTML " +
                "file ...");
            System.exit(1);
        }

        /* Create and initialize the bird handler. */
        handler = new BirdHandler();
        handler.initialize("resources/taxa", null, "resources/groups",
            "resources/abbvs");

        /* Process the files mentioned on the command line. */
        for (int i = 0, n = args.length; i < n; i++)
            processRecordFile(args[i]);

        /* If errors were found quit without generating any output. */
        if (errorFound) {
            System.err.println("Fix the errors and run again.");
            System.exit(1);
        }

        /* There were no errors during processing so generate the output. */
        if (args.length == 1) outputHTML();
        else outputMerge();
    }

    /** Process a single records file.
     *
     *    @param fname the name of the records file to process.
     */
    static private void processRecordFile (String fname)
        throws IOException, ColonFileException
    {
        currentFile = new ColonFile(fname);
        //System.out.println("fname is " + fname); // DEBUG DEBUG
        String name = null;
        Bird bird = null;
        String author = null;
        DayRange dayRange = null;
        String locale = null;
        String info = null;

        /* Get the first list of fields from the records file. */
        while (true) {
            List fields = currentFile.getFields();
            int lineNumber = currentFile.getLineNumber();

            /* Check if done. */
            if (fields == null) break;
            int size = fields.size();

            if (formatType == ORIGINAL) {

                /* Check if this is a format change. */
                if (size == 2) {
                    String key = (String) fields.get(0);
                    if (key.equals("type") || key.equals("t")) {
                        String value = (String) fields.get(1);
                        if (value.equals("quick"))
                            formatType = QUICK;
                        else if (value.equals("complete"))
                            formatType = COMPLETE;
                        else
                            error(lineNumber, "Illegal format change line");
                    } else {
                        error(lineNumber, "Unknown two field line");
                    }
                    continue;
                }
                /* Check if a new species. */
                if (size == 1) {
                    name = (String) fields.get(0);
                    bird = handler.getSpeciesByCode(name);
                    if (bird == null) bird = handler.getGroupByCode(name);
                    if (bird == null) bird = handler.getGroupByName(name);
                    if (bird == null) bird = handler.getSpeciesByName(name);
                    if (bird == null) {
                        error(lineNumber, "Unknown species or group: " + name);
                        continue;
                    }
                    if (!allSpecies.contains(bird)) {
                        bird.setData(new ArrayList());
                        allSpecies.add(bird);
                    }
                    continue;
                }

                /* Issue error if not exactly three fields. */
                if (size != 3) {
                    error(lineNumber, "Illegal line");
                    continue;
                }

                /* Handle a normal reporting line. */
                dayRange = DayRange.extractDayRange((String) fields.get(0));
                if (dayRange == null) {
                    System.out.println("field 0 is " + fields.get(0));
                    System.out.println("field 1 is " + fields.get(1));
                    System.out.println("field 2 is " + fields.get(2));
                    error(lineNumber, "dayRange is null");
                }
                if (dayRange.toLong() > lastDay) lastDay = dayRange.toLong();
                info = (String) fields.get(1);
                author = (String) fields.get(2);
                if (dayRange == null || info == null || author == null) {
                    error(lineNumber, "Illegal record line");
                    continue;
                }
                if (bird == null) error(lineNumber, "Bird is null");
                List<Entry> list = (List<Entry>) bird.getData();
                list.add(new Entry(dayRange, info, author));

            /* Handle the quick data format. */
            } else if (formatType == QUICK) {

                /* In quick format every legal line has two fields. */
                if (size <= 0) {
                    error(lineNumber, "Illegal line");
                    continue;
                }

                /* Extract the key and value from the current file line. */
                String key = (String) fields.get(0);
                String value = (size == 2 ? (String) fields.get(1) : "yes");

                /* Allow "comments" in the file. */

// PLACE WHERE ERRORS HAVE OCCURRED: TURN ON FOLLOWING LINE TO TRACK THEM DOWN.
//System.out.println("key is " + key);
                if (key.equals("Note")) continue;

                /* In quick format every legal line has two fields. */
                if (size > 2) {
                    error(lineNumber, "Illegal line");
                    continue;
                }
                /* Check if this is a format change. */
                if (key.equals("type") || key.equals("t")) {
                    if (value.equals("original")) {
                        formatType = ORIGINAL;
                        author = null;
                        dayRange = null;
                        locale = null;
                    } else {
                        error(lineNumber, "Illegal type line");
                    }
                    continue;
                }

                /* Check if this is an observer/author change. */
                if (key.equals("observer") || key.equals("o")) {
                    if (value == null || value.length() == 0)
                        error(lineNumber, "Illegal observer line");
                    author = value;
                    continue;
                }

                /* Check if this is a locale change. */
                if (key.equals("locale") || key.equals("l")) {
                    if (value == null) value = "";
                    locale = value;
                    if (locale.equals("off")) locale = "";
                    continue;
                }

                /* Check if this is a date change. */
                if (key.equals("date") || key.equals("d")) {
                    dayRange = DayRange.extractDayRange(value);
                    if (dayRange == null)
                        error(lineNumber, "Illegal date value");
                    continue;
                }

                /* The lines should be a bird observation line. */
                bird = handler.getSpeciesByCommonName(key);
                if (bird == null) bird = handler.getSpeciesByCode(key);
                if (bird == null) bird = handler.getSpeciesByBandingCode(key);
                if (bird == null) bird = handler.getGroupByName(key);
                if (bird == null) bird = handler.getGroupByCode(key);
                if (bird == null) bird = handler.getSpeciesByName(key);
                if (bird == null) {
                System.out.println("THERE IS AN ERROR"); // UGLY DEBUG
                    error(lineNumber, "Unknown species or group: " + key);
                    continue;
                }
                if (!allSpecies.contains(bird)) {
                    bird.setData(new ArrayList());
                    allSpecies.add(bird);
                }
                List<Entry> list = (List<Entry>) bird.getData();
                if (dayRange == null) {
                    error(lineNumber, "No date for record");
                    continue;
                }
                if (author == null) {
                    error(lineNumber, "No authority for record");
                    continue;
                }
                boolean valueOk = (value != null && value.length() != 0);
                boolean localeOk = (locale != null && locale.length() != 0);
                if (valueOk && localeOk) info = value + ", " + locale;
                else if (valueOk) info = value;
                else if (localeOk) info = locale;
                else info = "yes";
                Entry entry =
                    new PrepareSightingsHTML.Entry(dayRange, info, author);
                list.add(entry);

            } /* END QUICK FORMAT */ else { /* START COMPLETE FORMAT */

                /* Issue error if not exactly four fields. */
                if (size != 4) {
                    error(lineNumber, "Illegal line");
                    continue;
                }

                /* Handle a complete reporting line. */
                name = (String) fields.get(0);
                bird = handler.getSpeciesByCode(name);
                if (bird == null) bird = handler.getGroupByCode(name);
                if (bird == null) bird = handler.getGroupByName(name);
                if (bird == null) bird = handler.getSpeciesByName(name);
                if (bird == null) {
                    error(lineNumber, "Unknown species or group: " + name);
                    continue;
                }
                if (!allSpecies.contains(bird)) {
                    bird.setData(new ArrayList());
                    allSpecies.add(bird);
                }

                dayRange = DayRange.extractDayRange((String) fields.get(1));
                if (dayRange.toLong() > lastDay) lastDay = dayRange.toLong();
                info = (String) fields.get(2);
                author = (String) fields.get(3);
                if (dayRange == null || info == null || author == null) {
                    error(lineNumber, "Illegal record line");
                    continue;
                }
                if (bird == null) error(lineNumber, "Bird is null");
                List<Entry> list = (List<Entry>) bird.getData();
                list.add(new Entry(dayRange, info, author));
            } // handling complete format line
        } /* processing single line from file */
    } /* processRecordFile */

    /** Generate the sightings web page from the data now in allSpecies. First
     *  trim the data to the time period of interest.
     */
    static private void outputHTML ()
    {
        trimBirds(DAYSTOTRIM);
        outputHeading();
        outputTable();
        outputTrailer();
    }

    static private void outputTable ()
    {
        int count = countLines();
        Bird breakBird = findBreakSpecies(count);

        System.out.println("<table class=\"bordered\" cellspacing=\"0\">");
        System.out.println("<tr class=\"row\">");
        System.out.println("<td valign=\"top\" width=\"50%\">");
        System.out.println("<ul>");

        for (Bird bird: allSpecies) {
            if (bird == breakBird) {
                System.out.println("</ul>");
                System.out.println("</td>");
                System.out.println("");
                System.out.println("");
                System.out.println("<td valign=\"top\" width=\"50%\">");
                System.out.println("<ul>");
            }
            List list = (List) bird.getData();
            System.out.print("<li class=\"species\"><b>" + bird.getCommonName() + "</b>");
            String officialName = bird.getOfficialName();
            if (officialName != null)
                System.out.print(", <i>" + bird.getOfficialName() + "</i>");
            System.out.println("  <ul>");
            Object objects[] = list.toArray();
            Arrays.sort(objects);
            for (int i = 0; i < objects.length; i++) {
                String color = ((Entry) objects[i]).getColor(lastDay);
                System.out.println("<li class=\"" + color + "\">" + objects[i] +
                    "</li>");
            }
            System.out.println("</ul></li>");
        }
        System.out.println("</ul>");
        System.out.println("</td>");
        System.out.println("</tr>");
        System.out.println("</table>");
    }

    //----------------------------------------------------------------
    // Remove all birds not seen in the past (numDays + 1) days, and
    // remove all record entries from the remaining birds that are not
    // in the last (numDays + 1) days.
    //----------------------------------------------------------------
    static private void trimBirds (int numDays)
    {
        TreeSet<Bird> keepSpecies = new TreeSet<Bird>();
        long cutoffDay = lastDay - numDays + 1;
        for (Bird bird: allSpecies) {
            List list = (List) bird.getData();
            ArrayList<Entry> newList = new ArrayList<Entry>();
            int n = list.size();
            for (int i = 0; i < n; i++) {
                Entry entry = (Entry) list.get(i);
                long dayLong = entry.dayRange.toLongEnd();
                if (dayLong < cutoffDay) continue;
                newList.add(entry);
            }
            if (newList.size() == 0) continue;
            bird.setData(newList);
            keepSpecies.add(bird);
        }
        allSpecies = keepSpecies;
    }

    //--------------------------------------------------
    // Count how many lines to output in the HTML table.
    //--------------------------------------------------
    static private int countLines ()
    {
        int count = 0;
        Iterator iter = allSpecies.iterator();
        while (iter.hasNext()) {
            Bird bird = (Bird) iter.next();
            List list = (List) bird.getData();
            count += 1 + list.size(); // add 1 for the species/group name
        }
        return count;
    }

    /** Find the species that should be at the top of the second column in the
     *  output table. This is done by finding finding the smallest difference
     *  possible in the lengths of the two columns.
     */
    static private Bird findBreakSpecies (int count)
    {
        int left = 0;
        int right = count;
        int diff = count;
        Iterator iter = allSpecies.iterator();
        while (iter.hasNext()) {
            Bird bird = (Bird) iter.next();
            List list = (List) bird.getData();
            int size = 1 + list.size();
            left += size;
            right -= size;
            int newDiff = right - left;
            if (newDiff < 0) newDiff = -newDiff;
            if (newDiff >= diff) return bird;
            diff = newDiff;
        }
        return null; // this cannot happen
    }

    /** If there were more than one file mentioned on the command line the
     *  output of this program is an "original" format file with all data from
     *  all input files merged together in systematic order of species and date
     *  order observations.
     */
    static private void outputMerge ()
    {
        Iterator iter = allSpecies.iterator();
        while (iter.hasNext()) {
            Bird bird = (Bird) iter.next();
            ArrayList list = (ArrayList) bird.getData();
            System.out.println(bird.getCommonName());
            Object objects[] = list.toArray();
            Arrays.sort(objects);
            for (int i = objects.length - 1; i >= 0; --i) {
                Entry entry = (Entry) objects[i];
                DayRange dayRange = entry.dayRange;
                StringBuffer buf = new StringBuffer();
                buf.append(dayRange.toString(true, true));
                buf.append(": ");
                buf.append(entry.info);
                buf.append(": ");
                buf.append(entry.author);
                System.out.println(buf);
            }
            System.out.println();
        }
    }

    static private void outputHeading ()
    {
        System.out.println("<html>");
        System.out.println("<head>");
        System.out.println("<title>Recent Bird Sightings from Plum Island</title>");
        System.out.println("<link rel=\"stylesheet\" type=\"text/css\" media=\"screen\" href=\"../../style.css\"/>");


        System.out.println("<style type=\"text/css\">");
        System.out.println("td { border-color: #b8b8b8;");
        System.out.println("border-style: none; border-width: thin; }");
        System.out.println(".lastday { background-color: rgb(255,204,102); color: black; }");
        System.out.println(".oneweek { background-color: rgb(149,159,96); color: black; }");
        System.out.println(".twoweek { background-color: rgb(211,157,96); color: black; }");
        System.out.println(".threeweek { background-color: rgb(217,163,137); color: black; }");
        System.out.println(".species { background-color: #ccc; }");
        System.out.println(".row { background-color: #ddd; }");
        System.out.println(".right { text-align: right; }");
        System.out.println("li { color: #000048; }");
        System.out.println("</style>");
        System.out.println("</head>");
        System.out.println("");
        System.out.println("<body bgcolor=\"#FFFF99\">");
        System.out.println("");
// Following 3 lines added 10/30/2022 to try to foce the page to reload when clicked.
        //System.out.println("<script>");
        //System.out.println("location.reload();");
        //System.out.println("</script>");
        System.out.println("<a href=\"index.html\"><h5>Tom&rsquo;s Birding Page</h5></a>");
        System.out.println("<hr/>");
        System.out.println("<h2>Recent Bird Sightings from Plum Island</h2>");
        System.out.println("<hr/>");
        System.out.println("");
        System.out.println("<p>");
        System.out.println("Here&rsquo;s a list of recent bird sightings from Plum Island, located in Newburyport, Newbury, Rowley, and Ipswich, Massachusetts.");
        System.out.println("Most sightings are from the Parker River National Wildlife Refuge, which makes up the southern two thirds of the island.");
        System.out.println("This information is only as complete as the reports received.");
        //System.out.println("To contribute your sightings please send them to");
        //System.out.println("<a href=\"mailto:ttw4@verizon.net\">Tom Wetmore</a>.");
        System.out.println("A few reports to eBird are occasionally integrated into this page.");
        System.out.println("</p>");
        System.out.println("");
        System.out.println("<p>");
        System.out.println("See the <a href=\"#legend\">legend</a> after the list for an explanation of");
        System.out.println("terms.");
        System.out.println("You can find most of the locations on the Parker River NWR");
        System.out.println("<a href=\"ParkerRiverMap.pdf\">map</a>.");
        System.out.println("</p>");

        System.out.println("<p>");
        System.out.println("There are " + getNumFullSpecies() + " species currently on the list.");
        System.out.println("The list covers the last " + DAYSTOTRIM + " days.");
        System.out.println("</p>");

        System.out.println("");
        System.out.println("<br clear=\"left\"/>");
        System.out.println("<hr/>");
        System.out.println("");
        System.out.print("<h3 class=\"center\">Recent Bird Sightings from Plum Island &mdash; <i>updated ");
        System.out.print(today.getMonthName() + " " + today.getDay() + ", " +  today.getYear());
        System.out.println("</i></h3>");
    }

    static private int getNumFullSpecies ()
    {
        int count = 0;
        for (Bird bird: allSpecies) if (bird.isSpecies()) count++;
        return count;
    }

    static private void outputTrailer ()
    {
        System.out.println("</table>");
        System.out.println("");
        System.out.println("<hr/>");

        System.out.println("<a name=\"legend\"/>");
        System.out.println("<b>Legend</b>");
        System.out.println("<table class=\"bordered\" cellspacing=\"7\">");
        System.out.println("<tr>");
        System.out.println("<td>");
        System.out.println("<ul>");
        System.out.println("<li>m - male</li>");
        System.out.println("<li>f - female</li>");
        System.out.println("<li>pr - pair</li>");
        System.out.println("<li>fk - flock</li>");
        System.out.println("<li>ad - adult</li>");
        System.out.println("<li>im - immature</li>");
        System.out.println("<li>jv - juvenal</li>");
        System.out.println("<li>sm - small</li>");
        System.out.println("<li>lg - large</li>");
        System.out.println("<li>lt - light morph</li>");
        System.out.println("<li>dk - dark morph</li>");
        System.out.println("<li>n - north</li>");
        System.out.println("<li>s - south</li>");
        System.out.println("<li>e - east</li>");
        System.out.println("<li>w - west</li>");
        System.out.println("<li>inc - including</li>");
        System.out.println("<li>migr - migrating</li>");
        System.out.println("</ul>");
        System.out.println("</td>");
        System.out.println("");
        System.out.println("<td>");
        System.out.println("<br/>");
        System.out.println("</td>");
        System.out.println("");
        System.out.println("<td>");
        System.out.println("<ul>");
        System.out.println("<li>forward - Bill Forward Pool</li>");
        System.out.println("<li>one - Lot one area</li>");
        System.out.println("<li>three - Lot three area</li>");
        System.out.println("<li>seven - Lot seven area</li>");
        System.out.println("<li>emerson - Emerson Rocks</li>");
        System.out.println("<li>cross - Cross Farm Hill area</li>");
        System.out.println("<li>pans - North pans to lot three</li>");
        System.out.println("<li>north field - North boundary field</li>");
        System.out.println("<li>south field - South boundary field</li>");
        System.out.println("<li>north marsh - salt marsh from gate to wardens</li>");
        System.out.println("<li>south marsh - salt marsh from pines to cross</li>");
        System.out.println("<li>stage - Stage Island Pool area</li>");
        System.out.println("<li>pines - Pines Trail area</li>");
        System.out.println("<li>gate - Gate house area</li>");
        System.out.println("<li>blind - Blind on Bill Forward Pool</li>");
        System.out.println("<li>wardens - Sub-headquarters area</li>");
        System.out.println("<li>sound - Plum Island Sound</li>");
        System.out.println("</ul>");
        System.out.println("</td>");
        System.out.println("</tr>");
        System.out.println("</table>");
        System.out.println("<hr/>");
        System.out.println("<!-- Start of StatCounter Code -->");
        System.out.println("<script type=\"text/javascript\" language=\"javascript\">");
        System.out.println("var sc_project=599831; ");
        System.out.println("var sc_partition=4; ");
        System.out.println("var sc_security=\"487be869\"; ");
        System.out.println("</script>");

        System.out.println("<script type=\"text/javascript\" language=\"javascript\" src=\"http://www.statcounter.com/counter/counter.js\"></script><noscript><a href=\"http://www.statcounter.com/\" target=\"_blank\"><img  src=\"http://c5.statcounter.com/counter.php?sc_project=599831&amp;java=0&amp;security=487be869\" alt=\"javascript hit counter\" border=\"0\"></a> </noscript>");
        System.out.println("<!-- End of StatCounter Code -->");
        System.out.println("<br/>");
        System.out.println("<address>");
        System.out.print(today.getMonthName() + " " + today.getDay() + ", " + today.getYear());
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

    static private class Entry implements Comparable
    {
        DayRange dayRange;
        String info;
        String author;

        Entry (DayRange dayRange, String info, String author)
        {
            this.dayRange = dayRange;
            this.info = info;
            this.author = author;
        }

        /** Compare two entries. First order by date, then by authority (but
         *  always make "wetmore" entries sort last).
         */
        public int compareTo (Object object)
        {
            if (!(object instanceof Entry)) return 0;

            /* If the dates are different order by date. */
            Entry that = (Entry) object;
            int thisint = dayRange.toInteger();
            int thatint = that.dayRange.toInteger();
            if (thisint != thatint) return thatint - thisint;

            /* If dates are the same make my records sort after others. */
            if (author.indexOf("wetmore") != -1) return 1;

            /* Sort alphabetically. */
            return author.compareTo(that.author);
        }

        public String getColor (long lastDay)
        {
            long diff = lastDay - dayRange.toLong();
            if (diff < 1) return "lastday";
            if (diff < 7) return "oneweek";
            if (diff < 14) return "twoweek";
            return "threeweek";
        }

        public String toString ()
        {
            StringBuffer buf = new StringBuffer();
            buf.append(dayRange.toString(true, false));
            buf.append(", ");
            if (info != null) {
                buf.append(info);
                buf.append(", ");
            }
            buf.append("<i>");
            buf.append(author);
            buf.append("</i>");
            return buf.toString();
        }
    }
}
