---
id: DOCS-CLEAR-LANGUAGE
type: clear-language-standard
status: accepted
scope: Names and shared language used for project navigation, documents, systems, branches, and agent work
authority: Owns the rules that keep routine project language direct, stable, and understandable without hidden context
last_reviewed: 2026-08-29
---

# Clear Language Standard

Project language must reduce the effort required to find, remember, and discuss
work. A familiar reader should not need chat history or a private glossary to
understand a routine name.

## Naming rules

- A name must reveal the subject or outcome it identifies.
- One term must have one meaning within the same context.
- Use the same subject name in filenames, headings, links, system labels, and
  assignments unless a shorter public label is explicitly defined.
- Prefer ordinary words over invented abbreviations. Introduce an abbreviation
  only when repeated use saves more effort than learning and remembering it.
- A routine navigation label must not require glossary lookup. Specialized
  scientific terms may remain when they are the precise subject being named.
- Name work after its intended result, not the tool, agent, worker, or
  conversation that performs it.
- Remove obsolete terminology from the active path in the same change that
  adopts its replacement. Preserve history in Git or a clearly dated historical
  record, not in active navigation.
- Do not use vague containers such as `misc`, `stuff`, `updates`, `changes`,
  `temp`, `old`, or `new` as a complete name or branch-name segment.

These rules govern names. They do not authorize rewriting an accepted domain
term merely because it is technical. The [Glossary](../../foundations/GLOSSARY.md)
remains the authority for precise shared meanings.

## Branch names

Normal work branches use:

```text
<kind>/<clear-outcome>
```

Allowed kinds are:

- `feature` — a new product capability;
- `fix` — a defect correction;
- `docs` — documentation or knowledge work;
- `maintenance` — repository or tooling upkeep;
- `experiment` — a temporary investigation.

The outcome is a lowercase hyphen-separated phrase that states what the branch
will accomplish. `main` is exempt. Tool and worker identities such as `codex`,
`agent`, or `worker` are not outcomes and must not appear as branch-name
segments.

Examples:

```text
docs/project-journal-and-system-map
feature/world-map-prototype
fix/spatial-cell-selection
maintenance/clarify-document-filenames
experiment/tectonic-partitioning
```

Names such as `codex/docs-work`, `docs/updates`, and
`maintenance/misc-changes` are invalid because they identify a performer or a
vague activity rather than an outcome.

## Review test

Before accepting a shared name, ask:

1. Can a new contributor predict what it contains or accomplishes?
2. Does the same term mean the same thing everywhere it appears?
3. Is every shortened form worth its learning and memory cost?
4. Does the name remain truthful after the work is complete?
5. Has the replaced name left active navigation?

If any answer is no, improve the name or record the precise exception before
making it durable.
