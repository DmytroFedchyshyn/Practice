/**
 * Facts about one return request, written as plain text for a prompt template that
 * explains the request to the partner. The text holds data and policy only; the
 * template decides tone and wording.
 *
 * A request of another partner gets the same answer as a missing request, so the
 * template cannot be used to probe which request numbers exist.
 *
 * Bulk-safe: one query per call.
 */
public with sharing class ReturnRequestFactsService {
    public class FactsInput {
        public String requestNumber;
        public String accountId;
    }

    /**
     * @return one block of text per input, in the same order
     */
    public static List<String> describe(List<FactsInput> inputs, Date today) {
        Set<String> numbers = new Set<String>();
        for (FactsInput input : inputs) {
            String normalized = ReturnRequestNumbers.normalize(input.requestNumber);
            if (normalized != null) {
                numbers.add(normalized);
            }
        }
        Map<String, Return_Request__c> byNumber = new Map<String, Return_Request__c>();
        for (Return_Request__c request : ReturnRequestSelector.selectWithOrderByNumbers(numbers)) {
            byNumber.put(request.Name, request);
        }

        List<String> facts = new List<String>();
        for (FactsInput input : inputs) {
            String requestNumber = ReturnRequestNumbers.normalize(input.requestNumber);
            Id accountId = toId(input.accountId);
            Return_Request__c request = byNumber.get(requestNumber);

            if (requestNumber == null) {
                facts.add('No return request number was given. Ask the partner for it, for example RR-00012.');
            } else if (accountId == null || request == null || request.Account__c != accountId) {
                facts.add(
                    'No return request ' +
                        requestNumber +
                        ' was found for this partner. Ask the partner to check the number; their list of return requests shows the valid numbers.'
                );
            } else {
                facts.add(describe(request, today));
            }
        }
        return facts;
    }

    private static String describe(Return_Request__c request, Date today) {
        Date requestedOn = request.CreatedDate.date();
        Date deliveredOn = request.Order__r.Delivered_Date__c;
        List<String> lines = new List<String>{
            'Return request: ' + request.Name,
            'Status: ' + request.Status__c,
            'Product: ' + request.Product_Name__c + ', quantity ' + request.Quantity__c.intValue(),
            'Order: ' + request.Order_Number__c,
            'Order delivered on: ' + (deliveredOn == null ? 'not delivered' : String.valueOf(deliveredOn)),
            'Request made on: ' + String.valueOf(requestedOn) + daysAfterDelivery(deliveredOn, requestedOn),
            'Reason: ' + request.Reason__c,
            'Partner description: ' + valueOrNone(request.Description__c),
            'Resolution notes from the returns team: ' + valueOrNone(request.Resolution_Notes__c),
            'Next step: ' + ReturnPolicy.nextStep(request.Status__c),
            'Return policy: ' + ReturnPolicy.POLICY_SUMMARY,
            'Today: ' + String.valueOf(today)
        };
        return String.join(lines, '\n');
    }

    private static String daysAfterDelivery(Date deliveredOn, Date requestedOn) {
        return deliveredOn == null ? '' : ' (' + deliveredOn.daysBetween(requestedOn) + ' days after delivery)';
    }

    private static String valueOrNone(String value) {
        return String.isBlank(value) ? 'none' : value;
    }

    /** The template passes the account as free text; anything that is not an Id matches nothing. */
    private static Id toId(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        try {
            return Id.valueOf(raw.trim());
        } catch (StringException e) {
            return null;
        }
    }
}
