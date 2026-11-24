@IsTest
private class ReturnRequestNumbersTest {
    @IsTest
    static void normalizesWhatPartnersType() {
        Assert.areEqual('RR-00012', ReturnRequestNumbers.normalize('RR-00012'));
        Assert.areEqual('RR-00012', ReturnRequestNumbers.normalize(' rr 12 '));
        Assert.areEqual('RR-00012', ReturnRequestNumbers.normalize('12'));
        Assert.areEqual('RR-123456', ReturnRequestNumbers.normalize('123456'), 'Longer numbers are kept');
    }

    @IsTest
    static void keepsTextWithoutDigitsAndIgnoresBlanks() {
        Assert.areEqual('my last request', ReturnRequestNumbers.normalize(' my last request '));
        Assert.isNull(ReturnRequestNumbers.normalize(' '));
        Assert.isNull(ReturnRequestNumbers.normalize(null));
    }
}
