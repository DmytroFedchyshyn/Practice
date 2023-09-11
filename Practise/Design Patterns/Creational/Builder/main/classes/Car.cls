public class Car {
    private final String make;
    private final String model;
    private final Integer year;
    private final String color;

    private Car(Builder builder) {
        this.make = builder.make;
        this.model = builder.model;
        this.year = builder.year;
        this.color = builder.color;
    }

    public class Builder {
        private final String make;
        private final String model;
        private Integer year;
        private String color;

        public Builder(String make, String model) {
            this.make = make;
            this.model = model;
        }

        public Builder year(Integer year) {
            this.year = year;
            return this;
        }

        public Builder color(String color) {
            this.color = color;
            return this;
        }

        public Car build() {
            return new Car(this);
        }
    }
}
