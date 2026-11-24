/**
 * All SOQL for Order. Runs in user mode, so the caller's object, field and record access applies.
 */
public inherited sharing class OrderSelector {
    public static final Integer RECENT_ORDER_LIMIT = 10;

    private static final String FIELDS_WITH_LINES =
        'SELECT Id, AccountId, OrderNumber, EffectiveDate, Fulfillment_Status__c, Expected_Delivery_Date__c, ' +
        'Delivered_Date__c, Tracking_Number__c, Fulfillment_Warehouse__r.Name, TotalAmount, ' +
        '(SELECT Product2Id, Product2.ProductCode, Product2.Name, Quantity, UnitPrice FROM OrderItems ORDER BY OrderItemNumber) ' +
        'FROM Order ';

    /** Orders with their lines, matched by number but only among the given partners' orders. */
    public static List<Order> selectWithLinesByNumbers(Set<String> orderNumbers, Set<Id> accountIds) {
        if (orderNumbers.isEmpty() || accountIds.isEmpty()) {
            return new List<Order>();
        }
        return Database.queryWithBinds(
            FIELDS_WITH_LINES + 'WHERE OrderNumber IN :orderNumbers AND AccountId IN :accountIds',
            new Map<String, Object>{ 'orderNumbers' => orderNumbers, 'accountIds' => accountIds },
            AccessLevel.USER_MODE
        );
    }

    public static List<Order> selectWithLinesByIds(Set<Id> orderIds) {
        if (orderIds.isEmpty()) {
            return new List<Order>();
        }
        return Database.queryWithBinds(FIELDS_WITH_LINES + 'WHERE Id IN :orderIds', new Map<String, Object>{ 'orderIds' => orderIds }, AccessLevel.USER_MODE);
    }

    /** Ids of each partner's most recent orders, newest first, at most RECENT_ORDER_LIMIT per partner. */
    public static Map<Id, List<Id>> selectRecentIdsByAccount(Set<Id> accountIds) {
        Map<Id, List<Id>> idsByAccount = new Map<Id, List<Id>>();
        if (accountIds.isEmpty()) {
            return idsByAccount;
        }
        // A parent-child subquery applies the limit per account, which a flat query cannot do.
        for (Account partner : [
            SELECT Id, (SELECT Id FROM Orders ORDER BY EffectiveDate DESC, OrderNumber DESC LIMIT :RECENT_ORDER_LIMIT)
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ]) {
            List<Id> ids = new List<Id>();
            for (Order record : partner.Orders) {
                ids.add(record.Id);
            }
            idsByAccount.put(partner.Id, ids);
        }
        return idsByAccount;
    }
}
