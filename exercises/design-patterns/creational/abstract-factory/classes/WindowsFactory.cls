public with sharing class WindowsFactory implements GUIFactory {
    public Button createButton() {
        return new WindowsButton();
    }

    public CheckBox createCheckBox() {
        return new WindowCheckbox();
    }
}