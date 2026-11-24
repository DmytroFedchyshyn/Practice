@IsTest
private class GetReturnRequestFactsActionTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void mapsInputsToThePromptText() {
        Return_Request__c request = [SELECT Name, Account__c FROM Return_Request__c WHERE Account__r.Partner_Code__c = 'MAR-003' LIMIT 1];
        GetReturnRequestFactsAction.Request input = new GetReturnRequestFactsAction.Request();
        input.requestNumber = request.Name;
        input.accountId = request.Account__c;

        List<GetReturnRequestFactsAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = GetReturnRequestFactsAction.run(new List<GetReturnRequestFactsAction.Request>{ input });
        }

        Assert.areEqual(1, responses.size());
        Assert.isTrue(responses[0].Prompt.contains('Status: Rejected'), responses[0].Prompt);
        Assert.isTrue(responses[0].Prompt.contains('Today: ' + String.valueOf(Date.today())), responses[0].Prompt);
    }
}
