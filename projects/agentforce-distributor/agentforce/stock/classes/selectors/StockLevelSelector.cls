/**
 * All SOQL for Stock_Level__c. Runs in user mode.
 */
public inherited sharing class StockLevelSelector {
    /** Stock rows of the given products in active warehouses, grouped by product, warehouses in code order. */
    public static Map<Id, List<Stock_Level__c>> selectInActiveWarehousesByProduct(Set<Id> productIds) {
        Map<Id, List<Stock_Level__c>> byProduct = new Map<Id, List<Stock_Level__c>>();
        if (productIds.isEmpty()) {
            return byProduct;
        }
        for (Stock_Level__c level : [
            SELECT Product__c, Quantity_On_Hand__c, Quantity_Available__c, Warehouse__r.Code__c, Warehouse__r.Name, Warehouse__r.City__c
            FROM Stock_Level__c
            WHERE Product__c IN :productIds AND Warehouse__r.Is_Active__c = TRUE
            WITH USER_MODE
            ORDER BY Warehouse__r.Code__c
        ]) {
            if (!byProduct.containsKey(level.Product__c)) {
                byProduct.put(level.Product__c, new List<Stock_Level__c>());
            }
            byProduct.get(level.Product__c).add(level);
        }
        return byProduct;
    }
}
