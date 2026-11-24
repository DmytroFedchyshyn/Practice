/**
 * All SOQL for Product2. Runs in user mode.
 */
public inherited sharing class ProductSelector {
    /** Active products whose code is in the set or whose name matches one of the LIKE patterns. */
    public static List<Product2> selectActiveByCodesOrNames(Set<String> codes, List<String> namePatterns) {
        if (codes.isEmpty() && namePatterns.isEmpty()) {
            return new List<Product2>();
        }
        return [
            SELECT Id, ProductCode, Name
            FROM Product2
            WHERE IsActive = TRUE AND (ProductCode IN :codes OR Name LIKE :namePatterns)
            WITH USER_MODE
            ORDER BY ProductCode
        ];
    }
}
