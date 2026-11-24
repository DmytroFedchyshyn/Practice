/**
 * Rules for return request numbers as partners type them.
 */
public with sharing class ReturnRequestNumbers {
    private static final String PREFIX = 'RR-';
    private static final Integer DIGIT_COUNT = 5;

    /**
     * Turns what a partner types ("RR-00012", "rr 12", "12") into the stored number
     * "RR-00012". Text without digits is returned trimmed, so it simply does not match
     * any request.
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
        return PREFIX + (digits.length() >= DIGIT_COUNT ? digits : digits.leftPad(DIGIT_COUNT, '0'));
    }
}
