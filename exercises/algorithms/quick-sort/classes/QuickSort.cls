public without sharing class QuickSort {

        public List<Integer> sort(List<Integer> arr) {
            if (arr == null || arr.size() < 2) {
                return arr;
            }

            List<Integer> nonNulls = new List<Integer>();
            for (Integer num : arr) {
                if (num != null) {
                    nonNulls.add(num);
                }
            }

            nonNulls = quickSort(nonNulls);
            return nonNulls;
        }

        private List<Integer> quickSort(List<Integer> arr) {
            if (arr.size() < 2) {
                return arr;
            }

            Integer pivot = arr[0];
            List<Integer> less = new List<Integer>();
            List<Integer> greater = new List<Integer>();

            for (Integer i = 1; i < arr.size(); i++) {
                if (arr[i] < pivot) {
                    less.add(arr[i]);
                } else {
                    greater.add(arr[i]);
                }
            }

            List<Integer> sorted = quickSort(less);
            sorted.add(pivot);
            sorted.addAll(quickSort(greater));

            return sorted;
        }
}