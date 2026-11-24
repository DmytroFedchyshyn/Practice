@IsTest
private class ReturnRequestFactsServiceTest {
    private static final Date TODAY = Date.newInstance(2026, 11, 24);

    @TestSetup
    static void setUp() {
        DistributorTestData.setUp();
    }

    private static ReturnRequestFactsService.FactsInput input(String requestNumber, Id accountId) {
        ReturnRequestFactsService.FactsInput input = new ReturnRequestFactsService.FactsInput();
        input.requestNumber = requestNumber;
        input.accountId = accountId;
        return input;
    }

    private static List<String> describe(List<ReturnRequestFactsService.FactsInput> inputs) {
        List<String> facts;
        System.runAs(DistributorTestData.dataAdmin()) {
            facts = ReturnRequestFactsService.describe(inputs, TODAY);
        }
        return facts;
    }

    /** The seeded Kestrel request: Approved, with resolution notes. */
    private static Return_Request__c kestrelRequest() {
        return [
            SELECT Name, Account__c, Order__r.OrderNumber, Product__r.Name
            FROM Return_Request__c
            WHERE Account__r.Partner_Code__c = 'KES-002'
            LIMIT 1
        ];
    }

    @IsTest
    static void describesARequestOfThePartner() {
        Return_Request__c request = kestrelRequest();

        String facts = describe(new List<ReturnRequestFactsService.FactsInput>{ input(request.Name, request.Account__c) })[0];

        Assert.isTrue(facts.contains('Return request: ' + request.Name), facts);
        Assert.isTrue(facts.contains('Status: Approved'), facts);
        Assert.isTrue(facts.contains('Order: ' + request.Order__r.OrderNumber), facts);
        Assert.isTrue(facts.contains('Product: ' + request.Product__r.Name), facts);
        Assert.isTrue(facts.contains('days after delivery'), facts);
        Assert.isTrue(facts.contains('Resolution notes from the returns team: Approved.'), facts);
        Assert.isTrue(facts.contains('Next step: ' + ReturnPolicy.nextStep('Approved')), facts);
        Assert.isTrue(facts.contains('Return policy: ' + ReturnPolicy.POLICY_SUMMARY), facts);
        Assert.isTrue(facts.contains('Today: 2026-11-24'), facts);
    }

    @IsTest
    static void acceptsTheNumberAsPartnersTypeIt() {
        Return_Request__c request = kestrelRequest();
        String typed = 'rr ' + Integer.valueOf(request.Name.replaceAll('[^0-9]', ''));

        String facts = describe(new List<ReturnRequestFactsService.FactsInput>{ input(typed, request.Account__c) })[0];

        Assert.isTrue(facts.contains('Return request: ' + request.Name), facts);
    }

    @IsTest
    static void requestOfAnotherPartnerLooksMissing() {
        Return_Request__c request = kestrelRequest();
        Id borealis = DistributorTestData.partnerId('BOR-001');

        List<String> facts = describe(
            new List<ReturnRequestFactsService.FactsInput>{ input(request.Name, borealis), input('RR-99999', borealis) }
        );

        Assert.areEqual(facts[1].replace('RR-99999', request.Name), facts[0], 'Same answer as for a number that does not exist');
        Assert.isTrue(facts[0].startsWith('No return request ' + request.Name + ' was found'), facts[0]);
    }

    @IsTest
    static void blankNumberAndInvalidAccountAreHandled() {
        Return_Request__c request = kestrelRequest();

        List<String> facts = describe(
            new List<ReturnRequestFactsService.FactsInput>{ input(' ', request.Account__c), input(request.Name, null) }
        );
        ReturnRequestFactsService.FactsInput notAnId = input(request.Name, null);
        notAnId.accountId = 'not an id';
        String notAnIdFacts = describe(new List<ReturnRequestFactsService.FactsInput>{ notAnId })[0];

        Assert.isTrue(facts[0].startsWith('No return request number was given'), facts[0]);
        Assert.isTrue(facts[1].startsWith('No return request ' + request.Name + ' was found'), facts[1]);
        Assert.isTrue(notAnIdFacts.startsWith('No return request ' + request.Name + ' was found'), notAnIdFacts);
    }

    @IsTest
    static void bulkUsesOneQuery() {
        Return_Request__c request = kestrelRequest();
        List<ReturnRequestFactsService.FactsInput> inputs = new List<ReturnRequestFactsService.FactsInput>();
        for (Integer i = 0; i < 200; i++) {
            inputs.add(input(request.Name, request.Account__c));
        }

        List<String> facts;
        Integer queriesUsed;
        System.runAs(DistributorTestData.dataAdmin()) {
            Integer before = Limits.getQueries();
            facts = ReturnRequestFactsService.describe(inputs, TODAY);
            queriesUsed = Limits.getQueries() - before;
        }

        Assert.areEqual(200, facts.size());
        Assert.areEqual(1, queriesUsed);
    }
}
