import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const siteRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const repositoryRoot = resolve(siteRoot, '..');
const read = (relativePath) => readFileSync(resolve(repositoryRoot, relativePath), 'utf8');

const registry = JSON.parse(read('docs/project-journal/SYSTEMS.json'));
const worldIndex = read('docs/world-generation/README.md');
const worldStatus = read('docs/project-journal/WORLD_GENERATION_STATUS.md');
const openDecisions = read('docs/architecture/OPEN_DECISIONS.md');

function findRustRuntimeEvidence(directory) {
  const excluded = new Set(['.git', '.next', '.vinext', '.wrangler', 'dist', 'node_modules', 'target']);
  const evidence = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (excluded.has(entry.name)) continue;
    const absolutePath = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      evidence.push(...findRustRuntimeEvidence(absolutePath));
    } else if (entry.name === 'Cargo.toml' || entry.name.endsWith('.rs')) {
      evidence.push(absolutePath.slice(repositoryRoot.length + 1).replaceAll('\\', '/'));
    }
  }
  return evidence.sort();
}

function tableRows(markdown, heading, nextHeading) {
  const start = markdown.indexOf(`## ${heading}`);
  const end = nextHeading ? markdown.indexOf(`## ${nextHeading}`, start + 1) : markdown.length;
  if (start < 0 || end < 0) throw new Error(`Could not find table section: ${heading}`);
  return markdown
    .slice(start, end)
    .split(/\r?\n/)
    .filter((line) => /^\| `WG-\d{3}` \|/.test(line))
    .map((line) => line.split('|').slice(1, -1).map((cell) => cell.trim()));
}

const plain = (value) => value
  .replace(/`/g, '')
  .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
  .replace(/\*\*/g, '');

const acceptedConcepts = tableRows(worldIndex, 'Accepted concepts', 'Recognized exploration topics')
  .map(([id, truth, owner, implementation]) => ({ id: plain(id), truth: plain(truth), owner: plain(owner), implementation: plain(implementation) }));

const explorationTopics = tableRows(worldIndex, 'Recognized exploration topics', 'Dependency order')
  .map(([id, state, question, owner]) => ({ id: plain(id), state: plain(state), question: plain(question), owner: plain(owner) }));

const decisions = [...openDecisions.matchAll(/^#{2,3} (ARCH-OPEN-\d{3}) — (.+)$/gm)]
  .map((match) => ({ id: match[1], name: match[2].trim() }));

const conceptLifecycleCounts = [...acceptedConcepts, ...explorationTopics]
  .reduce((counts, concept) => {
    const state = concept.state ?? 'accepted';
    counts[state] = (counts[state] ?? 0) + 1;
    return counts;
  }, {});

const rustRuntimeEvidence = findRustRuntimeEvidence(repositoryRoot);
const rustRuntimePresent = rustRuntimeEvidence.length > 0;
const systemNames = new Map(registry.systems.map((system) => [system.id, system.name]));
const worldSystem = registry.systems.find((system) => system.id === 'world-generation');
const prototypeSystem = registry.systems.find((system) => system.id === 'map-and-spatial-model-prototype');
if (!worldSystem || !prototypeSystem) throw new Error('World-generation or prototype system is missing from the registry.');
const systemLinks = registry.systems.flatMap((system) => [
  ...(system.parent ? [{ source: system.id, sourceName: system.name, type: 'part-of', target: system.parent, targetName: systemNames.get(system.parent) }] : []),
  ...system.relationships.map((relationship) => ({
    source: system.id,
    sourceName: system.name,
    type: relationship.type,
    target: relationship.target,
    targetName: systemNames.get(relationship.target),
  })),
]);

if (systemLinks.some((link) => !link.targetName)) {
  throw new Error('A system parent or relationship points to an unknown system.');
}

const historicalPosts = registry.historicalPosts.map((relativePath) => {
  const source = read(relativePath);
  const title = source.match(/^# (.+)$/m)?.[1] ?? relativePath;
  const snapshotDate = source.match(/^snapshot_date:\s*(.+)$/m)?.[1] ?? 'Unknown';
  const paragraphs = source
    .replace(/^---[\s\S]*?---\s*/m, '')
    .replace(/^# .+$/m, '')
    .replace(/^>.*(?:\r?\n>.*)*/m, '')
    .trim()
    .split(/\r?\n\r?\n/)
    .map((paragraph) => plain(paragraph.replace(/\r?\n/g, ' ').trim()))
    .filter(Boolean);
  return {
    title,
    snapshotDate,
    slug: relativePath
      .split('/')
      .at(-1)
      .replace(/\.md$/i, '')
      .toLowerCase()
      .replace(/_/g, '-'),
    paragraphs,
  };
});

const fingerprint = worldStatus.match(/^dependency_fingerprint:\s*([0-9a-f]{64})$/m)?.[1];
if (!fingerprint) throw new Error('Current world-generation status has no dependency fingerprint.');

const data = {
  title: registry.journalTitle,
  reviewedOn: registry.currentView.reviewedOn,
  focus: registry.currentView.focus.label,
  milestone: registry.currentView.milestone,
  fingerprint,
  counts: {
    systems: registry.systems.length,
    acceptedConcepts: acceptedConcepts.length,
    explorationTopics: explorationTopics.length,
    openDecisions: decisions.length,
    conceptLifecycle: conceptLifecycleCounts,
    systemLinks: systemLinks.length,
  },
  currentStatements: {
    overview: `${acceptedConcepts.length} concepts are accepted; ${explorationTopics.length} topics remain in active exploration; ${decisions.length} architecture decisions remain open.`,
    worldGeneration: {
      lead: rustRuntimePresent
        ? 'A conceptual foundation and Rust runtime evidence exist; this Journal does not yet claim a working world generator.'
        : 'A conceptual foundation exists. A working world generator does not.',
      plainLanguage: `The repository contains ${acceptedConcepts.length} accepted world-generation concepts and ${explorationTopics.length} active exploration topics. Accepted concepts describe causal boundaries and relationships; they do not choose algorithms, storage layouts, or numerical methods.`,
      runtime: rustRuntimePresent
        ? `Rust runtime evidence is present: ${rustRuntimeEvidence.join(', ')}.`
        : 'No Rust source file or Cargo workspace exists. The map and spatial model prototype and runtime architecture remain not started in this workspace.',
      knowledge: `${acceptedConcepts.length} causal concepts are accepted; ${explorationTopics.length} later natural-system topics remain in exploration.`,
      coverage: `World-generation coverage is ${worldSystem.coverage.replaceAll('-', ' ')}. The natural world remains intentionally incomplete until authority records otherwise.`,
      implementation: rustRuntimePresent
        ? 'Rust runtime evidence exists, but this Journal does not claim that the world generator is complete.'
        : 'Mechanics are unresolved or not started. No Rust runtime code is present.',
      attention: worldSystem.attention === 'now' && prototypeSystem.attention === 'now'
        ? 'World generation and the map prototype are current. Exploration topics have no assigned implementation order.'
        : `World generation attention is ${worldSystem.attention.replaceAll('-', ' ')}; map prototype attention is ${prototypeSystem.attention.replaceAll('-', ' ')}.`,
    },
  },
  runtimeEvidence: {
    rustPresent: rustRuntimePresent,
    paths: rustRuntimeEvidence,
  },
  systems: registry.systems,
  systemLinks,
  acceptedConcepts,
  explorationTopics,
  decisions,
  historicalPosts,
};

const serialized = `// Generated by scripts/sync-journal.mjs. Do not edit by hand.\nexport const journalData = ${JSON.stringify(data, null, 2)} as const;\n`;
const outputPath = resolve(siteRoot, 'app/generated-journal.ts');

if (process.argv.includes('--check')) {
  const current = readFileSync(outputPath, 'utf8');
  if (current !== serialized) {
    const expected = createHash('sha256').update(serialized).digest('hex');
    const actual = createHash('sha256').update(current).digest('hex');
    throw new Error(`Website Journal data is stale. Expected ${expected}; found ${actual}. Run npm run sync.`);
  }
  console.log(`Website Journal data is current: ${data.counts.systems} systems, ${data.counts.acceptedConcepts + data.counts.explorationTopics} concepts, ${data.counts.openDecisions} decisions.`);
} else {
  writeFileSync(outputPath, serialized, 'utf8');
  console.log(`Synced Website Journal data: ${data.counts.systems} systems, ${data.counts.acceptedConcepts + data.counts.explorationTopics} concepts, ${data.counts.openDecisions} decisions.`);
}
