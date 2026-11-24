/**
 * Runs the List_Return_Requests flow the way an agent action does: inputs in, the
 * returnRequests collection out, as a user whose data access is known.
 */
@IsTest
private class ListReturnRequestsFlowTest {
    private static final String FLOW_NAME = 'List_Return_Requests';

    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    private static List<Return_Request__c> run(Id accountId, String status) {
        Map<String, Object> inputs = new Map<String, Object>{ 'accountId' => accountId, 'status' => status };
        List<Return_Request__c> requests;
        System.runAs(DistributorTestData.dataAdmin()) {
            Flow.Interview listRequests = Flow.Interview.createInterview(FLOW_NAME, inputs);
            listRequests.start();
            requests = (List<Return_Request__c>) listRequests.getVariableValue('returnRequests');
        }
        return requests == null ? new List<Return_Request__c>() : requests;
    }

    /** Extra requests for a partner, on the first line of its most recently delivered order. */
    private static void addRequests(String partnerCode, Integer count) {
        Order parent = DistributorTestData.recentDeliveredOrder(partnerCode);
        List<Return_Request__c> extra = new List<Return_Request__c>();
        for (Integer i = 0; i < count; i++) {
            extra.add(
                new Return_Request__c(
                    Account__c = DistributorTestData.partnerId(partnerCode),
                    Order__c = parent.Id,
                    Product__c = parent.OrderItems[0].Product2Id,
                    Quantity__c = 1,
                    Reason__c = 'Defective',
                    Status__c = 'Submitted'
                )
            );
        }
        insert extra;
    }

    @IsTest
    static void listsOnlyTheRequestsOfTheGivenPartner() {
        Id borealis = DistributorTestData.partnerId('BOR-001');

        List<Return_Request__c> requests = run(borealis, null);

        Return_Request__c expected = [
            SELECT Id, Order__r.OrderNumber, Product__r.Name
            FROM Return_Request__c
            WHERE Account__c = :borealis
        ];
        Assert.areEqual(1, requests.size());
        Assert.areEqual(expected.Id, requests[0].Id);
        Assert.areEqual(
            expected.Order__r.OrderNumber,
            requests[0].Order_Number__c,
            'Order number comes from the formula field'
        );
        Assert.areEqual(
            expected.Product__r.Name,
            requests[0].Product_Name__c,
            'Product name comes from the formula field'
        );
        Assert.isTrue(requests[0].Name.startsWith('RR-'), requests[0].Name);
    }

    @IsTest
    static void returnsAtMostTenNewestFirst() {
        addRequests('BOR-001', 12);
        Id borealis = DistributorTestData.partnerId('BOR-001');

        List<Return_Request__c> requests = run(borealis, '');

        Return_Request__c newest = [
            SELECT Id
            FROM Return_Request__c
            WHERE Account__c = :borealis
            ORDER BY Name DESC
            LIMIT 1
        ];
        Assert.areEqual(10, requests.size());
        Assert.areEqual(newest.Id, requests[0].Id);
        for (Integer i = 1; i < requests.size(); i++) {
            Assert.isTrue(
                requests[i - 1].Name > requests[i].Name,
                'Newest first: ' + requests[i - 1].Name + ' before ' + requests[i].Name
            );
        }
    }

    @IsTest
    static void filtersByStatusIgnoringCase() {
        Id kestrel = DistributorTestData.partnerId('KES-002');

        Assert.areEqual(1, run(kestrel, ' approved ').size(), 'The seeded Kestrel request is Approved');
        Assert.areEqual(0, run(kestrel, 'Submitted').size());
    }

    @IsTest
    static void unknownOrMissingAccountReturnsNothing() {
        Assert.isTrue(run(null, null).isEmpty());
        Assert.isTrue(run('001000000000001', null).isEmpty());
    }
}
