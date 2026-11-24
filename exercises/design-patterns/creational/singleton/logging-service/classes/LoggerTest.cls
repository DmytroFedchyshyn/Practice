@IsTest
private class LoggerTest {

    @IsTest
    static void testLogInfo() {
        Test.startTest();
        Logger.getInstance().logInfo('Test Message', LoggerTest.class.getName());
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Log__c> logs = [SELECT Level__c, Message__c FROM Log__c];
        Assert.areEqual(1, logs.size());
    }

}