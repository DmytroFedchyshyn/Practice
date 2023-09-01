public with sharing class LogEventTriggerHandler {

    public static void handleAfterInsert(List<LogEvent__e> records) {
        List<Log__c> logs = new List<Log__c>();
        for (LogEvent__e logEvent : records) {
            Log__c log = new Log__c();
            log.Datetime__c = logEvent.Datetime__c;
            log.User__c = logEvent.User__c;
            log.Message__c = logEvent.Message__c;
            log.Level__c = logEvent.Level__c;
            log.Source__c = logEvent.Source__c;
            logs.add(log);
        }

        if (!logs.isEmpty()) {
            insert logs;
        }
    }
}