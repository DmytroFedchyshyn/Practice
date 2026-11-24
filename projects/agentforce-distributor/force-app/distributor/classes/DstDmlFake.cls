/**
 * DstDml for unit tests: answers as the database would without writing anything. New records get fake Ids,
 * a record the test names is refused, an insert with an Id or an update without one is refused, and every
 * call is kept with its operation, mode and records.
 */
@IsTest
public class DstDmlFake implements DstDml {
    public class Write {
        public String operation;
        public DstDmlMode mode;
        public List<SObject> records;
    }

    public List<Write> writes = new List<Write>();
    private Map<Id, String> refusedCodes = new Map<Id, String>();
    private Map<Id, String> refusedMessages = new Map<Id, String>();
    private static Integer counter = 0;

    /** A distinct fake Id of the type, for a record in memory. */
    public static Id fakeId(Schema.SObjectType type) {
        counter++;
        return Id.valueOf(type.getDescribe().getKeyPrefix() + String.valueOf(counter).leftPad(12, '0'));
    }

    /** The record with this Id is refused, as a validation rule or the sharing would refuse it. */
    public DstDmlFake refuse(Id recordId, StatusCode code, String message) {
        refusedCodes.put(recordId, String.valueOf(code));
        refusedMessages.put(recordId, message);
        return this;
    }

    /** Every record written by one operation, across calls, in order. */
    public List<SObject> recordsOf(String operation) {
        List<SObject> records = new List<SObject>();
        for (Write write : writes) {
            if (write.operation == operation) {
                records.addAll(write.records);
            }
        }
        return records;
    }

    public void insertAll(List<SObject> records, DstDmlMode mode) {
        throwFirst(answer('insertAll', records, mode, true));
    }

    public List<DstDmlResult> insertEach(List<SObject> records, DstDmlMode mode) {
        return answer('insertEach', records, mode, true);
    }

    public void updateAll(List<SObject> records, DstDmlMode mode) {
        throwFirst(answer('updateAll', records, mode, false));
    }

    public void upsertAll(List<SObject> records, Schema.SObjectField externalIdField, DstDmlMode mode) {
        List<SObject> newRecords = new List<SObject>();
        List<SObject> savedRecords = new List<SObject>();
        for (SObject record : records) {
            if (record.Id == null) {
                newRecords.add(record);
            } else {
                savedRecords.add(record);
            }
        }
        throwFirst(answer('upsertAll', newRecords, mode, true));
        throwFirst(answer('upsertAll', savedRecords, mode, false));
    }

    public void deleteAll(List<SObject> records, DstDmlMode mode) {
        throwFirst(answer('deleteAll', records, mode, false));
    }

    private List<DstDmlResult> answer(String operation, List<SObject> records, DstDmlMode mode, Boolean isNew) {
        Write write = new Write();
        write.operation = operation;
        write.mode = mode;
        write.records = records;
        writes.add(write);

        List<DstDmlResult> results = new List<DstDmlResult>();
        for (SObject record : records) {
            if (isNew && record.Id != null) {
                results.add(
                    new DstDmlResult(
                        null,
                        false,
                        'INVALID_FIELD_FOR_INSERT_UPDATE',
                        new List<String>{ 'cannot specify Id in an insert call' }
                    )
                );
            } else if (!isNew && record.Id == null) {
                results.add(
                    new DstDmlResult(
                        null,
                        false,
                        'MISSING_ARGUMENT',
                        new List<String>{ 'Id not specified in an update call' }
                    )
                );
            } else if (record.Id != null && refusedCodes.containsKey(record.Id)) {
                results.add(
                    new DstDmlResult(
                        record.Id,
                        false,
                        refusedCodes.get(record.Id),
                        new List<String>{ refusedMessages.get(record.Id) }
                    )
                );
            } else {
                if (isNew) {
                    record.Id = fakeId(record.getSObjectType());
                }
                results.add(new DstDmlResult(record.Id, true, null, null));
            }
        }
        return results;
    }

    private static void throwFirst(List<DstDmlResult> results) {
        for (DstDmlResult result : results) {
            if (!result.success) {
                throw DstDmlException.of(result.statusCode, result.recordId, result.firstMessage());
            }
        }
    }
}
