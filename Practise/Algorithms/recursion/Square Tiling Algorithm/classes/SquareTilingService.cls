public without sharing class SquareTilingService {

    public static Integer calculate(Integer a, Integer b) {
        if (b == 0) {
            return a;
        } else {
            return calculate(b, Math.mod(a, b));
        }
    }

}