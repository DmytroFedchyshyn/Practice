/**
 * All SOQL for partner contacts. Runs in user mode.
 */
public inherited sharing class ContactSelector {
    public static Map<Id, Contact> selectByIds(Set<Id> contactIds) {
        if (contactIds.isEmpty()) {
            return new Map<Id, Contact>();
        }
        return new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds WITH USER_MODE]);
    }
}
