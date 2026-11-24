/**
 * Chooses the DstDml implementation in one place, so another one can replace it without a change to its
 * callers. A class holds it in a @TestVisible private static field that a test sets to DstDmlFake.
 */
public inherited sharing class DstDmlProvider {
    public static DstDml get() {
        return new DstDatabaseDml();
    }
}
