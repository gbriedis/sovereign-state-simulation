# State of Consequence

**A living nation simulation.**

> Govern what you cannot command.

*State of Consequence* is a reality-grounded strategy simulation in which the
player governs a living, autonomous nation rather than directly controlling
every person, company, or building.

The project is currently in its natural-world foundation phase: building the
natural world that later political, economic, and social systems must respect.

## Start here

| Need | Document |
| --- | --- |
| See the whole project in a human-readable view | [Project Journal and System Map](docs/project-journal/README.md) |
| Open the browser Project Journal | [`project-journal-site/`](project-journal-site/) |
| Understand the enduring game idea | [Project vision](docs/foundations/PROJECT_VISION.md) |
| Use the accepted name, positioning, and voice | [Brand foundation](docs/brand/BRAND_FOUNDATION.md) |
| Understand the rules guiding design | [Design principles](docs/foundations/DESIGN_PRINCIPLES.md) |
| Understand the current development phase | [Natural-world foundation roadmap](docs/planning/NATURAL_WORLD_FOUNDATION_ROADMAP.md) |
| Understand the technical structure | [Architecture overview](docs/architecture/ARCHITECTURE_OVERVIEW.md) |
| Enter the world-generation knowledge system | [World-generation source of truth](docs/world-generation/README.md) |
| Build the first proof of concept | [Map and spatial model prototype](docs/architecture/MAP_AND_SPATIAL_MODEL_PROTOTYPE.md) |
| See unresolved technical choices | [Open decisions](docs/architecture/OPEN_DECISIONS.md) |
| Catch up before continuing work | [Current state](docs/operations/CURRENT_STATE.md) |

The [documentation standard](docs/README.md) explains ownership, precedence,
wording, and update rules. The [document index](docs/INDEX.md) lists every active
source of truth.

## Current status

- **Phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Architecture boundaries:** Cross-cutting boundaries are accepted
- **Implementation choices:** Unresolved where listed in Open Decisions
- **Implementation:** Not started
- **Immediate target:** `PROTO-001` — map and spatial model prototype
- **Runtime evidence:** No Rust source or Cargo workspace is present
- **Project overview:** Generated and validated by the [Project Journal](docs/project-journal/README.md)
- **Browser view:** The top-level [`project-journal-site/`](project-journal-site/) presents the same derivative Journal data and owns no technical truth
- **Status reviewed:** 2026-08-29

## Long-term direction

The eventual game is a persistent sovereign-state MMO. Each player nation should
remain a deep simulation in its own right. Multiplayer persistence should connect
nations without weakening their internal autonomy or physical grounding.

Web3 may later become an optional economic or ownership layer. It is not a
foundation of the simulation and must not dictate the core game design.
