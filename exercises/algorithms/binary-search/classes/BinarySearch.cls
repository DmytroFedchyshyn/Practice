public without sharing class BinarySearch {
    public Integer count = 0;

    public Integer search(List<Integer> intList, Integer value) {
        Integer first = 0;
        Integer lastV = intList.size() - 1;
        do {
            Integer midVal = (first + lastV) / 2;
            count++;
            Integer currentValue = intList.get(midVal);
            if (currentValue == value) {
                return currentValue;
            } else if (currentValue < value) {
                first = midVal + 1;
            } else if (currentValue > value) {
                lastV = midVal - 1;
            }
        }
        while (first <= lastV);
        return null;
    }
}