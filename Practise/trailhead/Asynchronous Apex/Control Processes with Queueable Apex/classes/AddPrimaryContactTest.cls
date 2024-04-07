@IsTest
private class AddPrimaryContactTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, BillingState = 'CA'));
        }
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, BillingState = 'NY'));
        }

        insert accounts;
    }

    @IsTest
    static void addPrimaryContactTest() {
        Contact contact = new Contact(LastName = 'Test', FirstName = 'Contact');
        AddPrimaryContact addPrimaryContact = new AddPrimaryContact(contact, 'CA');

        Test.startTest();
        System.enqueueJob(addPrimaryContact);
        Test.stopTest();

        Assert.areEqual(50, [SELECT COUNT() FROM Contact]);
    }
}