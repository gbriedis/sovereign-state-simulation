# State of Consequence

**A living nation simulation.**

> Govern what you cannot command.

*State of Consequence* is a reality-grounded strategy simulation in which the
player governs a living, autonomous nation rather than directly controlling
every person, company, or building.

The project is currently in its world-foundation phase: building the natural
world that later political, economic, and social systems must respect.

## Start here

| Need | Document |
| --- | --- |
| Understand the enduring game idea | [Project vision](docs/PROJECT_VISION.md) |
| Use the accepted name, positioning, and voice | [Brand foundation](docs/brand/BRAND_FOUNDATION.md) |
| Understand the rules guiding design | [Design principles](docs/DESIGN_PRINCIPLES.md) |
| Understand the current development phase | [World-foundation roadmap](docs/ROADMAP_WORLD_FOUNDATION.md) |
| Understand the technical structure | [Architecture overview](docs/architecture/ARCHITECTURE_OVERVIEW.md) |
| Build the first proof of concept | [Prototype v0.1](docs/architecture/PROTOTYPE_V0.1.md) |
| See unresolved technical choices | [Open decisions](docs/architecture/OPEN_DECISIONS.md) |
| Catch up before continuing work | [Current state](docs/handoff/CURRENT_STATE.md) |

The [documentation guide](docs/README.md) explains ownership and update rules.

## Current status

- **Phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Architecture:** Pure-Rust world core with a separate Bevy client
- **Implementation:** Rust workspace and initial map window are bootstrapped
- **Immediate target:** Prototype spatial mapping and map-camera navigation
- **Last documentation reorganization:** 2026-08-21

## Development

The repository pins its Rust toolchain and keeps renderer-independent world code
separate from the Bevy client.

```powershell
cargo run -p state-of-consequence-client
cargo test --workspace --locked
cargo clippy --workspace --all-targets --locked -- -D warnings
```

The first build downloads and compiles Bevy and its rendering dependencies.

## Long-term direction

The eventual game is a persistent sovereign-state MMO. Each player nation should
remain a deep simulation in its own right. Multiplayer persistence should connect
nations without weakening their internal autonomy or physical grounding.

Web3 may later become an optional economic or ownership layer. It is not a
foundation of the simulation and must not dictate the core game design.
