/**
 * All SOQL for Return_Request__c. Runs in user mode.
 */
public inherited sharing class ReturnRequestSelector {
    /**
     * Quantity already requested per order line, ignoring requests in the given statuses.
     * @return totals keyed by ReturnRequestSelector.key(orderId, productId)
     */
    public static Map<String, Decimal> sumQuantityByOrderAndProduct(List<Order> orders, Set<String> ignoredStatuses) {
        Map<String, Decimal> totals = new Map<String, Decimal>();
        if (orders.isEmpty()) {
            return totals;
        }
        for (AggregateResult row : [
            SELECT Order__c orderId, Product__c productId, SUM(Quantity__c) total
            FROM Return_Request__c
            WHERE Order__c IN :orders AND Status__c NOT IN :ignoredStatuses
            WITH USER_MODE
            GROUP BY Order__c, Product__c
        ]) {
            totals.put(key((Id) row.get('orderId'), (Id) row.get('productId')), (Decimal) row.get('total'));
        }
        return totals;
    }

    public static Map<Id, Return_Request__c> selectByIds(Set<Id> requestIds) {
        if (requestIds.isEmpty()) {
            return new Map<Id, Return_Request__c>();
        }
        return new Map<Id, Return_Request__c>([SELECT Id, Name, Status__c FROM Return_Request__c WHERE Id IN :requestIds WITH USER_MODE]);
    }

    public static String key(Id orderId, Id productId) {
        return String.valueOf(orderId) + ':' + String.valueOf(productId);
    }
}
