# Practice

Apex practice on the Salesforce platform: classic algorithms, Gang of Four design patterns, and Trailhead exercises. Each topic is a self-contained Salesforce DX package directory, so you can deploy one topic without the others.

## Structure

```
algorithms/                       # package directory
├── binary-search/                BinarySearch
├── breadth-first-search/         BreadthFirstSearcher
├── dijkstra/                     DijkstraGraphSearcher
├── quick-sort/                   QuickSort
├── selection-sort/               SelectionSort
└── recursion/
    ├── factorial/                FactorialCalculator, Countdown
    ├── square-tiling/            SquareTilingService (Euclid's GCD)
    └── valid-parentheses/        ParenthesesValidator

design-patterns/                  # package directory (default)
├── creational/
│   ├── abstract-factory/         GUIFactory + macOS / Windows widget families
│   ├── builder/                  Car
│   ├── factory-method/           ShapeFactory → Circle, Rectangle, Square
│   └── singleton/
│       ├── configuration-manager/  ConfigurationManager + Configuration__c
│       └── logging-service/        Logger → LogEvent__e platform event → Log__c
└── structural/
    └── proxy/                    ImageProxy → HighResolutionImage

trailhead/                        # package directory
└── asynchronous-apex/
    ├── queueable-apex/           AddPrimaryContact
    └── apex-scheduler/           DailyLeadProcessor
```

The Singleton, Factory Method and Trailhead examples include `*Test` classes.

## Run it

Requires the [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) and a Developer Edition or scratch org.

```bash
sf org login web --alias practice
sf project deploy start --source-dir design-patterns --target-org practice
sf apex run test --test-level RunLocalTests --target-org practice --wait 10
```

Swap `design-patterns` for `algorithms` or `trailhead` to deploy another topic, or deploy everything with `sf project deploy start --target-org practice`.

Formatting uses Prettier with the Apex plugin: `npm install`, then `npm run prettier`.
