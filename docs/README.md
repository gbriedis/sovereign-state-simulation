# Documentation Guide

This directory is the project knowledge base. Documents are separated by how
often their information should change, so humans and AI agents can identify what
is authoritative without reconstructing context from chat history.

## Information hierarchy

1. **Vision** — enduring product intent and boundaries.
2. **Principles** — rules used to judge designs and implementations.
3. **Roadmaps** — milestone scope and definitions of completion.
4. **Architecture** — accepted technical structure and constraints.
5. **Open decisions** — questions that are explicitly unresolved.
6. **Handoffs** — concise snapshots of present work and next actions.

When documents conflict, prefer the more specific document. If two documents at
the same level conflict, do not guess: record the conflict in the current-state
handoff and resolve it before implementation.

## Update rules

- Change `PROJECT_VISION.md` only when the agreed product vision changes.
- Change `DESIGN_PRINCIPLES.md` only when a governing design rule changes.
- Update roadmap files when milestone scope or completion criteria change.
- Put accepted technical decisions in the architecture overview.
- Keep undecided matters in `OPEN_DECISIONS.md`; move them out once resolved.
- Refresh `handoff/CURRENT_STATE.md` after meaningful implementation or planning.
- Include dates in handoffs and decision records, not in timeless prose unless
  the date is itself important.

## AI catch-up order

For a general task, read:

1. `handoff/CURRENT_STATE.md`
2. The task-relevant roadmap or architecture document
3. `PROJECT_VISION.md` and `DESIGN_PRINCIPLES.md` when making design choices

Do not treat proposals, open questions, or long-term direction as implemented
features.
