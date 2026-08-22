# Outcome

<!-- State the delivered result in 1-3 sentences. Link the canonical artifact, not the chat that produced it. -->
<!-- This PR is integration evidence. docs/operations/WORKSTREAMS.md remains the canonical cross-agent status ledger. -->

## Handoff record

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| Work ID                | <!-- e.g. CORE-042 -->                                                               |
| Owner / primary writer | <!-- agent or person accountable through merge -->                                   |
| Base SHA               | <!-- full commit SHA work started from -->                                           |
| Head SHA               | <!-- full commit SHA submitted for review -->                                        |
| Branch / worktree      | <!-- branch plus logical task/worktree label; never publish a machine-local path --> |
| Declared write set     | <!-- paths or path globs intentionally changed -->                                   |

### Scope and dependencies

<!-- What changed, what deliberately did not, and why? Note any write-set deviation. -->

- Depends on:
- Unblocks:
- Interfaces / invariants / contracts changed:
- Player-visible behavior or public claims changed:
- Canonical records updated:

### Decisions

<!-- Link accepted/proposed decision records. Write `None` when this PR only implements settled direction. -->

- Made or implemented:
- Still open:

## Art / Technical Art impact

<!-- ART-CONTRACT: IMPACT-DECLARATION -->
<!-- Required. Begin the declaration with exactly one of: `Action required`, `Consulted`, `Informed`, or `N/A — <nonempty rationale>`. Do not use bare `N/A`. -->

**Declaration:** <!-- e.g. Consulted — Technical Art reviewed terrain-material and capture-pipeline impact; no blocking finding. -->

<!-- Name affected visual contracts, asset schemas, render/capture behavior, tooling, performance budgets, or art-production workflows. Link evidence or the routed follow-up when applicable. -->

## Change propagation

<!-- Include only affected departments/lanes. Status must be Consulted, Informed, or Action required. Use `None` if genuinely isolated. -->

| Department / lane        | Status                                          | What changed for them | Acknowledgement or follow-up |
| ------------------------ | ----------------------------------------------- | --------------------- | ---------------------------- |
| <!-- e.g. World Core --> | <!-- Consulted / Informed / Action required --> |                       |                              |

## Validation

<!-- Give reproducible evidence: command/check, result, and anything not run. -->

| Check                            | Result                              |
| -------------------------------- | ----------------------------------- |
| <!-- command or manual check --> | <!-- pass/fail/not run + reason --> |

## Risks and recovery

<!-- Compatibility, migration, performance, incomplete proof, or rollback notes. Write `None identified` when appropriate. -->

- Risks / limitations:
- Recovery or rollback:

## Reviewer gates

<!-- ART-CONTRACT: REVIEW-GATE -->
<!-- Name the reviewer for each required gate. Use `N/A — reason` rather than silently omitting a gate. -->

| Gate                                       | Reviewer | Status / evidence                                                                                   |
| ------------------------------------------ | -------- | --------------------------------------------------------------------------------------------------- |
| Owning domain                              |          | Pending                                                                                             |
| Cross-boundary architecture                |          | <!-- Pending or N/A — no contract/boundary change -->                                               |
| Implementation / long-term maintainability |          | <!-- Pending or N/A — no implementation change -->                                                  |
| Art / Technical Art                        |          | <!-- Pending, evidence link, or N/A — specific rationale consistent with the impact declaration --> |
| Public truth / marketing claims            |          | <!-- Pending or N/A — no public claim change -->                                                    |
| Integration readiness                      |          | Pending                                                                                             |

## Autonomous closeout

- [ ] The diff stays within the declared write set, or deviations are explained above.
- [ ] Base and head SHAs are accurate; upstream changes and merge conflicts have been resolved by the owner/integrator.
- [ ] The working tree is clean, with no uncommitted task output or unrelated user changes included.
- [ ] Required validation passes; skipped checks and residual risks are explicit.
- [ ] Every action-required department has acknowledged or has a named follow-up owner.
- [ ] Art / Technical Art impact uses an allowed classification; any `N/A` includes a specific rationale, and the matching reviewer/routing gate is resolved.
- [ ] Required reviewer gates are complete and conversations are resolved.
- [ ] Canonical status, decision, and handoff records reflect the delivered state.
- [ ] After merge, the owner/integrator will prove exact-head integration (including squash proof where applicable) and retire the clean task branch/worktree safely.

**Next owner and action:** <!-- `Integrator: merge when checks pass`, or name the exact unresolved action. -->
