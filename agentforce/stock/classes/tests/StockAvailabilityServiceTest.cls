@IsTest
private class StockAvailabilityServiceTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    private static List<StockAvailabilityService.StockResult> check(List<String> terms) {
        List<StockAvailabilityService.StockResult> results;
        System.runAs(DistributorTestData.dataAdmin()) {
            results = StockAvailabilityService.checkStock(terms);
        }
        return results;
    }

    @IsTest
    static void findsProductByCodeIgnoringCase() {
        StockAvailabilityService.StockResult result = check(new List<String>{ 'dst-1001' })[0];

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(1, result.products.size());
        StockAvailabilityService.ProductStock drill = result.products[0];
        Assert.areEqual('DST-1001', drill.productCode);
        Assert.areEqual(2, drill.warehouses.size());
        Assert.areEqual((240 - 30) + (85 - 10), drill.totalAvailable, 'On hand minus reserved, summed over warehouses');
    }

    @IsTest
    static void findsProductByPartOfName() {
        StockAvailabilityService.StockResult result = check(new List<String>{ 'grinder' })[0];

        Assert.isTrue(result.success, result.message);
        Assert.areEqual('DST-1002', result.products[0].productCode);
        Assert.areEqual(120, result.products[0].totalAvailable);
    }

    @IsTest
    static void outOfStockProductIsASuccessWithZero() {
        StockAvailabilityService.StockResult result = check(new List<String>{ 'Torque Wrench' })[0];

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(0, result.products[0].totalAvailable);
    }

    @IsTest
    static void tooManyMatchesAsksForSomethingMoreSpecific() {
        StockAvailabilityService.StockResult result = check(new List<String>{ 'e' })[0];

        Assert.isFalse(result.success);
        Assert.areEqual('AMBIGUOUS_PRODUCT', result.errorCode);
        Assert.isTrue(result.message.contains('DST-1001'), 'The message lists the matches');
        Assert.isTrue(result.message.contains('matches 7 products'), result.message);
        Assert.isTrue(result.message.endsWith(' and 2 more.'), 'Only the first ' + StockAvailabilityService.MAX_MATCHES + ' are listed: ' + result.message);
        Assert.isTrue(result.products.isEmpty());
    }

    @IsTest
    static void unknownAndBlankProductsAreErrors() {
        List<StockAvailabilityService.StockResult> results = check(new List<String>{ 'flux capacitor', ' ', null, '100%' });

        Assert.areEqual('PRODUCT_NOT_FOUND', results[0].errorCode);
        Assert.areEqual('PRODUCT_REQUIRED', results[1].errorCode);
        Assert.areEqual('PRODUCT_REQUIRED', results[2].errorCode);
        Assert.areEqual('PRODUCT_NOT_FOUND', results[3].errorCode, 'A typed % is not a wildcard');
    }

    @IsTest
    static void inactiveWarehousesDoNotCount() {
        update new Warehouse__c(Id = [SELECT Id FROM Warehouse__c WHERE Code__c = 'WST'].Id, Is_Active__c = false);

        StockAvailabilityService.StockResult result = check(new List<String>{ 'DST-1001' })[0];

        Assert.areEqual(1, result.products[0].warehouses.size());
        Assert.areEqual('CEN', result.products[0].warehouses[0].warehouseCode);
        Assert.areEqual(240 - 30, result.products[0].totalAvailable);
    }

    @IsTest
    static void bulkCheckUsesAFixedNumberOfQueries() {
        List<String> terms = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            terms.add('DST-100' + (Math.mod(i, 3) + 1));
        }

        List<StockAvailabilityService.StockResult> results;
        Integer queriesUsed;
        System.runAs(DistributorTestData.dataAdmin()) {
            Integer before = Limits.getQueries();
            results = StockAvailabilityService.checkStock(terms);
            queriesUsed = Limits.getQueries() - before;
        }

        Assert.areEqual(200, results.size());
        Assert.isTrue(queriesUsed <= 2, 'Expected at most 2 queries, used ' + queriesUsed);
    }
}
