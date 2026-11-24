public with sharing class DailyLeadProcessor implements Schedulable {
    public void execute(SchedulableContext context) {
        List<Lead> leads = [SELECT Id, Name FROM Lead WHERE LeadSource = NULL LIMIT 200];
        for (Lead lead : leads) {
            lead.LeadSource = 'Dreamforce';
        }
        update leads;
    }
}