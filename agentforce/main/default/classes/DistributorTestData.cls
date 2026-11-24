/**
 * Shared test setup for the distributor classes: seed data plus a user who has
 * exactly the data access the permission set grants. The service classes query in
 * user mode, so tests must run as a user whose field access is known, not as
 * whoever happens to deploy.
 */
@IsTest
public class DistributorTestData {
    private static final String TEST_USER_LAST_NAME = 'Distributor Data Admin Test';

    /** Call from @TestSetup. */
    public static void setUp() {
        // Users and permission set assignments are setup objects. Inserting them in a
        // runAs block keeps them apart from the seed data DML (no MIXED_DML_OPERATION).
        System.runAs(new User(Id = UserInfo.getUserId())) {
            createDataAdmin();
        }
        SeedData.run();
    }

    public static User dataAdmin() {
        return [SELECT Id FROM User WHERE LastName = :TEST_USER_LAST_NAME LIMIT 1];
    }

    public static Id partnerId(String partnerCode) {
        return [SELECT Id FROM Account WHERE Partner_Code__c = :partnerCode].Id;
    }

    /** The most recently delivered order of a partner (inside the return window in seed data). */
    public static Order recentDeliveredOrder(String partnerCode) {
        return deliveredOrder(partnerCode, 'DESC');
    }

    /** The oldest delivered order of a partner (outside the return window in seed data). */
    public static Order oldDeliveredOrder(String partnerCode) {
        return deliveredOrder(partnerCode, 'ASC');
    }

    public static Order orderWithStatus(String partnerCode, String fulfillmentStatus) {
        return [
            SELECT Id, OrderNumber, (SELECT Product2Id, Product2.ProductCode, Product2.Name, Quantity FROM OrderItems ORDER BY OrderItemNumber)
            FROM Order
            WHERE Account.Partner_Code__c = :partnerCode AND Fulfillment_Status__c = :fulfillmentStatus
            LIMIT 1
        ];
    }

    private static Order deliveredOrder(String partnerCode, String direction) {
        List<Order> orders = [
            SELECT
                Id,
                OrderNumber,
                Delivered_Date__c,
                (SELECT Product2Id, Product2.ProductCode, Product2.Name, Quantity FROM OrderItems ORDER BY OrderItemNumber)
            FROM Order
            WHERE Account.Partner_Code__c = :partnerCode AND Fulfillment_Status__c = 'Delivered'
            ORDER BY Delivered_Date__c DESC
        ];
        return direction == 'DESC' ? orders[0] : orders[orders.size() - 1];
    }

    private static void createDataAdmin() {
        Profile admin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            LastName = TEST_USER_LAST_NAME,
            Alias = 'dstadm',
            Email = 'distributor.data.admin@example.com',
            Username = 'distributor.data.admin.' + UserInfo.getOrganizationId() + '@example.com',
            ProfileId = admin.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Kyiv'
        );
        insert testUser;
        PermissionSet dataAccess = [SELECT Id FROM PermissionSet WHERE Name = 'Distributor_Data_Admin'];
        insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = dataAccess.Id);
    }
}
