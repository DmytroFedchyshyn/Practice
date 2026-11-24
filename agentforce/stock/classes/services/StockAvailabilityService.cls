/**
 * Stock availability per product and warehouse, from the CRM snapshot in Stock_Level__c.
 * Only active warehouses count. Data Cloud adds the ERP view of stock in phase 3.
 *
 * When a name fragment matches too many products the result asks for something more
 * specific instead of dumping the catalogue on the partner.
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
                namePatterns.add(ProductMatcher.containsPattern(term));
            }
        }
        List<Product2> candidates = ProductSelector.selectActiveByCodesOrNames(codes, namePatterns);
        List<String> candidateCodes = new List<String>();
        List<String> candidateNames = new List<String>();
        for (Product2 product : candidates) {
            candidateCodes.add(product.ProductCode);
            candidateNames.add(product.Name);
        }

        List<List<Product2>> matchesPerTerm = new List<List<Product2>>();
        Set<Id> productIds = new Set<Id>();
        for (String term : productTerms) {
            List<Product2> matches = new List<Product2>();
            for (Integer position : ProductMatcher.match(candidateCodes, candidateNames, term)) {
                matches.add(candidates[position]);
            }
            matchesPerTerm.add(matches);
            if (matches.size() <= MAX_MATCHES) {
                for (Product2 product : matches) {
                    productIds.add(product.Id);
                }
            }
        }
        Map<Id, List<Stock_Level__c>> stockByProduct = StockLevelSelector.selectInActiveWarehousesByProduct(productIds);

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
}
