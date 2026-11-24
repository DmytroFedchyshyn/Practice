@IsTest
private class ReturnRequestServiceTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    private static ReturnRequestService.ReturnInput input(
        String partnerCode,
        String orderNumber,
        String product,
        Integer quantity
    ) {
        return inputFor(DistributorTestData.partnerId(partnerCode), orderNumber, product, quantity);
    }

    private static ReturnRequestService.ReturnInput inputFor(
        Id accountId,
        String orderNumber,
        String product,
        Integer quantity
    ) {
        ReturnRequestService.ReturnInput input = new ReturnRequestService.ReturnInput();
        input.accountId = accountId;
        input.orderNumber = orderNumber;
        input.product = product;
        input.quantity = quantity;
        input.reason = 'Defective';
        return input;
    }

    private static List<ReturnRequestService.ReturnResult> create(List<ReturnRequestService.ReturnInput> inputs) {
        List<ReturnRequestService.ReturnResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = ReturnRequestService.createReturns(inputs);
        }
        return results;
    }

    /** Product on the order that has no return request yet. The seed puts one on the first line. */
    private static OrderItem lineWithoutReturns(Order parent) {
        Set<Id> returned = new Set<Id>();
        for (Return_Request__c existing : [SELECT Product__c FROM Return_Request__c WHERE Order__c = :parent.Id]) {
            returned.add(existing.Product__c);
        }
        for (OrderItem item : parent.OrderItems) {
            if (!returned.contains(item.Product2Id)) {
                return item;
            }
        }
        return null;
    }

    @IsTest
    static void createsRequestForDeliveredOrder() {
        Order parent = DistributorTestData.recentDeliveredOrder('BOR-001');
        OrderItem line = lineWithoutReturns(parent);
        ReturnRequestService.ReturnInput request = input('BOR-001', parent.OrderNumber, line.Product2.ProductCode, 1);
        request.reason = 'damaged in transit';
        request.contactId = [SELECT Id FROM Contact WHERE Account.Partner_Code__c = 'BOR-001' LIMIT 1].Id;
        request.description = 'Box was crushed.';

        ReturnRequestService.ReturnResult result = create(new List<ReturnRequestService.ReturnInput>{ request })[0];

        Assert.isTrue(result.success, result.message);
        Assert.isTrue(result.requestNumber.startsWith('RR-'), result.requestNumber);
        Assert.areEqual('Submitted', result.status);
        Return_Request__c saved = [
            SELECT Account__c, Order__c, Product__c, Requested_By__c, Quantity__c, Reason__c, Status__c
            FROM Return_Request__c
            WHERE Id = :result.recordId
        ];
        Assert.areEqual(parent.Id, saved.Order__c);
        Assert.areEqual(line.Product2Id, saved.Product__c);
        Assert.areEqual(request.contactId, saved.Requested_By__c);
        Assert.areEqual(
            'Damaged in Transit',
            saved.Reason__c,
            'Reason is matched ignoring case and stored as the picklist value'
        );
    }

    @IsTest
    static void findsTheLineByPartOfTheProductName() {
        Order parent = DistributorTestData.recentDeliveredOrder('KES-002');
        OrderItem line = lineWithoutReturns(parent);
        String fragment = line.Product2.Name.split(' ')[0].toLowerCase();

        ReturnRequestService.ReturnResult result = create(
            new List<ReturnRequestService.ReturnInput>{ input('KES-002', parent.OrderNumber, fragment, 1) }
        )[0];

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(
            line.Product2Id,
            [SELECT Product__c FROM Return_Request__c WHERE Id = :result.recordId].Product__c
        );
    }

    @IsTest
    static void enforcesTheReturnPolicy() {
        Order recent = DistributorTestData.recentDeliveredOrder('BOR-001');
        Order old = DistributorTestData.oldDeliveredOrder('BOR-001');
        Order processing = DistributorTestData.orderWithStatus('BOR-001', 'Processing');
        Order otherPartners = DistributorTestData.recentDeliveredOrder('KES-002');
        String product = lineWithoutReturns(recent).Product2.ProductCode;

        ReturnRequestService.ReturnInput badReason = input('BOR-001', recent.OrderNumber, product, 1);
        badReason.reason = 'Changed my mind';
        ReturnRequestService.ReturnInput wrongContact = input('BOR-001', recent.OrderNumber, product, 1);
        wrongContact.contactId = [SELECT Id FROM Contact WHERE Account.Partner_Code__c = 'KES-002' LIMIT 1].Id;
        ReturnRequestService.ReturnInput noAccount = input('BOR-001', recent.OrderNumber, product, 1);
        noAccount.accountId = null;

        List<ReturnRequestService.ReturnResult> results = create(
            new List<ReturnRequestService.ReturnInput>{
                input('BOR-001', processing.OrderNumber, processing.OrderItems[0].Product2.ProductCode, 1),
                input('BOR-001', old.OrderNumber, old.OrderItems[0].Product2.ProductCode, 1),
                input('BOR-001', otherPartners.OrderNumber, otherPartners.OrderItems[0].Product2.ProductCode, 1),
                input('BOR-001', recent.OrderNumber, 'flux capacitor', 1),
                input('BOR-001', recent.OrderNumber, product, 1000),
                input('BOR-001', recent.OrderNumber, product, 0),
                input('BOR-001', null, product, 1),
                input('BOR-001', recent.OrderNumber, ' ', 1),
                badReason,
                wrongContact,
                noAccount
            }
        );

        List<String> expected = new List<String>{
            'NOT_DELIVERED',
            'RETURN_WINDOW_CLOSED',
            'ORDER_NOT_FOUND',
            'PRODUCT_NOT_ON_ORDER',
            'QUANTITY_EXCEEDS_ORDER',
            'INVALID_QUANTITY',
            'ORDER_REQUIRED',
            'PRODUCT_REQUIRED',
            'INVALID_REASON',
            'INVALID_CONTACT',
            'MISSING_ACCOUNT'
        };
        for (Integer i = 0; i < expected.size(); i++) {
            Assert.isFalse(results[i].success, 'Case ' + i + ' should fail');
            Assert.areEqual(expected[i], results[i].errorCode, 'Case ' + i + ': ' + results[i].message);
            Assert.isTrue(String.isNotBlank(results[i].message), 'Every error explains itself');
        }
        Assert.areEqual(3, [SELECT COUNT() FROM Return_Request__c], 'Nothing was saved beyond the seed data');
    }

    @IsTest
    static void openRequestsAndRequestsInTheSameCallCountAgainstTheOrderedQuantity() {
        Order parent = DistributorTestData.recentDeliveredOrder('BOR-001');
        Return_Request__c seeded = [
            SELECT Product__c, Quantity__c
            FROM Return_Request__c
            WHERE Order__c = :parent.Id
            LIMIT 1
        ];
        Decimal ordered = 0;
        String productCode;
        for (OrderItem item : parent.OrderItems) {
            if (item.Product2Id == seeded.Product__c) {
                ordered += item.Quantity;
                productCode = item.Product2.ProductCode;
            }
        }
        Integer remaining = (ordered - seeded.Quantity__c).intValue();

        List<ReturnRequestService.ReturnResult> results = create(
            new List<ReturnRequestService.ReturnInput>{
                input('BOR-001', parent.OrderNumber, productCode, remaining),
                input('BOR-001', parent.OrderNumber, productCode, 1)
            }
        );

        Assert.isTrue(results[0].success, results[0].message);
        Assert.areEqual(
            'QUANTITY_EXCEEDS_ORDER',
            results[1].errorCode,
            'The first request in the call used up the rest'
        );
    }

    @IsTest
    static void rejectedRequestsDoNotCount() {
        Order parent = DistributorTestData.recentDeliveredOrder('BOR-001');
        Return_Request__c seeded = [
            SELECT Id, Product__c, Quantity__c
            FROM Return_Request__c
            WHERE Order__c = :parent.Id
            LIMIT 1
        ];
        update new Return_Request__c(Id = seeded.Id, Status__c = 'Rejected');
        Decimal ordered = 0;
        String productCode;
        for (OrderItem item : parent.OrderItems) {
            if (item.Product2Id == seeded.Product__c) {
                ordered += item.Quantity;
                productCode = item.Product2.ProductCode;
            }
        }

        ReturnRequestService.ReturnResult result = create(
            new List<ReturnRequestService.ReturnInput>{
                input('BOR-001', parent.OrderNumber, productCode, ordered.intValue())
            }
        )[0];

        Assert.isTrue(result.success, result.message);
    }

    @IsTest
    static void bulkCreateUsesAFixedNumberOfQueriesAndOneInsert() {
        List<ReturnRequestService.ReturnInput> inputs = new List<ReturnRequestService.ReturnInput>();
        for (String partnerCode : new List<String>{ 'BOR-001', 'KES-002', 'MAR-003' }) {
            Id accountId = DistributorTestData.partnerId(partnerCode);
            Order parent = DistributorTestData.recentDeliveredOrder(partnerCode);
            String product = lineWithoutReturns(parent).Product2.ProductCode;
            for (Integer i = 0; i < 60; i++) {
                inputs.add(inputFor(accountId, parent.OrderNumber, product, 1));
            }
        }

        List<ReturnRequestService.ReturnResult> results;
        Integer queriesUsed;
        Integer dmlUsed;
        System.runAs(DistributorTestData.dataAdmin()) {
            Integer queriesBefore = Limits.getQueries();
            Integer dmlBefore = Limits.getDmlStatements();
            results = ReturnRequestService.createReturns(inputs);
            queriesUsed = Limits.getQueries() - queriesBefore;
            dmlUsed = Limits.getDmlStatements() - dmlBefore;
        }

        Assert.areEqual(180, results.size());
        Assert.isTrue(queriesUsed <= 4, 'Expected at most 4 queries, used ' + queriesUsed);
        Assert.areEqual(1, dmlUsed);
        Integer created = 0;
        for (ReturnRequestService.ReturnResult result : results) {
            if (result.success) {
                created++;
            } else {
                Assert.areEqual('QUANTITY_EXCEEDS_ORDER', result.errorCode, result.message);
            }
        }
        Assert.isTrue(created > 0 && created < 180, 'Requests are accepted until each order line is used up');
    }
}
