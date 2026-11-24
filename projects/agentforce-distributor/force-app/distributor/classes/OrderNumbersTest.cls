@IsTest
private class OrderNumbersTest {
    @IsTest
    static void normalizesWhatPartnersType() {
        Assert.areEqual('00000103', OrderNumbers.normalize('103'));
        Assert.areEqual('00000103', OrderNumbers.normalize('order #103'));
        Assert.areEqual('00000103', OrderNumbers.normalize('00000103'));
        Assert.areEqual('123456789', OrderNumbers.normalize('123456789'));
        Assert.areEqual('abc', OrderNumbers.normalize(' abc '), 'No digits: kept as is, so it matches nothing');
        Assert.isNull(OrderNumbers.normalize(' '));
        Assert.isNull(OrderNumbers.normalize(null));
    }

    @IsTest
    static void keyCombinesPartnerAndNumber() {
        Id accountId = '001000000000001';
        Assert.areEqual(String.valueOf(accountId) + ':00000103', OrderNumbers.key(accountId, '00000103'));
    }
}
