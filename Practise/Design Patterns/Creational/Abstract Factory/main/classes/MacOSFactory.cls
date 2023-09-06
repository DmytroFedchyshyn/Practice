public with sharing class MacOSFactory implements GUIFactory {
    public Button createButton() {
        return new MacOSButton();
    }

    public CheckBox createCheckBox() {
        return new MacOSCheckBox();
    }
}