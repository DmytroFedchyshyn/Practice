// Jest for the Lightning web components of the build (docs/engineering/architecture.md §4.5). Run with `npm test`.
const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
const { buildDir } = require("./project.config.json");

module.exports = {
    ...jestConfig,
    // Only the build's own components: the org snapshot is not tested here.
    roots: [`<rootDir>/${buildDir}`],
    modulePathIgnorePatterns: ["<rootDir>/.localdevserver"]
};
