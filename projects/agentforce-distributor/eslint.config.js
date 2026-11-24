// ESLint for the Aura and Lightning web components of the build (docs/engineering/development-foundation.md §1.5).
// The Salesforce recommended configurations; a project adds a rule here and its ID to code-review-rules.md.
const { defineConfig } = require("eslint/config");
const eslintJs = require("@eslint/js");
const jestPlugin = require("eslint-plugin-jest");
const auraConfig = require("@salesforce/eslint-plugin-aura");
const lwcConfig = require("@salesforce/eslint-config-lwc/recommended");
const globals = require("globals");
const { buildDir, snapshotDir } = require("./project.config.json");

module.exports = defineConfig([
    // Only the build's own code is linted: the org snapshot (a practice project has none) and third-party
    // code keep their authors' style.
    {
        ignores: [
            ...(snapshotDir ? [`${snapshotDir}/**`] : []),
            `${buildDir}/vendor/**`,
            "node_modules/**",
            ".sf/**",
            ".sfdx/**"
        ]
    },

    {
        files: ["**/aura/**/*.js"],
        extends: [...auraConfig.configs.recommended, ...auraConfig.configs.locker]
    },

    {
        files: ["**/lwc/**/*.js"],
        extends: [lwcConfig]
    },

    // Jest tests of the components: wire adapters are mocked there, and Node globals are available.
    {
        files: ["**/lwc/**/*.test.js"],
        extends: [lwcConfig],
        rules: {
            "@lwc/lwc/no-unexpected-wire-adapter-usages": "off"
        },
        languageOptions: {
            globals: { ...globals.node }
        }
    },

    {
        files: ["**/jest-mocks/**/*.js"],
        languageOptions: {
            sourceType: "module",
            ecmaVersion: "latest",
            globals: { ...globals.node, ...globals.es2021, ...jestPlugin.environments.globals.globals }
        },
        plugins: { eslintJs },
        extends: ["eslintJs/recommended"]
    }
]);
