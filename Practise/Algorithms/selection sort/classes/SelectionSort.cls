public without sharing class SelectionSort {

    public List<Integer> sort(Integer[] arr) {
        if (arr.size() == 0) {
            return new List<Integer>();
        }

        for (Integer i = 0; i < arr.size() - 1; i++) {
            Integer currentlySmallestIndex = this.findSmallestIndex(arr, i);
            Integer temp = arr[i];
            arr[i] = arr[currentlySmallestIndex];
            arr[currentlySmallestIndex] = temp;
        }

        return new List<Integer>(arr);
    }

    private Integer findSmallestIndex(Integer[] arr, Integer startIndex) {
        Integer smallestIndex = startIndex;
        for (Integer i = startIndex + 1; i < arr.size(); i++) {
            if (arr[i] < arr[smallestIndex]) {
                smallestIndex = i;
            }
        }
        return smallestIndex;
    }
}
