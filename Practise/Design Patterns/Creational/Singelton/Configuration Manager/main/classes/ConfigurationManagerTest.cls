@IsTest
private class ConfigurationManagerTest {

    @IsTest
    private static void getInstanceTest() {
        Test.startTest();
        ConfigurationManager instance = ConfigurationManager.getInstance();
        Test.stopTest();

        Assert.areEqual(instance, ConfigurationManager.getInstance());
    }

    @IsTest
    private static void getConfigurationByNameTest() {
        String configName = 'test';
        String configValue = 'test';
        createConfiguration(configName, configValue);
        ConfigurationManager configManager = ConfigurationManager.getInstance();
        Test.startTest();
        Configuration__c configuration = configManager.getConfigurationByName(configName);
        Test.stopTest();

        Assert.areEqual(configName, configuration.Name);
        Assert.areEqual(configValue, configuration.Value__c);
    }

    @IsTest
    private static void updateConfigurationValueTest() {
        String configName = 'test';
        String configValue = 'test';
        String updatedValue = 'value';
        createConfiguration(configName, configValue);
        ConfigurationManager configManager = ConfigurationManager.getInstance();
        Test.startTest();
        Configuration__c configuration = configManager.updateConfigurationValue(configName, updatedValue);
        Test.stopTest();


        Assert.areEqual(configName, configuration.Name);
        Assert.areEqual(updatedValue, configuration.Value__c);
    }

    private static void createConfiguration(String name, String value) {
        Configuration__c configuration = new Configuration__c();
        configuration.Name = name;
        configuration.Value__c = value;
        insert configuration;
    }

}