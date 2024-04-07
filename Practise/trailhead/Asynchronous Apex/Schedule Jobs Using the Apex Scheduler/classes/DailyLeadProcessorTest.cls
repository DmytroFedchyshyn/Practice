@IsTest
private class DailyLeadProcessorTest {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                    FirstName = 'Test',
                    LastName = 'Lead ' + i,
                    Company = 'Test Company'
            ));
        }
        insert leads;
    }

    @IsTest
    static void executeTest() {
        String CRON_EXP = '0 0 0 * * ?';
        Test.startTest();
        System.schedule('ScheduledApexTest', CRON_EXP, new DailyLeadProcessor());
        Test.stopTest();

        Assert.areEqual(200, [SELECT count() FROM Lead WHERE LeadSource = 'Dreamforce']);
    }
}