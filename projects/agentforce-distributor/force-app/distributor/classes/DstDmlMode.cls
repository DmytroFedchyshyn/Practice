/**
 * Whose access a write runs with. Every call to DstDml names one; a system mode carries a comment at the
 * call saying why (SEC-04).
 */
public enum DstDmlMode {
    /** The running user's object and field access and sharing. */
    USER,
    /** Past the user's object and field access, within the sharing rules. */
    SYSTEM_WITH_SHARING,
    /** Past both object and field access and sharing. */
    SYSTEM_WITHOUT_SHARING
}
