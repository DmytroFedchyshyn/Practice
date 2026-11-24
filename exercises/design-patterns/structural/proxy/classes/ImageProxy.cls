public with sharing class ImageProxy implements Image {
    private HighResolutionImage image;
    private String filename;

    public ImageProxy(String filename) {
        this.filename = filename;
    }

    public void display() {
        if (image == null) {
            image = new HighResolutionImage(filename);
        }
        image.display();
    }
}
