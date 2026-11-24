public with sharing class ConfigurationManager {

    private static ConfigurationManager instance;

    private ConfigurationManager() {}

    public static ConfigurationManager getInstance() {
        if (instance == null) {
            instance = new ConfigurationManager();
        }
        return instance;
    }

    public Configuration__c getConfigurationByName(String configName) {
        return [SELECT Id, Name, Value__c FROM Configuration__c WHERE Name = :configName LIMIT 1];
    }

    public Configuration__c updateConfigurationValue(String configName, String value) {
        Configuration__c config = this.getConfigurationByName(configName);
        config.Value__c = value;
        update config;
        return config;
    }

    public Configuration__c updateConfigurationValue(Configuration__c config, String value) {
        config.Value__c = value;
        update config;
        return config;
    }
}