/**
 * DstDml on the Database class. The mode picks the access level and the sharing: USER and
 * SYSTEM_WITH_SHARING write through a with sharing writer, SYSTEM_WITHOUT_SHARING through a without sharing
 * one. A refused whole save becomes a DstDmlException. In user mode a missing object or field permission
 * makes an all-or-none save raise a SecurityException, not a DmlException: an ...All write turns it into a
 * DstDmlException with the code INSUFFICIENT_ACCESS. A partial save gets the platform's error per record
 * instead; should it raise a SecurityException, insertEach answers it as a refusal of every record.
 */
public inherited sharing class DstDatabaseDml implements DstDml {
    public void insertAll(List<SObject> records, DstDmlMode mode) {
        writeAll(Operation.INSERT_ALL, records, null, mode);
    }

    public List<DstDmlResult> insertEach(List<SObject> records, DstDmlMode mode) {
        if (records.isEmpty()) {
            return new List<DstDmlResult>();
        }
        try {
            return DstDmlResult.of(writer(mode).insertRecords(records, false, level(mode)));
        } catch (SecurityException e) {
            List<DstDmlResult> refused = new List<DstDmlResult>();
            for (Integer i = 0; i < records.size(); i++) {
                refused.add(
                    new DstDmlResult(
                        null,
                        false,
                        DstDmlException.INSUFFICIENT_ACCESS,
                        new List<String>{ e.getMessage() }
                    )
                );
            }
            return refused;
        }
    }

    public void updateAll(List<SObject> records, DstDmlMode mode) {
        writeAll(Operation.UPDATE_ALL, records, null, mode);
    }

    public void upsertAll(List<SObject> records, Schema.SObjectField externalIdField, DstDmlMode mode) {
        writeAll(Operation.UPSERT_ALL, records, externalIdField, mode);
    }

    public void deleteAll(List<SObject> records, DstDmlMode mode) {
        writeAll(Operation.DELETE_ALL, records, null, mode);
    }

    private enum Operation {
        INSERT_ALL,
        UPDATE_ALL,
        UPSERT_ALL,
        DELETE_ALL
    }

    /** Every all-or-none write, with one translation of what the platform throws. */
    private static void writeAll(
        Operation operation,
        List<SObject> records,
        Schema.SObjectField externalIdField,
        DstDmlMode mode
    ) {
        if (records.isEmpty()) {
            return;
        }
        Writer target = writer(mode);
        AccessLevel access = level(mode);
        try {
            switch on operation {
                when INSERT_ALL {
                    target.insertRecords(records, true, access);
                }
                when UPDATE_ALL {
                    target.updateRecords(records, access);
                }
                when UPSERT_ALL {
                    target.upsertRecords(typed(records), externalIdField, access);
                }
                when DELETE_ALL {
                    target.deleteRecords(records, access);
                }
            }
        } catch (DmlException e) {
            throw DstDmlException.of(e);
        } catch (SecurityException e) {
            throw DstDmlException.of(e);
        }
    }

    private static AccessLevel level(DstDmlMode mode) {
        return mode == DstDmlMode.USER ? AccessLevel.USER_MODE : AccessLevel.SYSTEM_MODE;
    }

    private static Writer writer(DstDmlMode mode) {
        return mode == DstDmlMode.SYSTEM_WITHOUT_SHARING ? (Writer) new UnsharedWriter() : (Writer) new SharedWriter();
    }

    /** Apex upserts a list only when its type is concrete at run time, so the records are copied into one. */
    private static List<SObject> typed(List<SObject> records) {
        String objectName = records[0].getSObjectType().getDescribe().getName();
        List<SObject> concrete = (List<SObject>) Type.forName('List<' + objectName + '>').newInstance();
        concrete.addAll(records);
        return concrete;
    }

    private interface Writer {
        List<Database.SaveResult> insertRecords(List<SObject> records, Boolean allOrNone, AccessLevel level);
        void updateRecords(List<SObject> records, AccessLevel level);
        void upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, AccessLevel level);
        void deleteRecords(List<SObject> records, AccessLevel level);
    }

    private with sharing class SharedWriter implements Writer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Boolean allOrNone, AccessLevel level) {
            return Database.insert(records, allOrNone, level);
        }
        public void updateRecords(List<SObject> records, AccessLevel level) {
            Database.update(records, true, level);
        }
        public void upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, AccessLevel level) {
            if (externalIdField == null) {
                Database.upsert(records, true, level);
            } else {
                Database.upsert(records, externalIdField, true, level);
            }
        }
        public void deleteRecords(List<SObject> records, AccessLevel level) {
            Database.delete(records, true, level);
        }
    }

    /** Without sharing on purpose: it serves only the calls that name SYSTEM_WITHOUT_SHARING, each with its reason. */
    private without sharing class UnsharedWriter implements Writer {
        public List<Database.SaveResult> insertRecords(List<SObject> records, Boolean allOrNone, AccessLevel level) {
            return Database.insert(records, allOrNone, level);
        }
        public void updateRecords(List<SObject> records, AccessLevel level) {
            Database.update(records, true, level);
        }
        public void upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, AccessLevel level) {
            if (externalIdField == null) {
                Database.upsert(records, true, level);
            } else {
                Database.upsert(records, externalIdField, true, level);
            }
        }
        public void deleteRecords(List<SObject> records, AccessLevel level) {
            Database.delete(records, true, level);
        }
    }
}
