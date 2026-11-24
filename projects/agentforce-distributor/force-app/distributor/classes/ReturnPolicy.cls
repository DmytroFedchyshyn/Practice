/**
 * The return policy: which orders can be returned and how many units of a line.
 * Pure rules on records already in memory; no SOQL, no DML, so it is unit-testable without data.
 */
public with sharing class ReturnPolicy {
    public static final Integer RETURN_WINDOW_DAYS = 30;
    public static final String STATUS_SUBMITTED = 'Submitted';
    /** Requests in these statuses do not use up the returnable quantity. */
    public static final Set<String> STATUSES_NOT_COUNTED = new Set<String>{ 'Rejected' };

    /** The policy in one paragraph, for prompts that explain a request to a partner. */
    public static final String POLICY_SUMMARY =
        'Returns are accepted for delivered orders within ' +
        RETURN_WINDOW_DAYS +
        ' days of delivery, for at most the ordered quantity of each product. Rejected requests do not count toward that quantity.';

    private static final String FULFILLMENT_DELIVERED = 'Delivered';

    private static final Map<String, String> NEXT_STEPS = new Map<String, String>{
        'Submitted' => 'The returns team reviews new requests within 2 business days.',
        'Under Review' => 'The returns team is checking the request and answers the requester by email.',
        'Approved' => 'Send the product back with the prepaid return label that the requester received by email.',
        'Rejected' => 'The request is closed. The resolution notes give the reason. A new request can be made if the policy allows it.',
        'Received' => 'The warehouse has the product. The refund is issued within 5 business days.',
        'Refunded' => 'The refund is issued. Nothing else is needed.'
    };

    /** What happens next for a request in this status, in one or two sentences. */
    public static String nextStep(String status) {
        String step = NEXT_STEPS.get(status);
        return step == null ? 'Contact the returns team for the next step.' : step;
    }

    public class Violation {
        public String code;
        public String message;

        public Violation(String code, String message) {
            this.code = code;
            this.message = message;
        }
    }

    /**
     * The order must be delivered, and delivered no more than RETURN_WINDOW_DAYS ago.
     * @return null when the order can be returned
     */
    public static Violation checkOrder(Order parent, String orderNumber, Date today) {
        if (parent.Fulfillment_Status__c != FULFILLMENT_DELIVERED || parent.Delivered_Date__c == null) {
            return new Violation(
                'NOT_DELIVERED',
                'Order ' +
                    orderNumber +
                    ' is ' +
                    parent.Fulfillment_Status__c +
                    '. Only delivered orders can be returned.'
            );
        }
        Integer daysSinceDelivery = parent.Delivered_Date__c.daysBetween(today);
        if (daysSinceDelivery > RETURN_WINDOW_DAYS) {
            return new Violation(
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
        }
        return null;
    }

    /** Units of a product on the order, summed over its lines. */
    public static Decimal orderedQuantity(List<OrderItem> lines, Id productId) {
        Decimal ordered = 0;
        for (OrderItem line : lines) {
            if (line.Product2Id == productId) {
                ordered += line.Quantity;
            }
        }
        return ordered;
    }

    /**
     * A request may not take the total above what was ordered.
     * @return null when the quantity can be returned
     */
    public static Violation checkQuantity(
        String orderNumber,
        String productName,
        Decimal ordered,
        Decimal alreadyRequested,
        Integer requested
    ) {
        if (requested == null || requested <= 0) {
            return new Violation('INVALID_QUANTITY', 'Quantity must be a whole number greater than zero.');
        }
        if (alreadyRequested + requested > ordered) {
            return new Violation(
                'QUANTITY_EXCEEDS_ORDER',
                'Order ' +
                    orderNumber +
                    ' has ' +
                    ordered.intValue() +
                    ' x ' +
                    productName +
                    ' and ' +
                    alreadyRequested.intValue() +
                    ' are already in open return requests, so at most ' +
                    Math.max(0, (ordered - alreadyRequested).intValue()) +
                    ' more can be returned.'
            );
        }
        return null;
    }
}
