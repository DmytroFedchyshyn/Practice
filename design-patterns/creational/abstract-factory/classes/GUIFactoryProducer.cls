public with sharing class GUIFactoryProducer {

    public static GUIFactory getFactory(String platform) {
        if (platform.equalsIgnoreCase('Windows')) {
            return new WindowsFactory();
        } else if (platform.equalsIgnoreCase('MacOS')) {
            return new MacOSFactory();
        }
        return null;
    }
}