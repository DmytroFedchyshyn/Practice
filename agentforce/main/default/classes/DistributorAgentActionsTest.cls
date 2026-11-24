/**
 * Tests for the invocable wrappers: inputs are passed through and results come back as
 * text the agent can read. Business rules are tested in the service tests.
 */
@IsTest
private class DistributorAgentActionsTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void getPartnerOrdersFormatsEachOrderOnOneLine() {
        Order delivered = DistributorTestData.recentDeliveredOrder('BOR-001');
        GetPartnerOrdersAction.Request byNumber = new GetPartnerOrdersAction.Request();
        byNumber.accountId = DistributorTestData.partnerId('BOR-001');
        byNumber.orderNumber = delivered.OrderNumber;
        GetPartnerOrdersAction.Request recent = new GetPartnerOrdersAction.Request();
        recent.accountId = byNumber.accountId;

        List<GetPartnerOrdersAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = GetPartnerOrdersAction.run(new List<GetPartnerOrdersAction.Request>{ byNumber, recent });
        }

        Assert.isTrue(responses[0].success, responses[0].message);
        String line = responses[0].orders;
        Assert.isTrue(line.startsWith('Order ' + delivered.OrderNumber), line);
        Assert.isTrue(line.contains('status Delivered'), line);
        Assert.isTrue(line.contains('delivered ' + String.valueOf(delivered.Delivered_Date__c)), line);
        Assert.isTrue(line.contains('tracking TRK-'), line);
        Assert.isTrue(line.contains(delivered.OrderItems[0].Product2.ProductCode), line);
        Assert.areEqual(6, responses[1].orders.split('\n').size(), 'One line per recent order');
    }

    @IsTest
    static void checkProductStockListsWarehouses() {
        CheckProductStockAction.Request request = new CheckProductStockAction.Request();
        request.product = 'DST-1001';
        CheckProductStockAction.Request unknown = new CheckProductStockAction.Request();
        unknown.product = 'flux capacitor';

        List<CheckProductStockAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = CheckProductStockAction.run(new List<CheckProductStockAction.Request>{ request, unknown });
        }

        Assert.isTrue(responses[0].success, responses[0].message);
        Assert.isTrue(responses[0].stock.contains('285 available in total'), responses[0].stock);
        Assert.isTrue(responses[0].stock.contains('Central Warehouse (Kyiv): 210 available of 240 on hand'), responses[0].stock);
        Assert.isFalse(responses[1].success);
        Assert.areEqual('PRODUCT_NOT_FOUND', responses[1].errorCode);
        Assert.areEqual('', responses[1].stock);
    }

    @IsTest
    static void checkProductStockSaysWhenNothingIsStocked() {
        StockAvailabilityService.ProductStock product = new StockAvailabilityService.ProductStock();
        product.productCode = 'DST-9999';
        product.productName = 'Discontinued Item';

        Assert.areEqual(
            'Discontinued Item (DST-9999): 0 available in total. Not stocked in any active warehouse.',
            CheckProductStockAction.format(product)
        );
    }

    @IsTest
    static void createReturnRequestPassesEveryInputThrough() {
        Order parent = DistributorTestData.recentDeliveredOrder('MAR-003');
        Set<Id> returned = new Set<Id>();
        for (Return_Request__c existing : [SELECT Product__c FROM Return_Request__c WHERE Order__c = :parent.Id]) {
            returned.add(existing.Product__c);
        }
        OrderItem line;
        for (OrderItem item : parent.OrderItems) {
            if (!returned.contains(item.Product2Id)) {
                line = item;
                break;
            }
        }
        CreateReturnRequestAction.Request request = new CreateReturnRequestAction.Request();
        request.accountId = DistributorTestData.partnerId('MAR-003');
        request.contactId = [SELECT Id FROM Contact WHERE Account.Partner_Code__c = 'MAR-003' LIMIT 1].Id;
        request.orderNumber = parent.OrderNumber;
        request.product = line.Product2.ProductCode;
        request.quantity = 1;
        request.reason = 'Wrong Item';
        request.description = 'Received the wrong size.';

        List<CreateReturnRequestAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = CreateReturnRequestAction.run(new List<CreateReturnRequestAction.Request>{ request });
        }

        CreateReturnRequestAction.Response response = responses[0];
        Assert.isTrue(response.success, response.message);
        Assert.isNull(response.errorCode);
        Return_Request__c saved = [
            SELECT Name, Requested_By__c, Reason__c, Description__c, Quantity__c
            FROM Return_Request__c
            WHERE Id = :response.recordId
        ];
        Assert.areEqual(saved.Name, response.requestNumber);
        Assert.isTrue(response.message.contains(saved.Name), response.message);
        Assert.areEqual(request.contactId, saved.Requested_By__c);
        Assert.areEqual('Wrong Item', saved.Reason__c);
        Assert.areEqual('Received the wrong size.', saved.Description__c);
        Assert.areEqual(1, saved.Quantity__c);
    }
}
