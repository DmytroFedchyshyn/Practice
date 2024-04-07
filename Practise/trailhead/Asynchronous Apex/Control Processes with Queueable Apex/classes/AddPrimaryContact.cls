public with sharing class AddPrimaryContact implements Queueable {
    private Contact contact;
    private String stateAbbreviation;

    public AddPrimaryContact(Contact contact, String stateAbbreviation) {
        this.contact = contact;
        this.stateAbbreviation = stateAbbreviation;
    }

    public void execute(QueueableContext context) {
        List<Contact> contactsToInsert = new List<Contact>();
        List<Account> accounts = [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE BillingState = :stateAbbreviation LIMIT 200];
        for (Account account : accounts) {
            Contact newContact = contact.clone(false, true);
            newContact.AccountId = account.Id;
            contactsToInsert.add(newContact);
        }
        insert contactsToInsert;
    }
}