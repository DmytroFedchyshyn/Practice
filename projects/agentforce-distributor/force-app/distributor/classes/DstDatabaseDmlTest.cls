@IsTest
private class DstDatabaseDmlTest {
    private static final DstDml DML = new DstDatabaseDml();

    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    /** A user with no access to the build's objects and no role, so no sharing rule reaches them. */
    private static User userWithoutAccess() {
        User outsider = new User(
            LastName = 'Dml Outsider',
            Alias = 'dmlout',
            Email = 'dml.outsider@example.com',
            Username = 'dml.outsider.' + UserInfo.getOrganizationId() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]
            .Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Kyiv'
        );
        insert outsider;
        return outsider;
    }

    @IsTest
    static void insertsUpdatesAndDeletesInUserMode() {
        System.runAs(DistributorTestData.dataAdmin()) {
            Warehouse__c depot = new Warehouse__c(Name = 'Test Depot', Code__c = 'TST');
            DML.insertAll(new List<Warehouse__c>{ depot }, DstDmlMode.USER);
            Assert.isNotNull(depot.Id, 'The insert sets the Id on the record');

            depot.City__c = 'Lviv';
            DML.updateAll(new List<Warehouse__c>{ depot }, DstDmlMode.USER);
            Assert.areEqual('Lviv', [SELECT City__c FROM Warehouse__c WHERE Id = :depot.Id].City__c);

            DML.deleteAll(new List<Warehouse__c>{ depot }, DstDmlMode.USER);
            Assert.areEqual(0, [SELECT COUNT() FROM Warehouse__c WHERE Id = :depot.Id]);
        }
    }

    @IsTest
    static void aRefusedWholeSaveThrowsWithTheStatusCode() {
        System.runAs(DistributorTestData.dataAdmin()) {
            try {
                DML.insertAll(new List<Warehouse__c>{ new Warehouse__c(Name = 'No Code') }, DstDmlMode.USER);
                Assert.fail('A warehouse without a code is refused');
            } catch (DstDmlException e) {
                Assert.areEqual('REQUIRED_FIELD_MISSING', e.statusCode);
                Assert.isTrue(e.getCause() instanceof DmlException, 'The platform exception is the cause');
            }
            try {
                DML.upsertAll(new List<Warehouse__c>{ new Warehouse__c(Name = 'No Code') }, null, DstDmlMode.USER);
                Assert.fail('An upsert of a warehouse without a code is refused');
            } catch (DstDmlException e) {
                Assert.areEqual('REQUIRED_FIELD_MISSING', e.statusCode);
            }
        }
    }

    @IsTest
    static void insertEachSavesWhatItCanInOrder() {
        List<DstDmlResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = DML.insertEach(
                new List<Warehouse__c>{
                    new Warehouse__c(Name = 'Good', Code__c = 'GD1'),
                    new Warehouse__c(Name = 'No Code')
                },
                DstDmlMode.USER
            );
        }

        Assert.areEqual(2, results.size());
        Assert.isTrue(results[0].success);
        Assert.isNotNull(results[0].recordId);
        Assert.isFalse(results[1].success);
        Assert.areEqual('REQUIRED_FIELD_MISSING', results[1].statusCode);
        Assert.isNotNull(results[1].firstMessage());
    }

    @IsTest
    static void upsertsOnAnExternalIdAndOnTheId() {
        System.runAs(DistributorTestData.dataAdmin()) {
            DML.upsertAll(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Ext', Code__c = 'EXT') },
                Warehouse__c.Code__c,
                DstDmlMode.USER
            );
            DML.upsertAll(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Ext Renamed', Code__c = 'EXT') },
                Warehouse__c.Code__c,
                DstDmlMode.USER
            );
            Warehouse__c saved = [SELECT Id, Name FROM Warehouse__c WHERE Code__c = 'EXT'];
            Assert.areEqual('Ext Renamed', saved.Name, 'The second upsert updates the same record');

            saved.Name = 'By Id';
            Warehouse__c added = new Warehouse__c(Name = 'New', Code__c = 'NEW');
            DML.upsertAll(new List<SObject>{ saved, added }, null, DstDmlMode.USER);
            Assert.areEqual('By Id', [SELECT Name FROM Warehouse__c WHERE Id = :saved.Id].Name);
            Assert.isNotNull(added.Id, 'A record without an Id is inserted');
        }
    }

    @IsTest
    static void userModeIsRefusedWhereSystemModeIsNot() {
        User outsider;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            outsider = userWithoutAccess();
        }
        System.runAs(outsider) {
            try {
                DML.insertAll(
                    new List<Warehouse__c>{ new Warehouse__c(Name = 'Denied', Code__c = 'DEN') },
                    DstDmlMode.USER
                );
                Assert.fail('A user without access to the object cannot create it in user mode');
            } catch (DstDmlException e) {
                Assert.areEqual(DstDmlException.INSUFFICIENT_ACCESS, e.statusCode);
                Assert.isTrue(e.getCause() instanceof SecurityException, 'The platform exception is the cause');
            }
            List<DstDmlResult> each = DML.insertEach(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Denied', Code__c = 'DE2') },
                DstDmlMode.USER
            );
            Assert.isFalse(each[0].success, 'insertEach answers a refusal instead of throwing');
            Assert.isNotNull(each[0].statusCode, 'The platform answers a partial save record by record');
            DML.insertAll(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Allowed', Code__c = 'ALW') },
                DstDmlMode.SYSTEM_WITH_SHARING
            );
            Warehouse__c allowed = [SELECT Id FROM Warehouse__c WHERE Code__c = 'ALW' WITH SYSTEM_MODE];
            for (String operation : new List<String>{ 'update', 'upsert', 'delete' }) {
                List<Warehouse__c> records = new List<Warehouse__c>{
                    new Warehouse__c(Id = allowed.Id, Name = 'Changed')
                };
                try {
                    if (operation == 'update') {
                        DML.updateAll(records, DstDmlMode.USER);
                    } else if (operation == 'upsert') {
                        DML.upsertAll(records, null, DstDmlMode.USER);
                    } else {
                        DML.deleteAll(records, DstDmlMode.USER);
                    }
                    Assert.fail('A user without access cannot ' + operation + ' in user mode');
                } catch (DstDmlException e) {
                    Assert.areEqual(DstDmlException.INSUFFICIENT_ACCESS, e.statusCode, operation);
                }
            }
        }
        Assert.areEqual(1, [SELECT COUNT() FROM Warehouse__c WHERE Code__c = 'ALW']);
    }

    @IsTest
    static void onlyWithoutSharingReachesARecordTheUserCannotSee() {
        Return_Request__c request = [SELECT Id FROM Return_Request__c LIMIT 1];
        User outsider;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            outsider = userWithoutAccess();
        }
        System.runAs(outsider) {
            try {
                DML.updateAll(
                    new List<Return_Request__c>{ new Return_Request__c(Id = request.Id, Description__c = 'x') },
                    DstDmlMode.SYSTEM_WITH_SHARING
                );
                Assert.fail('Return requests are private, so the sharing refuses the update');
            } catch (DstDmlException e) {
                Assert.areEqual(request.Id, e.recordId);
            }
            DML.updateAll(
                new List<Return_Request__c>{
                    new Return_Request__c(Id = request.Id, Description__c = 'Updated past sharing')
                },
                DstDmlMode.SYSTEM_WITHOUT_SHARING
            );
        }
        Assert.areEqual(
            'Updated past sharing',
            [SELECT Description__c FROM Return_Request__c WHERE Id = :request.Id].Description__c
        );
    }

    @IsTest
    static void everyOperationRunsWithoutSharing() {
        System.runAs(DistributorTestData.dataAdmin()) {
            Warehouse__c first = new Warehouse__c(Name = 'One', Code__c = 'WS1');
            DML.insertAll(new List<Warehouse__c>{ first }, DstDmlMode.SYSTEM_WITHOUT_SHARING);
            List<DstDmlResult> each = DML.insertEach(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Two', Code__c = 'WS2') },
                DstDmlMode.SYSTEM_WITHOUT_SHARING
            );
            DML.upsertAll(
                new List<Warehouse__c>{ new Warehouse__c(Name = 'Three', Code__c = 'WS3') },
                Warehouse__c.Code__c,
                DstDmlMode.SYSTEM_WITHOUT_SHARING
            );
            first.Name = 'One Renamed';
            DML.upsertAll(new List<Warehouse__c>{ first }, null, DstDmlMode.SYSTEM_WITHOUT_SHARING);
            DML.deleteAll(new List<Warehouse__c>{ first }, DstDmlMode.SYSTEM_WITHOUT_SHARING);

            Assert.isTrue(each[0].success);
            Assert.areEqual(2, [SELECT COUNT() FROM Warehouse__c WHERE Code__c IN ('WS1', 'WS2', 'WS3')]);
        }
    }
}
