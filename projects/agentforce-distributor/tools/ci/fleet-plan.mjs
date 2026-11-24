// Resolves an org group from config/orgs.json into the list of orgs a fleet deploy runs on
// (docs/engineering/ci-cd.md, *Fleet deploy*).
//
//   node tools/ci/fleet-plan.mjs <group> <mode> <test-level>
//
// Prints one JSON array, [{alias, environment, production}], for the pipeline's matrix. Stops with the
// list of known groups when the group is unknown or empty, and refuses NoTestRun when the group holds
// a production org: Salesforce refuses it there anyway, and failing here stops the run before any org
// is touched.
import { existsSync, readFileSync } from "node:fs";

const [group, mode = "validate", testLevel = "RunSpecifiedTests"] = process.argv.slice(2);
const file = "config/orgs.json";
const fail = (message) => {
    console.error(message);
    process.exit(1);
};

if (!group) fail("usage: node tools/ci/fleet-plan.mjs <group> <mode> <test-level>");
if (!existsSync(file)) fail(`${file} does not exist: copy config/orgs.example.json and list the project's orgs.`);
if (!["validate", "deploy"].includes(mode)) fail(`Unknown mode "${mode}": validate or deploy.`);

const { groups = {}, orgs = {} } = JSON.parse(readFileSync(file, "utf8"));
const known = new Set(Object.keys(groups));
for (const org of Object.values(orgs)) for (const name of org.groups ?? []) known.add(name);
if (!known.has(group)) fail(`Unknown group "${group}". Known groups: ${[...known].sort().join(", ")}`);

const aliases = new Set(groups[group] ?? []);
for (const [alias, org] of Object.entries(orgs)) if ((org.groups ?? []).includes(group)) aliases.add(alias);

const plan = [...aliases].sort().map((alias) => {
    const org = orgs[alias];
    if (!org) fail(`Group "${group}" names "${alias}", which is not under "orgs" in ${file}.`);
    return { alias, environment: org.environment ?? alias, production: org.production !== false };
});
if (plan.length === 0) fail(`Group "${group}" has no orgs.`);
if (testLevel === "NoTestRun" && plan.some((org) => org.production)) {
    fail(`NoTestRun is for sandboxes only; group "${group}" holds a production org: ${plan.filter((o) => o.production).map((o) => o.alias).join(", ")}`);
}

console.log(JSON.stringify(plan));
