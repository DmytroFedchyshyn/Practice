/**
 * The invocable wrapper passes inputs through and formats results as text for the agent.
 * Business rules are tested in StockAvailabilityServiceTest.
 */
@IsTest
private class CheckProductStockActionTest {
    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    @IsTest
    static void listsWarehousesAndPassesErrorsOn() {
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
    static void saysWhenNothingIsStocked() {
        StockAvailabilityService.ProductStock product = new StockAvailabilityService.ProductStock();
        product.productCode = 'DST-9999';
        product.productName = 'Discontinued Item';

        Assert.areEqual(
            'Discontinued Item (DST-9999): 0 available in total. Not stocked in any active warehouse.',
            CheckProductStockAction.format(product)
        );
    }
}
