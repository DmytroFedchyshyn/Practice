@IsTest
private class PartnerOrderServiceTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void findsOrderByShortNumber() {
        Order shipped = DistributorTestData.orderWithStatus('BOR-001', 'Shipped');
        String shortNumber = '#' + String.valueOf(Integer.valueOf(shipped.OrderNumber));

        List<PartnerOrderService.OrderResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = PartnerOrderService.getOrders(
                new List<PartnerOrderService.OrderLookup>{ new PartnerOrderService.OrderLookup(DistributorTestData.partnerId('BOR-001'), shortNumber) }
            );
        }

        PartnerOrderService.OrderResult result = results[0];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual(1, result.orders.size());
        PartnerOrderService.OrderSummary summary = result.orders[0];
        Assert.areEqual(shipped.OrderNumber, summary.orderNumber);
        Assert.areEqual('Shipped', summary.fulfillmentStatus);
        Assert.isNotNull(summary.trackingNumber, 'Shipped orders carry a tracking number');
        Assert.isNotNull(summary.expectedDeliveryDate);
        Assert.areEqual(2, summary.lines.size());
    }

    @IsTest
    static void orderOfAnotherPartnerLooksLikeAMissingOrder() {
        Order otherPartners = DistributorTestData.orderWithStatus('KES-002', 'Shipped');

        List<PartnerOrderService.OrderResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = PartnerOrderService.getOrders(
                new List<PartnerOrderService.OrderLookup>{
                    new PartnerOrderService.OrderLookup(DistributorTestData.partnerId('BOR-001'), otherPartners.OrderNumber),
                    new PartnerOrderService.OrderLookup(DistributorTestData.partnerId('BOR-001'), '99999999')
                }
            );
        }

        Assert.isFalse(results[0].success);
        Assert.areEqual('ORDER_NOT_FOUND', results[0].errorCode);
        Assert.areEqual('ORDER_NOT_FOUND', results[1].errorCode);
        Assert.areEqual(
            results[1].message.replace('99999999', otherPartners.OrderNumber),
            results[0].message,
            'Another partner\'s order gets exactly the same answer as a missing one'
        );
    }

    @IsTest
    static void blankNumberReturnsRecentOrdersNewestFirst() {
        List<PartnerOrderService.OrderResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = PartnerOrderService.getOrders(
                new List<PartnerOrderService.OrderLookup>{ new PartnerOrderService.OrderLookup(DistributorTestData.partnerId('MAR-003'), '  ') }
            );
        }

        PartnerOrderService.OrderResult result = results[0];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual(6, result.orders.size(), 'All seeded orders of the partner, fewer than the limit of 10');
        for (Integer i = 1; i < result.orders.size(); i++) {
            Assert.isTrue(result.orders[i - 1].placedOn >= result.orders[i].placedOn, 'Newest first');
        }
    }

    @IsTest
    static void missingAccountIsAnError() {
        List<PartnerOrderService.OrderResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = PartnerOrderService.getOrders(new List<PartnerOrderService.OrderLookup>{ new PartnerOrderService.OrderLookup(null, '103') });
        }

        Assert.isFalse(results[0].success);
        Assert.areEqual('MISSING_ACCOUNT', results[0].errorCode);
    }

    @IsTest
    static void bulkLookupUsesAFixedNumberOfQueries() {
        List<Order> orders = [SELECT AccountId, OrderNumber FROM Order];
        List<PartnerOrderService.OrderLookup> lookups = new List<PartnerOrderService.OrderLookup>();
        for (Integer i = 0; i < 200; i++) {
            Order record = orders[Math.mod(i, orders.size())];
            String orderNumber = Math.mod(i, 4) == 0 ? null : record.OrderNumber;
            lookups.add(new PartnerOrderService.OrderLookup(record.AccountId, orderNumber));
        }

        List<PartnerOrderService.OrderResult> results;
        Integer queriesUsed;
        System.runAs(DistributorTestData.dataAdmin()) {
            Integer before = Limits.getQueries();
            results = PartnerOrderService.getOrders(lookups);
            queriesUsed = Limits.getQueries() - before;
        }

        Assert.areEqual(200, results.size());
        Assert.isTrue(queriesUsed <= 3, 'Expected at most 3 queries, used ' + queriesUsed);
        for (PartnerOrderService.OrderResult result : results) {
            Assert.isTrue(result.success, result.message);
        }
    }
}
