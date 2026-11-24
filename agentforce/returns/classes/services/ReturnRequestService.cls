/**
 * Creates return requests for delivered order lines and enforces the return policy:
 * the order belongs to the partner, it was delivered, the return window is still open,
 * the product is on the order, and the quantity does not exceed what was ordered minus
 * what is already in open (not rejected) return requests.
 *
 * Every rule failure comes back as an error code plus a sentence the agent can pass on,
 * never as an exception. Valid requests in the same call are still saved.
 *
 * Bulk-safe: four queries and one DML statement per call, whatever the number of requests.
 */
public with sharing class ReturnRequestService {
    public static final Integer RETURN_WINDOW_DAYS = 30;

    private static final String FULFILLMENT_DELIVERED = 'Delivered';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_REJECTED = 'Rejected';

    public class ReturnInput {
        public Id accountId;
        /** Optional. The partner contact who asks; must belong to the partner. */
        public Id contactId;
        public String orderNumber;
        /** Product code or part of the product name, as the partner said it. */
        public String product;
        public Integer quantity;
        public String reason;
        public String description;
    }

    public class ReturnResult {
        public Boolean success = false;
        public String errorCode;
        public String message;
        public Id recordId;
        public String requestNumber;
        public String status;
    }

    public static List<ReturnResult> createReturns(List<ReturnInput> inputs) {
        Set<Id> accountIds = new Set<Id>();
        Set<String> numbers = new Set<String>();
        Set<Id> contactIds = new Set<Id>();
        for (ReturnInput input : inputs) {
            if (input.accountId != null) {
                accountIds.add(input.accountId);
            }
            String orderNumber = PartnerOrderService.normalizeOrderNumber(input.orderNumber);
            if (orderNumber != null) {
                numbers.add(orderNumber);
            }
            if (input.contactId != null) {
                contactIds.add(input.contactId);
            }
        }

        Map<String, Order> orderByAccountAndNumber = new Map<String, Order>();
        if (!numbers.isEmpty() && !accountIds.isEmpty()) {
            for (Order record : [
                SELECT
                    Id,
                    AccountId,
                    OrderNumber,
                    Fulfillment_Status__c,
                    Delivered_Date__c,
                    (SELECT Product2Id, Product2.ProductCode, Product2.Name, Quantity FROM OrderItems)
                FROM Order
                WHERE OrderNumber IN :numbers AND AccountId IN :accountIds
                WITH USER_MODE
            ]) {
                orderByAccountAndNumber.put(String.valueOf(record.AccountId) + ':' + record.OrderNumber, record);
            }
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        if (!contactIds.isEmpty()) {
            contacts = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds WITH USER_MODE]);
        }
        Map<String, Decimal> requestedByOrderAndProduct = openReturnQuantities(orderByAccountAndNumber.values());
        Map<String, String> reasonByLowerCase = new Map<String, String>();
        List<String> reasonLabels = new List<String>();
        for (Schema.PicklistEntry entry : Schema.SObjectType.Return_Request__c.fields.Reason__c.getPicklistValues()) {
            if (entry.isActive()) {
                reasonByLowerCase.put(entry.getValue().toLowerCase(), entry.getValue());
                reasonLabels.add(entry.getValue());
            }
        }

        List<ReturnResult> results = new List<ReturnResult>();
        List<Return_Request__c> records = new List<Return_Request__c>();
        List<ReturnResult> pending = new List<ReturnResult>();
        List<String> summaries = new List<String>();

        for (ReturnInput input : inputs) {
            ReturnResult result = new ReturnResult();
            results.add(result);

            if (input.accountId == null) {
                fail(result, 'MISSING_ACCOUNT', 'The partner account is not known, so a return request cannot be created.');
                continue;
            }
            if (input.quantity == null || input.quantity <= 0) {
                fail(result, 'INVALID_QUANTITY', 'Quantity must be a whole number greater than zero.');
                continue;
            }
            String reason = String.isBlank(input.reason) ? null : reasonByLowerCase.get(input.reason.trim().toLowerCase());
            if (reason == null) {
                fail(result, 'INVALID_REASON', 'Reason must be one of: ' + String.join(reasonLabels, ', ') + '.');
                continue;
            }
            if (String.isBlank(input.product)) {
                fail(result, 'PRODUCT_REQUIRED', 'Give the product code or name of the product to return.');
                continue;
            }
            String orderNumber = PartnerOrderService.normalizeOrderNumber(input.orderNumber);
            if (orderNumber == null) {
                fail(result, 'ORDER_REQUIRED', 'Give the number of the order the product was delivered on.');
                continue;
            }
            Order parent = orderByAccountAndNumber.get(String.valueOf(input.accountId) + ':' + orderNumber);
            if (parent == null) {
                fail(result, 'ORDER_NOT_FOUND', 'No order ' + orderNumber + ' was found for this partner.');
                continue;
            }
            if (parent.Fulfillment_Status__c != FULFILLMENT_DELIVERED || parent.Delivered_Date__c == null) {
                fail(
                    result,
                    'NOT_DELIVERED',
                    'Order ' + orderNumber + ' is ' + parent.Fulfillment_Status__c + '. Only delivered orders can be returned.'
                );
                continue;
            }
            Integer daysSinceDelivery = parent.Delivered_Date__c.daysBetween(Date.today());
            if (daysSinceDelivery > RETURN_WINDOW_DAYS) {
                fail(
                    result,
                    'RETURN_WINDOW_CLOSED',
                    'Order ' +
                        orderNumber +
                        ' was delivered on ' +
                        String.valueOf(parent.Delivered_Date__c) +
                        ', ' +
                        daysSinceDelivery +
                        ' days ago. Returns are accepted within ' +
                        RETURN_WINDOW_DAYS +
                        ' days of delivery.'
                );
                continue;
            }
            if (input.contactId != null && (!contacts.containsKey(input.contactId) || contacts.get(input.contactId).AccountId != input.accountId)) {
                fail(result, 'INVALID_CONTACT', 'The requester is not a contact of this partner.');
                continue;
            }

            List<OrderItem> matches = matchItems(parent.OrderItems, input.product);
            Set<Id> matchedProducts = new Set<Id>();
            for (OrderItem item : matches) {
                matchedProducts.add(item.Product2Id);
            }
            if (matchedProducts.isEmpty()) {
                fail(
                    result,
                    'PRODUCT_NOT_ON_ORDER',
                    'Order ' + orderNumber + ' has no product matching "' + input.product.trim() + '". Products on this order: ' + productNames(parent.OrderItems) + '.'
                );
                continue;
            }
            if (matchedProducts.size() > 1) {
                fail(
                    result,
                    'AMBIGUOUS_PRODUCT',
                    'More than one product on order ' + orderNumber + ' matches "' + input.product.trim() + '": ' + productNames(matches) + '. Ask which one.'
                );
                continue;
            }

            OrderItem line = matches[0];
            Decimal ordered = 0;
            for (OrderItem item : parent.OrderItems) {
                if (item.Product2Id == line.Product2Id) {
                    ordered += item.Quantity;
                }
            }
            String requestKey = String.valueOf(parent.Id) + ':' + String.valueOf(line.Product2Id);
            Decimal alreadyRequested = requestedByOrderAndProduct.containsKey(requestKey) ? requestedByOrderAndProduct.get(requestKey) : 0;
            if (alreadyRequested + input.quantity > ordered) {
                fail(
                    result,
                    'QUANTITY_EXCEEDS_ORDER',
                    'Order ' +
                        orderNumber +
                        ' has ' +
                        ordered.intValue() +
                        ' x ' +
                        line.Product2.Name +
                        ' and ' +
                        alreadyRequested.intValue() +
                        ' are already in open return requests, so at most ' +
                        (ordered - alreadyRequested).intValue() +
                        ' more can be returned.'
                );
                continue;
            }
            // Count this request too, so two requests in one call cannot together exceed the order.
            requestedByOrderAndProduct.put(requestKey, alreadyRequested + input.quantity);

            records.add(
                new Return_Request__c(
                    Account__c = input.accountId,
                    Order__c = parent.Id,
                    Product__c = line.Product2Id,
                    Requested_By__c = input.contactId,
                    Quantity__c = input.quantity,
                    Reason__c = reason,
                    Description__c = input.description,
                    Status__c = STATUS_SUBMITTED
                )
            );
            pending.add(result);
            summaries.add(input.quantity + ' x ' + line.Product2.Name + ' from order ' + orderNumber);
        }

        save(records, pending, summaries);
        return results;
    }

    private static void save(List<Return_Request__c> records, List<ReturnResult> pending, List<String> summaries) {
        if (records.isEmpty()) {
            return;
        }
        List<Database.SaveResult> saves = Database.insert(records, false, AccessLevel.USER_MODE);
        Set<Id> savedIds = new Set<Id>();
        for (Database.SaveResult outcome : saves) {
            if (outcome.isSuccess()) {
                savedIds.add(outcome.getId());
            }
        }
        Map<Id, Return_Request__c> saved = new Map<Id, Return_Request__c>(
            [SELECT Id, Name, Status__c FROM Return_Request__c WHERE Id IN :savedIds WITH USER_MODE]
        );

        for (Integer i = 0; i < saves.size(); i++) {
            ReturnResult result = pending[i];
            if (!saves[i].isSuccess()) {
                fail(result, 'SAVE_FAILED', 'The return request could not be saved: ' + saves[i].getErrors()[0].getMessage());
                continue;
            }
            Return_Request__c record = saved.get(saves[i].getId());
            result.success = true;
            result.recordId = saves[i].getId();
            result.requestNumber = record?.Name;
            result.status = record == null ? STATUS_SUBMITTED : record.Status__c;
            result.message = 'Return request ' + result.requestNumber + ' was submitted for ' + summaries[i] + '. Status: ' + result.status + '.';
        }
    }

    /** @return quantity already in open return requests, keyed by order id and product id */
    private static Map<String, Decimal> openReturnQuantities(List<Order> orders) {
        Map<String, Decimal> totals = new Map<String, Decimal>();
        if (orders.isEmpty()) {
            return totals;
        }
        for (AggregateResult row : [
            SELECT Order__c orderId, Product__c productId, SUM(Quantity__c) total
            FROM Return_Request__c
            WHERE Order__c IN :orders AND Status__c != :STATUS_REJECTED
            WITH USER_MODE
            GROUP BY Order__c, Product__c
        ]) {
            totals.put(String.valueOf(row.get('orderId')) + ':' + String.valueOf(row.get('productId')), (Decimal) row.get('total'));
        }
        return totals;
    }

    /** Exact product code wins; otherwise every line whose product name contains the term. */
    private static List<OrderItem> matchItems(List<OrderItem> items, String term) {
        List<OrderItem> matches = new List<OrderItem>();
        String trimmed = term.trim();
        for (OrderItem item : items) {
            if (trimmed.equalsIgnoreCase(item.Product2.ProductCode)) {
                matches.add(item);
            }
        }
        if (!matches.isEmpty()) {
            return matches;
        }
        for (OrderItem item : items) {
            if (item.Product2.Name.containsIgnoreCase(trimmed)) {
                matches.add(item);
            }
        }
        return matches;
    }

    private static String productNames(List<OrderItem> items) {
        List<String> labels = new List<String>();
        for (OrderItem item : items) {
            labels.add(item.Product2.Name + ' (' + item.Product2.ProductCode + ')');
        }
        return String.join(labels, ', ');
    }

    private static void fail(ReturnResult result, String errorCode, String message) {
        result.success = false;
        result.errorCode = errorCode;
        result.message = message;
    }
}
