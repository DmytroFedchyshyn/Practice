/**
 * Rules for order numbers as partners type them.
 */
public with sharing class OrderNumbers {
    private static final Integer STORED_LENGTH = 8;

    /**
     * Turns what a partner types ("103", "#00000103", "order 103") into the stored
     * eight-digit order number. Text without digits is returned trimmed, so it simply
     * does not match any order.
     * @return null when the input is blank
     */
    public static String normalize(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String digits = raw.replaceAll('[^0-9]', '');
        if (String.isEmpty(digits)) {
            return raw.trim();
        }
        return digits.length() >= STORED_LENGTH ? digits : digits.leftPad(STORED_LENGTH, '0');
    }

    /** Map key for "this order number of this partner". */
    public static String key(Id accountId, String orderNumber) {
        return String.valueOf(accountId) + ':' + orderNumber;
    }
}
