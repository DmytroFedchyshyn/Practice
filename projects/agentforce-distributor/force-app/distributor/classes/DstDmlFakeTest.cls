/**
 * The fake answers as the database would, with nothing written: no data, no user.
 */
@IsTest
private class DstDmlFakeTest {
    @IsTest
    static void givesNewRecordsDistinctIdsAndKeepsEveryCall() {
        DstDmlFake fake = new DstDmlFake();
        List<Account> accounts = new List<Account>{ new Account(Name = 'A'), new Account(Name = 'B') };

        fake.insertAll(accounts, DstDmlMode.USER);

        Assert.isNotNull(accounts[0].Id);
        Assert.areNotEqual(accounts[0].Id, accounts[1].Id);
        Assert.areEqual(Account.SObjectType, accounts[0].Id.getSObjectType());
        Assert.areEqual(DstDmlMode.USER, fake.writes[0].mode);
        Assert.areEqual(2, fake.recordsOf('insertAll').size());
        Assert.areEqual(0, [SELECT COUNT() FROM Account WHERE Name IN ('A', 'B')], 'Nothing reaches the database');
    }

    @IsTest
    static void refusesWhatTheTestNamesAndWhatTheDatabaseWould() {
        Id locked = DstDmlFake.fakeId(Account.SObjectType);
        DstDmlFake fake = new DstDmlFake()
            .refuse(locked, StatusCode.UNABLE_TO_LOCK_ROW, 'unable to obtain exclusive access');

        List<DstDmlResult> results = fake.insertEach(
            new List<Account>{ new Account(Name = 'New'), new Account(Id = locked, Name = 'Has an Id') },
            DstDmlMode.USER
        );
        Assert.isTrue(results[0].success);
        Assert.areEqual('INVALID_FIELD_FOR_INSERT_UPDATE', results[1].statusCode);

        try {
            fake.updateAll(
                new List<Account>{ new Account(Id = locked, Name = 'Locked') },
                DstDmlMode.SYSTEM_WITH_SHARING
            );
            Assert.fail('A named record is refused');
        } catch (DstDmlException e) {
            Assert.areEqual('UNABLE_TO_LOCK_ROW', e.statusCode);
            Assert.areEqual(locked, e.recordId);
        }

        try {
            fake.updateAll(new List<Account>{ new Account(Name = 'No Id') }, DstDmlMode.USER);
            Assert.fail('An update without an Id is refused');
        } catch (DstDmlException e) {
            Assert.areEqual('MISSING_ARGUMENT', e.statusCode);
        }
    }

    @IsTest
    static void upsertInsertsNewRecordsAndUpdatesSavedOnes() {
        DstDmlFake fake = new DstDmlFake();
        Account saved = new Account(Id = DstDmlFake.fakeId(Account.SObjectType), Name = 'Saved');
        Account fresh = new Account(Name = 'Fresh');

        fake.upsertAll(new List<Account>{ saved, fresh }, null, DstDmlMode.USER);
        fake.deleteAll(new List<Account>{ saved }, DstDmlMode.USER);

        Assert.isNotNull(fresh.Id);
        Assert.areEqual(2, fake.recordsOf('upsertAll').size());
        Assert.areEqual(1, fake.recordsOf('deleteAll').size());
    }
}
