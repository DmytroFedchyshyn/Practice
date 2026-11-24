@IsTest
private class ProductMatcherTest {
    private static final List<String> CODES = new List<String>{ 'DST-1001', 'DST-1002', 'DST-2001' };
    private static final List<String> NAMES = new List<String>{
        'Cordless Drill 18V',
        'Angle Grinder 125 mm',
        'Socket Set 94 pcs'
    };

    @IsTest
    static void exactCodeWinsOverNameMatches() {
        List<String> names = new List<String>{ 'Cordless Drill 18V', 'Adapter for DST-1001' };
        List<String> codes = new List<String>{ 'DST-1001', 'DST-9000' };

        Assert.areEqual(new List<Integer>{ 0 }, ProductMatcher.match(codes, names, ' dst-1001 '));
    }

    @IsTest
    static void fallsBackToPartOfTheName() {
        Assert.areEqual(new List<Integer>{ 1 }, ProductMatcher.match(CODES, NAMES, 'grinder'));
        Assert.areEqual(new List<Integer>{ 0, 1, 2 }, ProductMatcher.match(CODES, NAMES, 'e'));
    }

    @IsTest
    static void blankOrUnknownTermsMatchNothing() {
        Assert.isTrue(ProductMatcher.match(CODES, NAMES, ' ').isEmpty());
        Assert.isTrue(ProductMatcher.match(CODES, NAMES, null).isEmpty());
        Assert.isTrue(ProductMatcher.match(CODES, NAMES, 'flux capacitor').isEmpty());
    }

    @IsTest
    static void containsPatternEscapesWildcards() {
        Assert.areEqual('%drill%', ProductMatcher.containsPattern(' drill '));
        Assert.areEqual('%100\\%%', ProductMatcher.containsPattern('100%'));
        Assert.areEqual('%a\\_b%', ProductMatcher.containsPattern('a_b'));
    }
}
