/**
 * Every write of the build goes through this interface, so a unit test can replace it with DstDmlFake
 * (development-foundation.md §3 F-9). An ...All method saves every record or none and throws
 * DstDmlException; an ...Each method saves what it can and returns one result per record, in order.
 * An operation is added when a story first needs it.
 */
public interface DstDml {
    void insertAll(List<SObject> records, DstDmlMode mode);
    List<DstDmlResult> insertEach(List<SObject> records, DstDmlMode mode);
    void updateAll(List<SObject> records, DstDmlMode mode);
    /** Upserts on the external id field, or on the Id when the field is null. */
    void upsertAll(List<SObject> records, Schema.SObjectField externalIdField, DstDmlMode mode);
    void deleteAll(List<SObject> records, DstDmlMode mode);
}
