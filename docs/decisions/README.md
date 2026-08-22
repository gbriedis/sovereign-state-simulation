# Architecture and Project Decision Records

- **Index owner:** Project Steward
- **Status:** Active
- **Adopted:** 2026-08-22

Decision records preserve *why* a material choice was made, who had authority,
which alternatives were rejected, and which teams must react. They complement
focused canonical documents; they do not replace them.

## When an ADR is required

Create an ADR for a decision that is durable and expensive to rediscover or
reverse, including:

- architecture, authority, persistence, compatibility, or exported contracts;
- accepted world-generation semantics that constrain implementation;
- cross-department ownership or operating policy;
- material product or brand choices with downstream consumers; and
- deliberate exceptions to an accepted principle or boundary.

Do not create an ADR for routine implementation detail, a temporary experiment,
or a question with no recommendation. Keep unresolved technical questions in
[Open Decisions](../architecture/OPEN_DECISIONS.md) until a DRI advances one into
a decision proposal. When resolved, the ADR records rationale, the focused
canonical document records the resulting truth, and the open inventory is
updated. An accepted ADR means “decided,” not “implemented.”

## Lifecycle and naming

Allowed statuses are:

- `Proposed` — under consultation; not canonical direction.
- `Accepted` — accepted by the named decision owner.
- `Rejected` — considered and explicitly not selected.
- `Superseded` — replaced by a newer ADR linked in both records.

Files use `ADR-NNNN-kebab-case.md`. Before assigning a number, inspect this index
and the directory, then reserve the next unused four-digit number. Never reuse a
number or rewrite an accepted ADR to make history look cleaner. Small factual
corrections are allowed; a changed decision gets a new ADR and supersedes the
old one.

## Decision workflow

1. The workstream DRI copies [ADR_TEMPLATE.md](ADR_TEMPLATE.md), fills the
   recommendation and consequences, and marks it `Proposed`.
2. The DRI declares `Art / Technical Art impact` using the same classifications
   as a work packet, then routes consultation through
   [DEPENDENCIES.md](../operations/DEPENDENCIES.md). The lowest authority that
   owns the material consequence is the decision owner.
3. The decision owner accepts or rejects. The DRI records the outcome, date, and
   material objections rather than erasing them.
4. The DRI updates affected canonical documents and work packets, then notifies
   action-required and informed consumers.
5. Adoption evidence is linked as implementation lands. The Project Steward
   keeps the index and supersession links current.

Product Owner approval is not required for routine or domain-owned ADRs. It is
required when the decision changes the player promise, material product scope,
commercial commitment, public release, legal position, or another irreversible
external consequence.

## Index

| ADR | Status | Decision | Decision owner | Related work |
| --- | --- | --- | --- | --- |
| [ADR-0001](ADR-0001-project-control-plane.md) | Accepted | Adopt an autonomous repository-native project control plane | Product Owner | `OPS-001` |
