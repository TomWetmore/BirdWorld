// BirdHandler.java

package com.bartonstreet.birds;

import com.bartonstreet.util.*;
import com.bartonstreet.util.Stack;
import com.bartonstreet.io.*;
import java.io.IOException;
import java.util.*;

/** Instances of this class provide an interface to bird factories that use a
 *    particular set of files to provide the bird codes, species, forms, and
 *    groups...
 *
 *    @author Tom Wetmore
 *    @version 2008.06.03
 */
public class BirdHandler
{
    /** The underlying bird factory. */
    private BirdFactory factory;

    private boolean initialized = false;

    Stack birdStack = new Stack();

    /** Maps all Strings that can be used to name birds to Birds. */
    private Map<String, Bird> birdStrings = new HashMap<String, Bird>();

    /** The full set of all Strings that can name birds. */
    private Set<String> allStrings = new HashSet<String>();

    /** Construct a new bird handler instance.    This creates an underlying bird
     *    factory with the auto genera creation option set to false and the keep
     *    species ordered option set to true.
     */
    public BirdHandler ()
    {
        factory = new BirdFactory();
        factory.setKeepSpeciesOrdered(true);
    }

    /** Initialize this bird handler by reading all the code, species, form,
     *    and group data from three separate colon files.     Note that only species
     *    information is required.
     *
     *    @param taxa the name of the file holding species information.
     *    @param forms the name of the file holding form information.
     *    @param groups the name of the file holding group information.
     */
    public boolean initialize (String taxa, String forms, String groups)
    {
        return initialize(taxa, forms, groups, null);
    }

    public boolean initialize (String taxa, String forms)
    {
        return initialize(taxa, forms, null, null);
    }
    public boolean initialize (String taxa)
    {
        return initialize(taxa, null, null, null);
    }

    public boolean initialize (String taxa, String forms, String groups,
        String abbvs)
    {
        if (initialized) return false;
        initialized = true;

        if (taxa == null)
            throw new IllegalArgumentException("no taxa information file");

        ColonFile taxafile;
        ColonFile formsfile = null;
        ColonFile groupsfile = null;
        ColonFile abbvsfile = null;

        try {
            taxafile = new ColonFile(taxa);
            if (forms != null) formsfile = new ColonFile(forms);
            if (groups != null) groupsfile = new ColonFile(groups);
            if (abbvs != null) abbvsfile = new ColonFile(abbvs);

            handleTaxa(taxafile);
            if (forms != null) handleForms(formsfile);
            if (groups != null) handleGroups(groupsfile);
            if (abbvs != null) handleAbbvs(abbvsfile);

            return true;

        } catch (Exception e) {
            System.out.println(e.getMessage());
            throw new IllegalArgumentException(e.getMessage());
        }
    }

    /** Process a file of taxa information.     Each line is read and a specific
     *    handler called for each type of line.
     *
     *    @param file the file holding the taxa information.
     *    @return returns true iff the species file could be processed.
     */
    private boolean handleTaxa (ColonFile file) throws IOException,
        ColonFileException
    {
        /* Iterate through each line of the bird taxa file. */
        for (List fields = file.getFields(); fields != null;
             fields = file.getFields()) {

            String first = (String) fields.get(0);
            if (first.equals("order"))
                handleHigherTaxon(fields, Bird.ORDER, file);
            else if (first.equals("family"))
                handleHigherTaxon(fields, Bird.FAMILY, file);
            else if (first.equals("subfamily"))
                handleHigherTaxon(fields, Bird.SUBFAMILY, file);
            else if (first.equals("genus"))
                handleHigherTaxon(fields, Bird.GENUS, file);
            else
                handleSpecies(fields, file);
        }
        return true;
    }

    /** Handle an order, family, subfamily, or genus line.
     *
     *    @param fields the fields from a colon file for the taxon.
     *  @param level the level of the taxon.
     */
    private void handleHigherTaxon (List fields, int level, ColonFile file)
    {
        // Pop the bird stack to the level of the new taxon.
        popToLevel(birdStack, level);

        // Check that the official name has one component.
        String name = (String) fields.get(1);
        StringTokenizer izer = new StringTokenizer(name, " ");
        if (izer.countTokens() != 1) {
            System.out.println("error in taxa file: line " +
                file.getLineNumber());
            throw new IllegalArgumentException();
        }

        // Use the bird factory to create the taxon object.
        Bird taxon = factory.createHigherTaxon(name, level);

        // Assign a parent to the taxon and adjust the stack.
        Bird parent = (Bird) birdStack.top();
        taxon.setParent(parent);
        if (parent != null) parent.addChild(taxon);
        birdStack.push(taxon);
    }

    /** Handle a species line from the taxa file.
     *
     *  @param fields the fields from a colon file for the taxon.
     *  @param file the colon taxa file.
     */
    private void handleSpecies (List fields, ColonFile file)
    {
        // Check that the bird code has four letters.
        String code = (String) fields.get(0);
        if (code.length() != 4 || !isupper(code.charAt(0)) ||
            !isletter(code.charAt(1)) || !isletter(code.charAt(2)) ||
            !isletter(code.charAt(3))) {
                System.out.println("error in species file: line " +
                    file.getLineNumber() + ": illegal code " + code);
                throw new IllegalArgumentException();
        }
        String comname = (String) fields.get(1);

        // Check that the offical name has two words.
        String offname = (String) fields.get(2);
        StringTokenizer izer = new StringTokenizer(offname, " ");
        if (izer.countTokens() != 2) {
            System.out.println("error in species file: line " +
                file.getLineNumber() + ": illegal official name");
            throw new IllegalArgumentException();
        }

        String bcode = null;
        if (fields.size() >= 4) bcode = (String) fields.get(3);

        // Use the bird factory to create a bird species.
        Bird species = factory.createSpecies(code, comname, offname, bcode);

        // Assign a parent to the new species and adjust the stack.
        popToLevel(birdStack, Bird.SPECIES);
        Bird parent = (Bird) birdStack.top();
        species.setParent(parent);
        if (parent != null) parent.addChild(species);
        birdStack.push(species);
    }

    /** Process a file of foms information.     Each line must contain a code, an
     *    optional common name, and an optional official name.  The code must
     *    consist of a known species code, a dot, and a two letter form code.     At
     *    least one of the common or official name must be provided.    If there is
     *    an official name, it must be the subspecies epithet of the species.
     *
     *    @param file the file holding the species information.
     *    @return returns true iff the species file could be processed.
     */
    private boolean handleForms (ColonFile file) throws IOException,
        ColonFileException
    {
        List fields = file.getFields();

        /* Iterate through each line of the bird codes file. */
        while (fields != null) {

            /* Check that the line has at least two fields. */
            int n = fields.size();
            if (n != 2 && n != 3) {
                System.out.println("error in forms file: line " +
                    file.getLineNumber());
                throw new IllegalArgumentException();
            }

            /* Check that the bird code meets syntax rules. */
            String code = (String) fields.get(0);
            if (code.length() != 7 || code.charAt(4) != '.' ||
                !islower(code.charAt(5)) || !islower(code.charAt(6))) {
                System.out.println("error in forms file: line " +
                    file.getLineNumber() + ": bad syntax");
                throw new IllegalArgumentException();
            }

            String scode = code.substring(0, 4);
            String fcode = code.substring(5, 7);

    System.out.println("scode, fcode = " + scode + ", " + fcode);

            // LOTS OF MISSING STUFF

            fields = file.getFields();
        }
        return true;
    }

    /** Process a file of group information.  Each line must contain a code, a
     *    common name, and a list of species codes and official taxa names.
     *
     *    @param file the file holding the group information.
     *    @return returns true iff the group file could be processed.
     */
    private void handleGroups (ColonFile file) throws IOException,
        ColonFileException
    {
        List fields = file.getFields();
        int line = file.getLineNumber();

        /* Iterate through each line of the bird codes file. */
        while (fields != null) {

            /* Check that the line has three fields. */
            int n = fields.size();
            if (n != 3) {
                System.out.println("group file error: line " + line +
                    ": bad syntax");
                throw new IllegalArgumentException();
            }

            /* Check that the group code has four letters. */
            String code = (String) fields.get(0);
            if (code == null || code.length() != 4 ||
                !islower(code.charAt(0)) || !isletter(code.charAt(1)) ||
                !isletter(code.charAt(2)) || !isletter(code.charAt(3))) {
                    System.out.println("group file error: line " + line +
                        ": bad code");
                    throw new IllegalArgumentException();
            }

            /* Get the common name for the group. */
            String commonName = (String) fields.get(1);
            if (commonName == null) {
                System.out.println("group file error: line " + line +
                    ": bad common name");
                throw new IllegalArgumentException();
            }

            /* Get the contents of the group. */
            String contents = (String) fields.get(2);
            if (contents == null) {
                System.out.println ("group file error: line " + line +
                    ": group has no contents");
                throw new IllegalArgumentException();
            }

            /* Iterate through the contents of the group. */
            StringTokenizer izer = new StringTokenizer(contents, ",");
            List<String> children = new ArrayList<String>(1);
            while (izer.hasMoreElements()) {
                String token = izer.nextToken().trim();
                children.add(token);
            }

            /* Convert the list of children from a list of species codes and
             * higher level taxa names, into a list of species taxa. */
            List<Bird> childBirds = resolveGroupChildren(children);

            /* Use the factory to create the group taxon. */
            factory.createGroup(code, commonName, childBirds);
            fields = file.getFields();
            line = file.getLineNumber();
        }
    }

    /** Convert a list of species codes and higher level taxa official names
     *    into a list of bird species taxa.  This may involve recursing down
     *    through layers of higher level taxa until the species level is reached.
     *
     *    @param children a list of species codes and higher level taxa names.
     *    @return returns the list of resolved species taxa.
     */
    private List<Bird> resolveGroupChildren (List<String> children)
    {
        /* Set of all resolved species codes (not taxa). */
        Set<String> speciesSet = new TreeSet<String>();

        /* Iteratively handle each member of the original list. */
        int size = children.size();
        for (int i = 0; i < size; i++) {
            String name = children.get(i);
            Bird bird = factory.getSpeciesByCode(name);
            if (bird == null)
                bird = factory.getTaxonByOfficialName(name);
            if (bird != null)
                addTaxon(bird, speciesSet);
            else
                System.out.println("group content: " + name + ": unknown");
        }

        /* Create the list of species taxa from the species codes that were
         * accumulated into the species set. */
        List<Bird> newChildren = new ArrayList<Bird>(speciesSet.size());
        for (String code: speciesSet) {
            Bird species = factory.getSpeciesByCode(code);
            newChildren.add(species);
        }
        return newChildren;
    }

    /** Add a bird taxon to a set of species codes.     If the original taxon is a
     *    species the species code is added directly.     If the original taxon is a
     *    higher level taxon, this method is called recursively on each of the
     *    taxon's children taxa.
     *
     *    @param bird a species or higher level (non group) bird taxon.
     *    @param speciesSet the set to add the species codes to.
     */
    public void addTaxon (Bird bird, Set<String> speciesSet)
    {
        /* Handle case where bird is a species. */
        if (bird.isSpecies()) {
            String code = bird.getCode();
            if (speciesSet.contains(code)) return;
            speciesSet.add(code);
            return;
        }

        /* Handle the error case where the taxon is not a higher level taxon. */
        if (bird.isGroup() || bird.isForm())
            throw new IllegalArgumentException(
                "groups can't hold groups or forms");

        /* Handle case where bird is a higher level taxon. */
        List children = bird.getChildren();
        if (children == null || children.size() <= 0)
            throw new IllegalArgumentException(
                "high level taxon must have children");

        /* Recurse a level deeper on the children of the higher level taxon. */
        for (int i = 0; i < children.size(); i++) {
            Bird child = (Bird) children.get(i);
            addTaxon(child, speciesSet);
        }
    }

    private void handleAbbvs (ColonFile file)
    {
        List fields;
        int line;

        try {
            fields = file.getFields();
            line = file.getLineNumber();
        } catch (Exception e) {
            throw new IllegalArgumentException(e.getMessage());
        }

        /* Iterate through each line of the bird name abbreviations file. */
        while (fields != null) {
            if (fields.size() != 2) {
                System.out.println("line " + line + ": bad abbreviation");
            }

            String code = (String) fields.get(0);
            String defn = (String) fields.get(1);

            TextPattern pattern = new TextPattern(defn);
            TextPattern.Node root;
            try {
                root = pattern.parse();
            } catch (TextPattern.SourceException e) {
                System.out.println(e.getMessage());
                throw new IllegalArgumentException(e.getMessage());
            }

            Bird bird = getSpeciesByCode(code);
            if (bird == null) {
                System.out.println("line: " + line + ": " + code +
                    ": is not a bird code");
                throw new IllegalArgumentException("illegal bird code");
            }
            Set<String> strings = root.genStringSet();
            strings = squeezeSpaces(strings);

            // See if any of the strings have been seen before
            for (String string: strings) {
                if (allStrings.contains(string)) {
                    System.out.println("String " + string + " is a dupe");
                    throw new IllegalArgumentException("duplicate");
                } else {
                    allStrings.add(string);
                    birdStrings.put(string, bird);
                }
            }
            try {
                fields = file.getFields();
                line = file.getLineNumber();
            } catch (Exception e) {
                throw new IllegalArgumentException(e.getMessage());
            }
        }
    }

    /** Squeeze the spaces out of a set of Strings. */
    static Set<String> squeezeSpaces (Set<String> set)
    {
        Set<String> squeezed = new TreeSet<String>();
        for (String string: set) {
            squeezed.add(squeezeSpaces(string));
        }
        return squeezed;
    }

    /** Squeeze the spaces out of a String. */
    static String squeezeSpaces (String string)
    {
        StringBuffer buf = new StringBuffer();
        for (int i = 0, n = string.length(); i < n; i++) {
            if (string.charAt(i) != ' ') {
                buf.append(string.charAt(i));
            }
        }
        return buf.toString();
    }

    public int getNumSpecies ()
    {
        return factory.getNumSpecies();
    }

    /** Get a bird species from name or code; delegate to the factory.
     */
    public Bird getSpecies (String key)
    {
        return factory.getSpecies(key);
    }

    public Bird getSpecies (int index)
    {
        return factory.getSpecies(index);
    }

    public Bird getSpeciesByCode (String code)
    {
        return factory.getSpeciesByCode(code);
    }

    public Bird getSpeciesByBandingCode (String code)
    {
        return factory.getSpeciesByBandingCode(code);
    }

    public Bird getSpeciesByName (String name)
    {
        Bird bird = factory.getSpeciesByName(name);
        if (bird != null) return bird;
        if (birdStrings.size() == 0) return null;
        name = prepareString(name);
        return (Bird) birdStrings.get(name);

    }

    static public String prepareString (String in)
    {
        StringBuffer out = new StringBuffer();
        for (int i = 0, n = in.length(); i < n; i++) {
            char c = in.charAt(i);
            if (!Character.isLetter(c)) continue;
            out.append(c);
        }
        return out.toString().toLowerCase();
    }


    public Bird getSpeciesByOfficialName (String name)
    {
        return factory.getSpeciesByOfficialName(name);
    }

    public Bird getSpeciesByCommonName (String name)
    {
        return factory.getSpeciesByCommonName(name);
    }

    public Bird getGroup (String key)
    {
        return factory.getGroup(key);
    }

    public Bird getGroupByCode (String code)
    {
        return factory.getGroupByCode(code);
    }

    public Bird getGroupByName (String key)
    {
        return factory.getGroupByName(key);
    }

    public int getSpeciesOrder (String key)
    {
        return factory.getSpeciesOrder(key);
    }

    /** Get a bird genus from the genus name; delegate to the factory.
     */
    public Bird getGenus (String gname)
    {
        return factory.getGenus(gname);
    }

    public SpeciesCodeComparator getSpeciesCodeComparator ()
    {
        return factory.getSpeciesCodeComparator();
    }

    static private boolean islower (char c)
    {
        return Character.isLowerCase(c);
    }

    static private boolean isupper (char c)
    {
        return Character.isUpperCase(c);
    }

    static private boolean isletter (char c)
    {
        return Character.isLetter(c);
    }

    public void popToLevel (Stack stack, int level)
    {
        Bird taxon = (Bird) stack.top();
        while (taxon != null && taxon.getLevel() <= level) {
            stack.pop();
            taxon = (Bird) stack.top();
        }
    }

    /** Return the bird taxon with the given official name, if any.     Return null
     *    if no such bird taxon exists.  Delegate to the underlying bird factory.
     *
     *    @param officialName the official name of some bird taxon.
     *    @return return the bird taxon with the given official name, if any.
     */
    public Bird getTaxonByOfficialName (String officialName)
    {
        return factory.getTaxonByOfficialName(officialName);
    }

    // DEBUG METHODS //

    /** Test this class by reading some simple files and seeing what happens.
     */
    static public void main (String[] args)
    {
        BirdHandler handler = new BirdHandler();
        handler.initialize("resources/taxa", null,
            "resources/groups");

        Bird bird = handler.getTaxonByOfficialName("Gavia immer");
        System.out.println(bird);
        bird = handler.getTaxonByOfficialName("Gavia");
        System.out.println(bird);
        bird = handler.getTaxonByOfficialName("Gaviidae");
        System.out.println(bird);
        bird = handler.getTaxonByOfficialName("Gaviiformes");
        System.out.println(bird);
    }
}
