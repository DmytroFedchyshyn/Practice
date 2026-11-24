/**
 * Read access to a partner's orders: one order by number, or the partner's most recent orders.
 *
 * Every lookup is scoped to the partner account passed in. An order number that belongs to
 * another partner gets the same answer as one that does not exist, so the agent cannot be used
 * to probe other partners' orders.
 *
 * Bulk-safe: a call makes at most three queries, whatever the number of lookups.
 */
public with sharing class PartnerOrderService {
    private static final Integer ORDER_NUMBER_LENGTH = 8;

    public class OrderLookup {
        public Id accountId;
        /** Order number as the partner typed it; blank means "most recent orders". */
        public String orderNumber;

        public OrderLookup(Id accountId, String orderNumber) {
            this.accountId = accountId;
            this.orderNumber = orderNumber;
        }
    }

    public class OrderResult {
        public Boolean success = false;
        public String errorCode;
        public String message;
        public List<OrderSummary> orders = new List<OrderSummary>();
    }

    public class OrderSummary {
        public String orderNumber;
        public Date placedOn;
        public String fulfillmentStatus;
        public Date expectedDeliveryDate;
        public Date deliveredDate;
        public String trackingNumber;
        public String warehouse;
        public Decimal totalAmount;
        public List<OrderLine> lines = new List<OrderLine>();
    }

    public class OrderLine {
        public String productCode;
        public String productName;
        public Decimal quantity;
        public Decimal unitPrice;
    }

    public static List<OrderResult> getOrders(List<OrderLookup> lookups) {
        Set<Id> numberedAccounts = new Set<Id>();
        Set<String> numbers = new Set<String>();
        Set<Id> recentAccounts = new Set<Id>();
        for (OrderLookup lookup : lookups) {
            if (lookup.accountId == null) {
                continue;
            }
            String orderNumber = normalizeOrderNumber(lookup.orderNumber);
            if (orderNumber == null) {
                recentAccounts.add(lookup.accountId);
            } else {
                numberedAccounts.add(lookup.accountId);
                numbers.add(orderNumber);
            }
        }

        Map<String, Id> orderIdByAccountAndNumber = new Map<String, Id>();
        if (!numbers.isEmpty()) {
            for (Order record : [
                SELECT Id, AccountId, OrderNumber
                FROM Order
                WHERE OrderNumber IN :numbers AND AccountId IN :numberedAccounts
                WITH USER_MODE
            ]) {
                orderIdByAccountAndNumber.put(accountKey(record.AccountId, record.OrderNumber), record.Id);
            }
        }

        Map<Id, List<Id>> recentIdsByAccount = new Map<Id, List<Id>>();
        if (!recentAccounts.isEmpty()) {
            // A parent-child subquery applies the limit per account, which a flat query cannot do.
            for (Account partner : [
                SELECT Id, (SELECT Id FROM Orders ORDER BY EffectiveDate DESC, OrderNumber DESC LIMIT 10)
                FROM Account
                WHERE Id IN :recentAccounts
                WITH USER_MODE
            ]) {
                List<Id> ids = new List<Id>();
                for (Order record : partner.Orders) {
                    ids.add(record.Id);
                }
                recentIdsByAccount.put(partner.Id, ids);
            }
        }

        Set<Id> orderIds = new Set<Id>(orderIdByAccountAndNumber.values());
        for (List<Id> ids : recentIdsByAccount.values()) {
            orderIds.addAll(ids);
        }
        Map<Id, Order> details = new Map<Id, Order>();
        if (!orderIds.isEmpty()) {
            details = new Map<Id, Order>(
                [
                    SELECT
                        Id,
                        OrderNumber,
                        EffectiveDate,
                        Fulfillment_Status__c,
                        Expected_Delivery_Date__c,
                        Delivered_Date__c,
                        Tracking_Number__c,
                        Fulfillment_Warehouse__r.Name,
                        TotalAmount,
                        (SELECT Product2.ProductCode, Product2.Name, Quantity, UnitPrice FROM OrderItems ORDER BY OrderItemNumber)
                    FROM Order
                    WHERE Id IN :orderIds
                    WITH USER_MODE
                ]
            );
        }

        List<OrderResult> results = new List<OrderResult>();
        for (OrderLookup lookup : lookups) {
            OrderResult result = new OrderResult();
            results.add(result);
            if (lookup.accountId == null) {
                result.errorCode = 'MISSING_ACCOUNT';
                result.message = 'The partner account is not known, so orders cannot be looked up.';
                continue;
            }

            String orderNumber = normalizeOrderNumber(lookup.orderNumber);
            if (orderNumber != null) {
                Id orderId = orderIdByAccountAndNumber.get(accountKey(lookup.accountId, orderNumber));
                if (orderId == null || !details.containsKey(orderId)) {
                    result.errorCode = 'ORDER_NOT_FOUND';
                    result.message = 'No order ' + orderNumber + ' was found for this partner.';
                    continue;
                }
                result.orders.add(summarize(details.get(orderId)));
                result.success = true;
                result.message = 'Found order ' + orderNumber + '.';
                continue;
            }

            List<Id> ids = recentIdsByAccount.containsKey(lookup.accountId) ? recentIdsByAccount.get(lookup.accountId) : new List<Id>();
            for (Id orderId : ids) {
                result.orders.add(summarize(details.get(orderId)));
            }
            result.success = true;
            result.message = ids.isEmpty() ? 'This partner has no orders.' : 'Found the ' + ids.size() + ' most recent orders, newest first.';
        }
        return results;
    }

    /**
     * Turns what a partner types ("103", "#00000103", "order 103") into the stored
     * eight-digit order number. Text without digits is returned trimmed, so it simply
     * does not match any order.
     * @return null when the input is blank
     */
    public static String normalizeOrderNumber(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String digits = raw.replaceAll('[^0-9]', '');
        if (String.isEmpty(digits)) {
            return raw.trim();
        }
        return digits.length() >= ORDER_NUMBER_LENGTH ? digits : digits.leftPad(ORDER_NUMBER_LENGTH, '0');
    }

    private static String accountKey(Id accountId, String orderNumber) {
        return String.valueOf(accountId) + ':' + orderNumber;
    }

    private static OrderSummary summarize(Order record) {
        OrderSummary summary = new OrderSummary();
        summary.orderNumber = record.OrderNumber;
        summary.placedOn = record.EffectiveDate;
        summary.fulfillmentStatus = record.Fulfillment_Status__c;
        summary.expectedDeliveryDate = record.Expected_Delivery_Date__c;
        summary.deliveredDate = record.Delivered_Date__c;
        summary.trackingNumber = record.Tracking_Number__c;
        summary.warehouse = record.Fulfillment_Warehouse__r?.Name;
        summary.totalAmount = record.TotalAmount;
        for (OrderItem item : record.OrderItems) {
            OrderLine line = new OrderLine();
            line.productCode = item.Product2.ProductCode;
            line.productName = item.Product2.Name;
            line.quantity = item.Quantity;
            line.unitPrice = item.UnitPrice;
            summary.lines.add(line);
        }
        return summary;
    }
}
