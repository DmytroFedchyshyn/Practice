// Loads or refreshes the demo data. Safe to run more than once.
// sf apex run --file agentforce/scripts/seed.apex --target-org <alias>
Map<String, Integer> counts = SeedData.run();
for (String objectName : counts.keySet()) {
    System.debug(LoggingLevel.INFO, 'SEED ' + objectName + ': ' + counts.get(objectName));
}
