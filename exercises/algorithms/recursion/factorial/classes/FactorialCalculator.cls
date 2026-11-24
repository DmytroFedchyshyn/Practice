public without sharing class FactorialCalculator {

    public Integer calculate(Integer numberF) {
        if (numberF == 1) {
            return numberF;
        }
        return numberF * this.calculate(numberF - 1);
    }
}