/**
 * Stock availability per product and warehouse, from the CRM snapshot in Stock_Level__c.
 * Only active warehouses count. Data Cloud adds the ERP view of stock in phase 3.
 *
 * A product is found by exact product code first, then by part of its name. When a name
 * fragment matches too many products the result asks for something more specific instead
 * of dumping the catalogue on the partner.
 *
 * Bulk-safe: two queries per call, whatever the number of lookups.
 */
public with sharing class StockAvailabilityService {
    @TestVisible
    private static final Integer MAX_MATCHES = 5;

    public class StockResult {
        public Boolean success = false;
        public String errorCode;
        public String message;
        public List<ProductStock> products = new List<ProductStock>();
    }

    public class ProductStock {
        public String productCode;
        public String productName;
        public Integer totalAvailable = 0;
        public List<WarehouseStock> warehouses = new List<WarehouseStock>();
    }

    public class WarehouseStock {
        public String warehouseCode;
        public String warehouseName;
        public String city;
        public Integer available;
        public Integer onHand;
    }

    /**
     * @param productTerms product code or part of a product name, one per lookup
     * @return one result per term, in the same order
     */
    public static List<StockResult> checkStock(List<String> productTerms) {
        Set<String> codes = new Set<String>();
        List<String> namePatterns = new List<String>();
        for (String term : productTerms) {
            if (String.isNotBlank(term)) {
                codes.add(term.trim());
                namePatterns.add('%' + escapeLike(term.trim()) + '%');
            }
        }

        List<Product2> candidates = new List<Product2>();
        if (!codes.isEmpty()) {
            candidates = [
                SELECT Id, ProductCode, Name
                FROM Product2
                WHERE IsActive = TRUE AND (ProductCode IN :codes OR Name LIKE :namePatterns)
                WITH USER_MODE
                ORDER BY ProductCode
            ];
        }

        List<List<Product2>> matchesPerTerm = new List<List<Product2>>();
        Set<Id> productIds = new Set<Id>();
        for (String term : productTerms) {
            List<Product2> matches = match(candidates, term);
            matchesPerTerm.add(matches);
            if (!matches.isEmpty() && matches.size() <= MAX_MATCHES) {
                for (Product2 product : matches) {
                    productIds.add(product.Id);
                }
            }
        }

        Map<Id, List<Stock_Level__c>> stockByProduct = new Map<Id, List<Stock_Level__c>>();
        if (!productIds.isEmpty()) {
            for (Stock_Level__c level : [
                SELECT Product__c, Quantity_On_Hand__c, Quantity_Available__c, Warehouse__r.Code__c, Warehouse__r.Name, Warehouse__r.City__c
                FROM Stock_Level__c
                WHERE Product__c IN :productIds AND Warehouse__r.Is_Active__c = TRUE
                WITH USER_MODE
                ORDER BY Warehouse__r.Code__c
            ]) {
                if (!stockByProduct.containsKey(level.Product__c)) {
                    stockByProduct.put(level.Product__c, new List<Stock_Level__c>());
                }
                stockByProduct.get(level.Product__c).add(level);
            }
        }

        List<StockResult> results = new List<StockResult>();
        for (Integer i = 0; i < productTerms.size(); i++) {
            String term = productTerms[i];
            List<Product2> matches = matchesPerTerm[i];
            StockResult result = new StockResult();
            results.add(result);

            if (String.isBlank(term)) {
                result.errorCode = 'PRODUCT_REQUIRED';
                result.message = 'Give a product code or part of the product name.';
            } else if (matches.isEmpty()) {
                result.errorCode = 'PRODUCT_NOT_FOUND';
                result.message = 'No active product matches "' + term.trim() + '".';
            } else if (matches.size() > MAX_MATCHES) {
                result.errorCode = 'AMBIGUOUS_PRODUCT';
                result.message =
                    '"' +
                    term.trim() +
                    '" matches ' +
                    matches.size() +
                    ' products. Ask for the product code or a more specific name. Matches: ' +
                    names(matches) +
                    '.';
            } else {
                for (Product2 product : matches) {
                    result.products.add(toProductStock(product, stockByProduct.get(product.Id)));
                }
                result.success = true;
                result.message = 'Stock found for ' + matches.size() + ' product(s).';
            }
        }
        return results;
    }

    /** Exact product code wins; otherwise every product whose name contains the term. */
    private static List<Product2> match(List<Product2> candidates, String term) {
        List<Product2> matches = new List<Product2>();
        if (String.isBlank(term)) {
            return matches;
        }
        String trimmed = term.trim();
        for (Product2 product : candidates) {
            if (trimmed.equalsIgnoreCase(product.ProductCode)) {
                matches.add(product);
            }
        }
        if (!matches.isEmpty()) {
            return matches;
        }
        for (Product2 product : candidates) {
            if (product.Name.containsIgnoreCase(trimmed)) {
                matches.add(product);
            }
        }
        return matches;
    }

    private static ProductStock toProductStock(Product2 product, List<Stock_Level__c> levels) {
        ProductStock stock = new ProductStock();
        stock.productCode = product.ProductCode;
        stock.productName = product.Name;
        if (levels == null) {
            return stock;
        }
        for (Stock_Level__c level : levels) {
            WarehouseStock warehouse = new WarehouseStock();
            warehouse.warehouseCode = level.Warehouse__r.Code__c;
            warehouse.warehouseName = level.Warehouse__r.Name;
            warehouse.city = level.Warehouse__r.City__c;
            warehouse.onHand = level.Quantity_On_Hand__c == null ? 0 : level.Quantity_On_Hand__c.intValue();
            warehouse.available = level.Quantity_Available__c == null ? 0 : level.Quantity_Available__c.intValue();
            stock.totalAvailable += warehouse.available;
            stock.warehouses.add(warehouse);
        }
        return stock;
    }

    private static String names(List<Product2> products) {
        List<String> labels = new List<String>();
        for (Product2 product : products) {
            labels.add(product.Name + ' (' + product.ProductCode + ')');
        }
        return String.join(labels, ', ');
    }

    /** Treat % and _ typed by the partner as literal characters, not LIKE wildcards. */
    private static String escapeLike(String value) {
        return value.replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_');
    }
}
