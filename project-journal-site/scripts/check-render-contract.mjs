import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const read = (path) => readFileSync(resolve(root, path), 'utf8');
const generated = read('app/generated-journal.ts');
const json = generated.slice(
  generated.indexOf('export const journalData = ') + 'export const journalData = '.length,
  generated.lastIndexOf(' as const;'),
);
const data = JSON.parse(json);
const overview = read('app/page.tsx');
const world = read('app/world-generation/page.tsx');
const packageFile = JSON.parse(read('package.json'));
const lockFile = JSON.parse(read('package-lock.json'));

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const expectedLinkCount = data.systems.reduce(
  (count, system) => count + (system.parent ? 1 : 0) + system.relationships.length,
  0,
);
assert(data.systemLinks.length === expectedLinkCount, 'Generated system links do not cover every parent and relationship.');
assert(data.counts.systemLinks === expectedLinkCount, 'System-link count disagrees with generated links.');
assert(data.systemLinks.every((link) => link.sourceName && link.targetName), 'A generated system link has no readable endpoint name.');
assert(overview.includes('<th>Coverage</th>') && overview.includes('system.coverage'), 'Overview does not render system coverage.');
assert(overview.includes('journalData.systems.map') && overview.includes('journalData.systemLinks.filter'), 'Overview does not render every system connection group.');

const lifecycleTotal = Object.values(data.counts.conceptLifecycle).reduce((sum, count) => sum + count, 0);
assert(lifecycleTotal === data.acceptedConcepts.length + data.explorationTopics.length, 'Concept lifecycle counts are incomplete.');
assert(typeof data.runtimeEvidence.rustPresent === 'boolean', 'Runtime presence is missing from generated data.');
assert(Array.isArray(data.runtimeEvidence.paths), 'Runtime evidence paths are missing from generated data.');
assert(
  data.runtimeEvidence.rustPresent
    ? data.runtimeEvidence.paths.every((path) => data.currentStatements.worldGeneration.runtime.includes(path))
    : data.currentStatements.worldGeneration.runtime.startsWith('No Rust source file'),
  'Generated runtime statement disagrees with runtime evidence.',
);
for (const [state, count] of Object.entries(data.counts.conceptLifecycle)) {
  assert(Number.isInteger(count) && count > 0, `Concept lifecycle count for ${state} is invalid.`);
}
assert(world.includes('journalData.currentStatements.worldGeneration'), 'World page does not render generated current-state statements.');
assert(!world.includes('No Rust source file or Cargo workspace exists'), 'World page contains hardcoded runtime status.');
assert(!world.includes('recognized topics without accepted models'), 'World page contains a hardcoded lifecycle description.');

assert(lockFile.name === packageFile.name, 'Lockfile package name does not match package.json.');
assert(lockFile.packages?.['']?.name === packageFile.name, 'Lockfile root package name does not match package.json.');

console.log(`Website render contract passed: ${data.systems.length} systems, ${expectedLinkCount} links, ${lifecycleTotal} concepts.`);
