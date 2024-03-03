public with sharing class HighResolutionImage implements Image{

    public String filename;

    public HighResolutionImage(String filename) {
        this.filename = filename;
        loadImage();
    }

    private void loadImage() {
        // Simulate loading a large image file
        System.debug('Loading image ' + filename);
    }

    public void display() {
        System.debug('Displaying image ' + filename);
    }
}