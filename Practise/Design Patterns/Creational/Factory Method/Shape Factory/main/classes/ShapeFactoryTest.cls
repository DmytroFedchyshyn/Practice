@IsTest
private class ShapeFactoryTest {

    @IsTest
    static void testGetShape() {
        Shape shape1 = ShapeFactory.getShape('CIRCLE');
        Shape shape2 = ShapeFactory.getShape('RECTANGLE');
        Shape shape3 = ShapeFactory.getShape('SQUARE');
        Shape shape4 = ShapeFactory.getShape('Wring Shape');

        Assert.isTrue(shape1 instanceof Circle);
        Assert.isTrue(shape2 instanceof Rectangle);
        Assert.isTrue(shape3 instanceof Square);
        Assert.areEqual(null, shape4);
    }

}