/**
 * The invocable wrapper passes every input through and maps the result back.
 * Business rules are tested in ReturnRequestServiceTest and ReturnPolicyTest.
 */
@IsTest
private class CreateReturnRequestActionTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void passesEveryInputThrough() {
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

    @IsTest
    static void passesRuleFailuresOn() {
        Order old = DistributorTestData.oldDeliveredOrder('BOR-001');
        CreateReturnRequestAction.Request request = new CreateReturnRequestAction.Request();
        request.accountId = DistributorTestData.partnerId('BOR-001');
        request.orderNumber = old.OrderNumber;
        request.product = old.OrderItems[0].Product2.ProductCode;
        request.quantity = 1;
        request.reason = 'Defective';

        List<CreateReturnRequestAction.Response> responses;
        System.runAs(DistributorTestData.dataAdmin()) {
            responses = CreateReturnRequestAction.run(new List<CreateReturnRequestAction.Request>{ request });
        }

        Assert.isFalse(responses[0].success);
        Assert.areEqual('RETURN_WINDOW_CLOSED', responses[0].errorCode);
        Assert.isNull(responses[0].recordId);
    }
}
