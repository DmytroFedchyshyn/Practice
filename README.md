# Practice

Salesforce practice: Agentforce and Data Cloud, classic algorithms and Gang of Four design patterns in Apex, and Trailhead exercises. Each topic is a self-contained Salesforce DX package directory, so you can deploy one topic without the others.

## Structure

```
agentforce/                       # package directory (default)
                                  Agentforce agents, topics, actions and Data Cloud setup (work in progress)

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

design-patterns/                  # package directory
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

`agentforce` is the default package directory, so metadata retrieved from an org lands there. Agentforce needs an org with Agentforce and Data Cloud enabled (for example an Agentforce Developer Edition):

```bash
sf project retrieve start --metadata Bot GenAiPlannerBundle GenAiPlugin GenAiFunction --target-org practice
```

Formatting uses Prettier with the Apex plugin: `npm install`, then `npm run prettier`.
