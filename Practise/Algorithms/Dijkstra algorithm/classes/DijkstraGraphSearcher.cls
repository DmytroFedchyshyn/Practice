
public without sharing class DijkstraGraphSearcher {

    public Integer findCost(Map<String, Set<Node>> graph) {
        if (graph.isEmpty()) {
            return null;
        }

        Set<String> processedNodes = new Set<String>();
        Map<String, Double> costByVertex = new Map<String, Double>();
        Map<String, String> previousNodeMap = new Map<String, String>();

        for (String vertex : graph.keySet()) {
            costByVertex.put(vertex, null); // null represents infinity
            previousNodeMap.put(vertex, null);
        }
        costByVertex.put('Start', 0.0);

        Node node = findLowestCostNode(costByVertex, processedNodes);
        while (node != null) {
            Double cost = costByVertex.get(node.name);
            Set<Node> neighbors = graph.get(node.name);
            for (Node neighbor : neighbors) {
                Double newCost = cost + neighbor.value;
                Double currentNeighborCost = costByVertex.get(neighbor.name);
                if (currentNeighborCost == null || newCost < currentNeighborCost) {
                    costByVertex.put(neighbor.name, newCost);
                    previousNodeMap.put(neighbor.name, node.name);
                }
            }
            processedNodes.add(node.name);
            node = findLowestCostNode(costByVertex, processedNodes);
        }


        return null;
    }

    private Node findLowestCostNode(Map<String, Double> costByVertex, Set<String> processedNodes) {
        Double lowest = null;
        String lowestNodeName = null;
        for (String vertex : costByVertex.keySet()) {
            Double cost = costByVertex.get(vertex);
            if (!processedNodes.contains(vertex) && (lowest == null || (cost != null && cost < lowest))) {
                lowest = cost;
                lowestNodeName = vertex;
            }
        }
        return lowestNodeName != null ? new Node(lowestNodeName, lowest) : null;
    }

    public class Node {
        private final String name;
        private final Double value;

        public Node(String name, Double value) {
            this.name = name;
            this.value = value;
        }
    }
}