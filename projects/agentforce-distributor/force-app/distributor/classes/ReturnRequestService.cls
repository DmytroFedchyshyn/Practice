/**
 * Creates return requests for delivered order lines. Loads what the policy needs, applies
 * ReturnPolicy, saves the valid requests and reports every outcome.
 *
 * Every rule failure comes back as an error code plus a sentence the agent can pass on,
 * never as an exception. Valid requests in the same call are still saved.
 *
 * Bulk-safe: at most four queries and one DML statement per call.
 */
public with sharing class ReturnRequestService {
    @TestVisible
    private static DstDml dml = DstDmlProvider.get();

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
            String orderNumber = OrderNumbers.normalize(input.orderNumber);
            if (orderNumber != null) {
                numbers.add(orderNumber);
            }
            if (input.contactId != null) {
                contactIds.add(input.contactId);
            }
        }

        Map<String, Order> orderByAccountAndNumber = new Map<String, Order>();
        for (Order record : OrderSelector.selectWithLinesByNumbers(numbers, accountIds)) {
            orderByAccountAndNumber.put(OrderNumbers.key(record.AccountId, record.OrderNumber), record);
        }
        Map<Id, Contact> contacts = ContactSelector.selectByIds(contactIds);
        Map<String, Decimal> requestedByLine = ReturnRequestSelector.sumQuantityByOrderAndProduct(
            orderByAccountAndNumber.values(),
            ReturnPolicy.STATUSES_NOT_COUNTED
        );
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
        Date today = Date.today();

        for (ReturnInput input : inputs) {
            ReturnResult result = new ReturnResult();
            results.add(result);

            if (input.accountId == null) {
                fail(
                    result,
                    'MISSING_ACCOUNT',
                    'The partner account is not known, so a return request cannot be created.'
                );
                continue;
            }
            if (input.quantity == null || input.quantity <= 0) {
                fail(result, 'INVALID_QUANTITY', 'Quantity must be a whole number greater than zero.');
                continue;
            }
            String reason = String.isBlank(input.reason)
                ? null
                : reasonByLowerCase.get(input.reason.trim().toLowerCase());
            if (reason == null) {
                fail(result, 'INVALID_REASON', 'Reason must be one of: ' + String.join(reasonLabels, ', ') + '.');
                continue;
            }
            if (String.isBlank(input.product)) {
                fail(result, 'PRODUCT_REQUIRED', 'Give the product code or name of the product to return.');
                continue;
            }
            String orderNumber = OrderNumbers.normalize(input.orderNumber);
            if (orderNumber == null) {
                fail(result, 'ORDER_REQUIRED', 'Give the number of the order the product was delivered on.');
                continue;
            }
            Order parent = orderByAccountAndNumber.get(OrderNumbers.key(input.accountId, orderNumber));
            if (parent == null) {
                fail(result, 'ORDER_NOT_FOUND', 'No order ' + orderNumber + ' was found for this partner.');
                continue;
            }
            ReturnPolicy.Violation orderViolation = ReturnPolicy.checkOrder(parent, orderNumber, today);
            if (orderViolation != null) {
                fail(result, orderViolation.code, orderViolation.message);
                continue;
            }
            if (
                input.contactId != null &&
                (!contacts.containsKey(input.contactId) || contacts.get(input.contactId).AccountId != input.accountId)
            ) {
                fail(result, 'INVALID_CONTACT', 'The requester is not a contact of this partner.');
                continue;
            }

            List<OrderItem> matches = matchLines(parent.OrderItems, input.product);
            Set<Id> matchedProducts = new Set<Id>();
            for (OrderItem item : matches) {
                matchedProducts.add(item.Product2Id);
            }
            if (matchedProducts.isEmpty()) {
                fail(
                    result,
                    'PRODUCT_NOT_ON_ORDER',
                    'Order ' +
                        orderNumber +
                        ' has no product matching "' +
                        input.product.trim() +
                        '". Products on this order: ' +
                        productNames(parent.OrderItems) +
                        '.'
                );
                continue;
            }
            if (matchedProducts.size() > 1) {
                fail(
                    result,
                    'AMBIGUOUS_PRODUCT',
                    'More than one product on order ' +
                        orderNumber +
                        ' matches "' +
                        input.product.trim() +
                        '": ' +
                        productNames(matches) +
                        '. Ask which one.'
                );
                continue;
            }

            OrderItem line = matches[0];
            String lineKey = ReturnRequestSelector.key(parent.Id, line.Product2Id);
            Decimal alreadyRequested = requestedByLine.containsKey(lineKey) ? requestedByLine.get(lineKey) : 0;
            ReturnPolicy.Violation quantityViolation = ReturnPolicy.checkQuantity(
                orderNumber,
                line.Product2.Name,
                ReturnPolicy.orderedQuantity(parent.OrderItems, line.Product2Id),
                alreadyRequested,
                input.quantity
            );
            if (quantityViolation != null) {
                fail(result, quantityViolation.code, quantityViolation.message);
                continue;
            }
            // Count this request too, so two requests in one call cannot together exceed the order.
            requestedByLine.put(lineKey, alreadyRequested + input.quantity);

            records.add(
                new Return_Request__c(
                    Account__c = input.accountId,
                    Order__c = parent.Id,
                    Product__c = line.Product2Id,
                    Requested_By__c = input.contactId,
                    Quantity__c = input.quantity,
                    Reason__c = reason,
                    Description__c = input.description,
                    Status__c = ReturnPolicy.STATUS_SUBMITTED
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
        List<DstDmlResult> saves = dml.insertEach(records, DstDmlMode.USER);
        Set<Id> savedIds = new Set<Id>();
        for (DstDmlResult outcome : saves) {
            if (outcome.success) {
                savedIds.add(outcome.recordId);
            }
        }
        Map<Id, Return_Request__c> saved = ReturnRequestSelector.selectByIds(savedIds);

        for (Integer i = 0; i < saves.size(); i++) {
            ReturnResult result = pending[i];
            if (!saves[i].success) {
                fail(result, 'SAVE_FAILED', 'The return request could not be saved: ' + saves[i].firstMessage());
                continue;
            }
            Return_Request__c record = saved.get(saves[i].recordId);
            result.success = true;
            result.recordId = saves[i].recordId;
            result.requestNumber = record?.Name;
            result.status = record == null ? ReturnPolicy.STATUS_SUBMITTED : record.Status__c;
            result.message =
                'Return request ' +
                result.requestNumber +
                ' was submitted for ' +
                summaries[i] +
                '. Status: ' +
                result.status +
                '.';
        }
    }

    private static List<OrderItem> matchLines(List<OrderItem> lines, String term) {
        List<String> codes = new List<String>();
        List<String> names = new List<String>();
        for (OrderItem line : lines) {
            codes.add(line.Product2.ProductCode);
            names.add(line.Product2.Name);
        }
        List<OrderItem> matches = new List<OrderItem>();
        for (Integer position : ProductMatcher.match(codes, names, term)) {
            matches.add(lines[position]);
        }
        return matches;
    }

    private static String productNames(List<OrderItem> lines) {
        List<String> labels = new List<String>();
        for (OrderItem line : lines) {
            labels.add(line.Product2.Name + ' (' + line.Product2.ProductCode + ')');
        }
        return String.join(labels, ', ');
    }

    private static void fail(ReturnResult result, String errorCode, String message) {
        result.success = false;
        result.errorCode = errorCode;
        result.message = message;
    }
}
