public without sharing class BreadthFirstSearcher {

    public Person search(Map<String, List<Person>> friendsByName, String name) {
        if (friendsByName.isEmpty() || !friendsByName.containsKey(name)) {
            return null;
        }

        Set<Double> checkedFriends = new Set<Double>();
        PersonQueue personQueue = new PersonQueue();
        personQueue.addAll(friendsByName.get(name));

        while (!personQueue.isEmpty()) {
            Person person = personQueue.pop();

            if (!checkedFriends.contains(person.id)) {
                if (person.isMangoSeller) {
                    return person;
                }
                checkedFriends.add(person.id);
                personQueue.addAll(friendsByName.get(person.name));
            }
        }
        return null;
    }

    public class PersonQueue {
        private List<Person> peopleQueue = new List<Person>();

        public void addAll(List<Person> persons) {
            this.peopleQueue.addAll(persons);
        }

        public Person pop() {
            return !this.peopleQueue.isEmpty() ? this.peopleQueue.remove(0) : null;
        }

        public Boolean isEmpty() {
            return this.peopleQueue.isEmpty();
        }
    }

    private static Double nextId = 0.0;

    private static Double getNextId() {
        return nextId++;
    }

    public class Person {
        private Double id;
        public String name = '';
        private Boolean isMangoSeller = false;

        public Person(String name, Boolean isMangoSeller) {
            this.id = getNextId();
            this.name = name;
            this.isMangoSeller = isMangoSeller;
        }
    }
}
