/**
 * Finds products the way a partner names them: an exact product code wins; otherwise every
 * product whose name contains the text. Used for the catalogue (stock) and for order lines (returns).
 */
public with sharing class ProductMatcher {
    /**
     * @param codes product codes, one per candidate
     * @param names product names, same order as codes
     * @return positions of the matching candidates; empty for a blank term
     */
    public static List<Integer> match(List<String> codes, List<String> names, String term) {
        List<Integer> positions = new List<Integer>();
        if (String.isBlank(term)) {
            return positions;
        }
        String trimmed = term.trim();
        for (Integer i = 0; i < codes.size(); i++) {
            if (trimmed.equalsIgnoreCase(codes[i])) {
                positions.add(i);
            }
        }
        if (!positions.isEmpty()) {
            return positions;
        }
        for (Integer i = 0; i < names.size(); i++) {
            if (names[i] != null && names[i].containsIgnoreCase(trimmed)) {
                positions.add(i);
            }
        }
        return positions;
    }

    /** LIKE pattern for "name contains", with % and _ typed by the partner taken literally. */
    public static String containsPattern(String term) {
        return '%' + term.trim().replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') + '%';
    }
}
