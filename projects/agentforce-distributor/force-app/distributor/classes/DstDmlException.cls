/**
 * A whole save refused: the first failed record's status code, message and Id. Its message is the
 * platform's whole text; the DmlException is its cause.
 */
public inherited sharing class DstDmlException extends Exception {
    /** The code of a write the running user's object or field access refuses in user mode. */
    public static final String INSUFFICIENT_ACCESS = 'INSUFFICIENT_ACCESS';

    public String statusCode { get; private set; }
    public Id recordId { get; private set; }

    /** A refusal that did not come from a DmlException, such as DstDmlFake's. */
    public static DstDmlException of(String statusCode, Id recordId, String message) {
        DstDmlException refusal = new DstDmlException(message);
        refusal.statusCode = statusCode;
        refusal.recordId = recordId;
        return refusal;
    }

    public static DstDmlException of(SecurityException cause) {
        DstDmlException wrapped = new DstDmlException(cause.getMessage(), cause);
        wrapped.statusCode = INSUFFICIENT_ACCESS;
        return wrapped;
    }

    public static DstDmlException of(DmlException cause) {
        DstDmlException wrapped = new DstDmlException(cause.getMessage(), cause);
        if (cause.getNumDml() > 0) {
            wrapped.statusCode = String.valueOf(cause.getDmlType(0));
            wrapped.recordId = cause.getDmlId(0);
        }
        return wrapped;
    }
}
