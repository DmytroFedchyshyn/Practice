/**
 * The invocable wrapper passes inputs through and formats results as text for the agent.
 * Business rules are tested in PartnerOrderServiceTest.
 */
@IsTest
private class GetPartnerOrdersActionTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void formatsEachOrderOnOneLine() {
        Order delivered = DistributorTestData.recentDeliveredOrder('BOR-001');
        GetPartnerOrdersAction.Request byNumber = new GetPartnerOrdersAction.Request();
        byNumber.accountId = DistributorTestData.partnerId('BOR-001');
        byNumber.orderNumber = delivered.OrderNumber;
        GetPartnerOrdersAction.Request recent = new GetPartnerOrdersAction.Request();
        recent.accountId = byNumber.accountId;
        GetPartnerOrdersAction.Request missing = new GetPartnerOrdersAction.Request();
        missing.accountId = byNumber.accountId;
        missing.orderNumber = '99999999';

        List<GetPartnerOrdersAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = GetPartnerOrdersAction.run(
                new List<GetPartnerOrdersAction.Request>{ byNumber, recent, missing }
            );
        }

        Assert.isTrue(responses[0].success, responses[0].message);
        String line = responses[0].orders;
        Assert.isTrue(line.startsWith('Order ' + delivered.OrderNumber), line);
        Assert.isTrue(line.contains('status Delivered'), line);
        Assert.isTrue(line.contains('delivered ' + String.valueOf(delivered.Delivered_Date__c)), line);
        Assert.isTrue(line.contains('tracking TRK-'), line);
        Assert.isTrue(line.contains(delivered.OrderItems[0].Product2.ProductCode), line);
        Assert.areEqual(6, responses[1].orders.split('\n').size(), 'One line per recent order');
        Assert.isFalse(responses[2].success);
        Assert.areEqual('ORDER_NOT_FOUND', responses[2].errorCode);
        Assert.areEqual('', responses[2].orders);
    }

    @IsTest
    static void showsExpectedDeliveryUntilDelivered() {
        PartnerOrderService.OrderSummary summary = new PartnerOrderService.OrderSummary();
        summary.orderNumber = '00000001';
        summary.placedOn = Date.newInstance(2026, 11, 20);
        summary.fulfillmentStatus = 'Processing';
        summary.expectedDeliveryDate = Date.newInstance(2026, 11, 30);

        Assert.areEqual(
            'Order 00000001 | placed 2026-11-20 | status Processing | expected delivery 2026-11-30 | products: ',
            GetPartnerOrdersAction.format(summary)
        );
    }
}
