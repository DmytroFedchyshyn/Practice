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
            String orderNumber = OrderNumbers.normalize(lookup.orderNumber);
            if (orderNumber == null) {
                recentAccounts.add(lookup.accountId);
            } else {
                numberedAccounts.add(lookup.accountId);
                numbers.add(orderNumber);
            }
        }

        Map<String, Order> orderByAccountAndNumber = new Map<String, Order>();
        for (Order record : OrderSelector.selectWithLinesByNumbers(numbers, numberedAccounts)) {
            orderByAccountAndNumber.put(OrderNumbers.key(record.AccountId, record.OrderNumber), record);
        }
        Map<Id, List<Id>> recentIdsByAccount = OrderSelector.selectRecentIdsByAccount(recentAccounts);
        Set<Id> recentIds = new Set<Id>();
        for (List<Id> ids : recentIdsByAccount.values()) {
            recentIds.addAll(ids);
        }
        Map<Id, Order> recentOrders = new Map<Id, Order>(OrderSelector.selectWithLinesByIds(recentIds));

        List<OrderResult> results = new List<OrderResult>();
        for (OrderLookup lookup : lookups) {
            OrderResult result = new OrderResult();
            results.add(result);
            if (lookup.accountId == null) {
                result.errorCode = 'MISSING_ACCOUNT';
                result.message = 'The partner account is not known, so orders cannot be looked up.';
                continue;
            }

            String orderNumber = OrderNumbers.normalize(lookup.orderNumber);
            if (orderNumber != null) {
                Order record = orderByAccountAndNumber.get(OrderNumbers.key(lookup.accountId, orderNumber));
                if (record == null) {
                    result.errorCode = 'ORDER_NOT_FOUND';
                    result.message = 'No order ' + orderNumber + ' was found for this partner.';
                    continue;
                }
                result.orders.add(summarize(record));
                result.success = true;
                result.message = 'Found order ' + orderNumber + '.';
                continue;
            }

            List<Id> ids = recentIdsByAccount.containsKey(lookup.accountId)
                ? recentIdsByAccount.get(lookup.accountId)
                : new List<Id>();
            for (Id orderId : ids) {
                if (recentOrders.containsKey(orderId)) {
                    result.orders.add(summarize(recentOrders.get(orderId)));
                }
            }
            result.success = true;
            result.message = result.orders.isEmpty()
                ? 'This partner has no orders.'
                : 'Found the ' + result.orders.size() + ' most recent orders, newest first.';
        }
        return results;
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
