/**
 * The policy is pure logic on records in memory, so these tests need no data and no user.
 */
@IsTest
private class ReturnPolicyTest {
    private static final Date TODAY = Date.newInstance(2026, 11, 24);

    private static Order deliveredDaysAgo(Integer days) {
        return new Order(Fulfillment_Status__c = 'Delivered', Delivered_Date__c = TODAY.addDays(-days));
    }

    @IsTest
    static void acceptsDeliveredOrdersInsideTheWindow() {
        Assert.isNull(ReturnPolicy.checkOrder(deliveredDaysAgo(0), '00000001', TODAY));
        Assert.isNull(
            ReturnPolicy.checkOrder(deliveredDaysAgo(ReturnPolicy.RETURN_WINDOW_DAYS), '00000001', TODAY),
            'The last day still counts'
        );
    }

    @IsTest
    static void rejectsOrdersOutsideTheWindow() {
        ReturnPolicy.Violation violation = ReturnPolicy.checkOrder(
            deliveredDaysAgo(ReturnPolicy.RETURN_WINDOW_DAYS + 1),
            '00000001',
            TODAY
        );

        Assert.areEqual('RETURN_WINDOW_CLOSED', violation.code);
        Assert.isTrue(violation.message.contains('31 days ago'), violation.message);
    }

    @IsTest
    static void rejectsOrdersThatAreNotDelivered() {
        Assert.areEqual(
            'NOT_DELIVERED',
            ReturnPolicy.checkOrder(new Order(Fulfillment_Status__c = 'Shipped'), '00000001', TODAY).code
        );
        Assert.areEqual(
            'NOT_DELIVERED',
            ReturnPolicy.checkOrder(new Order(Fulfillment_Status__c = 'Delivered'), '00000001', TODAY).code,
            'Delivered without a delivery date is treated as not delivered'
        );
    }

    @IsTest
    static void sumsOrderedQuantityOverLinesOfTheSameProduct() {
        Id drill = '01t000000000001';
        Id grinder = '01t000000000002';
        List<OrderItem> lines = new List<OrderItem>{
            new OrderItem(Product2Id = drill, Quantity = 3),
            new OrderItem(Product2Id = grinder, Quantity = 5),
            new OrderItem(Product2Id = drill, Quantity = 2)
        };

        Assert.areEqual(5, ReturnPolicy.orderedQuantity(lines, drill));
        Assert.areEqual(0, ReturnPolicy.orderedQuantity(lines, '01t000000000003'));
    }

    @IsTest
    static void everyStatusHasANextStep() {
        for (Schema.PicklistEntry status : Return_Request__c.Status__c.getDescribe().getPicklistValues()) {
            Assert.areNotEqual(
                ReturnPolicy.nextStep('unknown'),
                ReturnPolicy.nextStep(status.getValue()),
                'Missing next step for ' + status.getValue()
            );
        }
        Assert.isTrue(ReturnPolicy.nextStep(null).startsWith('Contact the returns team'));
    }

    @IsTest
    static void limitsQuantityToWhatIsLeft() {
        Assert.isNull(ReturnPolicy.checkQuantity('00000001', 'Drill', 8, 1, 7), 'Exactly what is left');

        ReturnPolicy.Violation tooMany = ReturnPolicy.checkQuantity('00000001', 'Drill', 8, 1, 8);
        Assert.areEqual('QUANTITY_EXCEEDS_ORDER', tooMany.code);
        Assert.isTrue(tooMany.message.contains('at most 7 more'), tooMany.message);

        Assert.areEqual('INVALID_QUANTITY', ReturnPolicy.checkQuantity('00000001', 'Drill', 8, 0, 0).code);
        Assert.areEqual('INVALID_QUANTITY', ReturnPolicy.checkQuantity('00000001', 'Drill', 8, 0, null).code);
    }
}
