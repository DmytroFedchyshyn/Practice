@IsTest
private class SeedDataTest {
    @IsTest
    static void runCreatesTheWholeDataSet() {
        Test.startTest();
        Map<String, Integer> counts = SeedData.run();
        Test.stopTest();

        Assert.areEqual(3, counts.get('Account'), 'One account per partner');
        Assert.areEqual(3, [SELECT COUNT() FROM Account WHERE Partner_Code__c != NULL]);
        Assert.areEqual(6, [SELECT COUNT() FROM Contact WHERE Account.Partner_Code__c != NULL]);
        Assert.areEqual(8, [SELECT COUNT() FROM Product2 WHERE ProductCode LIKE :(SeedData.PRODUCT_CODE_PREFIX + '%')]);
        Assert.areEqual(16, [SELECT COUNT() FROM Stock_Level__c], 'Every product in both warehouses');
        Assert.areEqual(18, [SELECT COUNT() FROM Order], 'Six orders per partner');
        Assert.areEqual(36, [SELECT COUNT() FROM OrderItem], 'Two lines per order');
        Assert.areEqual(3, [SELECT COUNT() FROM Return_Request__c]);
    }

    @IsTest
    static void ordersCoverEveryFulfillmentStatus() {
        SeedData.run();

        Map<String, Integer> byStatus = new Map<String, Integer>();
        for (AggregateResult row : [SELECT Fulfillment_Status__c status, COUNT(Id) total FROM Order GROUP BY Fulfillment_Status__c]) {
            byStatus.put((String) row.get('status'), (Integer) row.get('total'));
        }
        Assert.areEqual(3, byStatus.get('Processing'));
        Assert.areEqual(3, byStatus.get('Picking'));
        Assert.areEqual(3, byStatus.get('Shipped'));
        Assert.areEqual(6, byStatus.get('Delivered'));
        Assert.areEqual(3, byStatus.get('Cancelled'));

        Assert.areEqual(15, [SELECT COUNT() FROM Order WHERE Status = 'Activated'], 'Everything but cancelled orders is activated');
        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Order WHERE Fulfillment_Status__c = 'Delivered' AND (Delivered_Date__c = NULL OR Tracking_Number__c = NULL)],
            'Delivered orders carry a delivery date and a tracking number'
        );
    }

    @IsTest
    static void stockMixIncludesOutOfStockAndFullyReserved() {
        SeedData.run();

        Assert.isTrue([SELECT COUNT() FROM Stock_Level__c WHERE Quantity_On_Hand__c = 0] > 0, 'Some products are out of stock');
        Assert.isTrue(
            [SELECT COUNT() FROM Stock_Level__c WHERE Quantity_On_Hand__c > 0 AND Quantity_Available__c = 0] > 0,
            'Some stock is fully reserved'
        );
        Assert.areEqual(0, [SELECT COUNT() FROM Stock_Level__c WHERE Quantity_Available__c < 0], 'Never more reserved than on hand');
    }

    @IsTest
    static void returnRequestsBelongToTheOrderAccount() {
        SeedData.run();

        for (Return_Request__c request : [SELECT Account__c, Order__r.AccountId, Product__c, Requested_By__r.AccountId FROM Return_Request__c]) {
            Assert.areEqual(request.Order__r.AccountId, request.Account__c, 'Request and order share the partner');
            Assert.areEqual(request.Account__c, request.Requested_By__r.AccountId, 'Requester works for the partner');
            Assert.isNotNull(request.Product__c);
        }
    }

    @IsTest
    static void runIsRepeatable() {
        SeedData.run();
        Set<Id> firstRunOrders = new Map<Id, Order>([SELECT Id FROM Order]).keySet();

        Test.startTest();
        SeedData.run();
        Test.stopTest();

        Assert.areEqual(3, [SELECT COUNT() FROM Account WHERE Partner_Code__c != NULL], 'Accounts are updated, not duplicated');
        Assert.areEqual(6, [SELECT COUNT() FROM Contact WHERE Account.Partner_Code__c != NULL]);
        Assert.areEqual(8, [SELECT COUNT() FROM Product2 WHERE ProductCode LIKE :(SeedData.PRODUCT_CODE_PREFIX + '%')]);
        Assert.areEqual(1, [SELECT COUNT() FROM Pricebook2 WHERE Name = :SeedData.PRICE_BOOK_NAME]);
        Assert.areEqual(16, [SELECT COUNT() FROM Stock_Level__c]);
        Assert.areEqual(18, [SELECT COUNT() FROM Order], 'Orders are rebuilt, not appended');
        Assert.areEqual(0, [SELECT COUNT() FROM Order WHERE Id IN :firstRunOrders], 'Old orders are gone');
        Assert.areEqual(3, [SELECT COUNT() FROM Return_Request__c]);
    }
}
