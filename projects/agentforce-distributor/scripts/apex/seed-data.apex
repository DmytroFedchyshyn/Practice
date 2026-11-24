// Loads or refreshes the demo data of the distributor: partners, contacts, products, warehouses, stock,
// orders and return requests. WRITES to the org; safe to run more than once (scripts/apex/README.md).
// From this project's folder: sf apex run --file scripts/apex/seed-data.apex --target-org <alias>
Map<String, Integer> counts = SeedData.run();
for (String objectName : counts.keySet()) {
    System.debug(LoggingLevel.INFO, 'SEED ' + objectName + ': ' + counts.get(objectName));
}
