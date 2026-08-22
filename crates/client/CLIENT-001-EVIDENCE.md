# CLIENT-001 camera navigation evidence

This record covers the provisional diagnostic camera implemented by
`CLIENT-001`. It is review evidence, not a player-facing capture and not a claim
about generated world data, projection, geology, semantic zoom, refinement,
streaming, or render LOD.

The accepted visual invariants come from
[Map and Camera Language](../../docs/art/MAP_AND_CAMERA_LANGUAGE.md). Binding,
sensitivity, numeric bounds, and other reversible tuning remain open under
[ART-D002](../../docs/art/ART_OPEN_DECISIONS.md).

## Review build

| Field | Recorded value |
| --- | --- |
| Work ID | `CLIENT-001` |
| Branch | `feat/CLIENT-001-map-camera-navigation` |
| Canonical base | `353b1f6c92c054464ad72690fe6bbfd58374ddc4` |
| Interaction source revision | `6d0de75` |
| Mode | Diagnostic/review fixture; not player-facing |
| Platform | Windows 11 Home, kernel build 26200 |
| GPU/backend | NVIDIA GeForce RTX 5060 Laptop GPU, Vulkan |
| Default viewport | 1280 x 720 logical; 1920 x 1080 physical |
| OS scale factor | 1.5 |
| Initial camera | center `(0, 0)`, orthographic scale `1` |
| Input path | Bevy 0.19 mouse-button, cursor-moved, and wheel messages |

The runtime prints this context at startup when `sovereign_client=info` is
enabled. The pull request records the final submitted head because adding this
evidence file necessarily follows the interaction-source commit.

## Provisional control contract

- Pan is middle-button direct manipulation: the diagnostic surface follows the
  pointer, so the camera center moves opposite the pointer delta.
- A pan begins only on a fresh, focused, in-viewport press. Release, focus loss,
  pointer exit, or UI input-gate closure cancels it. Stale platform button state
  cannot rearm it.
- Positive semantic zoom intent means zoom in. Line-wheel events retain their
  line value; pixel/trackpad events are divided by Bevy's scroll-unit conversion
  factor at the input boundary.
- Zoom uses an exponential step of `1.2`, clamps orthographic scale to
  `0.125..=16.0`, and clamps accumulated intent to `-4.0..=4.0` per frame.
- Zoom is ignored when the pointer is unavailable, outside the map viewport, the
  window is unfocused, or another client UI surface closes the input gate. There
  is no hidden viewport-center fallback.
- There is no smoothing, inertia, acceleration, rotation, tilt, keyboard
  navigation, remapping, picking, or semantic zoom in this packet.

## Automated evidence

Command:

```powershell
cargo test -p sovereign-client --bin sovereign-client --locked
```

Result at interaction source revision `6d0de75`: **13 passed, 0 failed**.

| Invariant | Focused evidence |
| --- | --- |
| Direct-manipulation direction | Cardinal and diagonal pan cases verify camera-center movement in all four directions. |
| Scale-aware pan | Equal pointer deltas are converted through the current orthographic scale. |
| Input normalization | Line and pixel events normalize to equal semantic intent; positive and negative signs are explicit. |
| Event-size safety | Accumulated intent is bounded per frame, including non-finite inputs. |
| Finite/clamped zoom | Scale remains finite and positive and is clamped to `0.125..=16.0`. |
| Bound pressure and reversal | Repeated bounded input reaches and holds both limits, then reverses away from each limit. |
| Repeated stability | Sixteen high-resolution zoom-in steps followed by sixteen inverse steps return to scale `1` within `1e-5`. |
| Cursor anchor | Center, four near-edge positions, and four near-corner positions are invariant at low, middle, and high provisional scales within `1e-5` logical pixels. |
| Cancellation | Release, pointer/focus/UI unavailability, stale-button non-rearming, and fresh-press rearming are covered by extractable state tests. |
| Invalid input | Non-finite pointer, drag, zoom, scale, and transform inputs cannot create a non-finite camera result. |

Targeted formatting and lint checks also passed:

```powershell
cargo fmt --all -- --check
cargo clippy -p sovereign-client --all-targets --locked -- -D warnings
```

## Runtime evidence

The source-identical pre-rebase interaction revision `63167f9` was launched
with the following command. `git diff 63167f9 6d0de75 -- crates/client/src`
confirms that the reviewed interaction source did not change during the rebase
onto the ART-001 closure commit.

```powershell
$env:RUST_LOG='sovereign_client=info,bevy_diagnostic=info'
cargo run --locked -p sovereign-client
```

The default diagnostic fixture opened at the viewport, DPI, transform, and
backend recorded above. With vertical sync enabled, repeated five-second samples
settled around 60 FPS and approximately 16.67 ms average frame time. Individual
reported samples during the unattended steady-state run ranged from about 56.9
to 65.9 FPS. No numeric pass budget has been accepted, so these measurements are
reported without inventing one.

Before the restart, interactive wheel checks on the source-identical client tree
were observed at the viewport center and at an upper-right off-center grid
intersection. The chosen grid point remained visually beneath the pointer while
zooming, and no visible jump or stall was observed. These observations do not
substitute for the complete manual matrix below.

## Manual interaction matrix

Run `cargo run --locked -p sovereign-client` and record results against the final
submitted head.

| Check | Status | Required observation |
| --- | --- | --- |
| Pan four directions | Pending user observation | Middle-drag up, down, left, and right; the surface follows the pointer. |
| Center and corner anchors | Pending user observation | At center and near all four corners, the same grid point remains beneath the pointer across zoom. |
| Both zoom bounds | Pending user observation | Repeated input holds each bound; reversing moves away without a jump or inversion. |
| Release cancellation | Pending user observation | Releasing middle button immediately stops panning. |
| Leave/re-enter | Pending user observation | Leaving while dragging cancels; re-entry does not resume until a fresh press. |
| Focus loss | Pending user observation | Alt-Tab during a drag cancels; returning does not resume until a fresh press. |
| Narrow/wide viewport | Pending user observation | Resizing narrower and wider preserves stable pan and cursor anchoring. |
| Discrete wheel | Pending user observation | Record hardware and sign/response. |
| High-resolution trackpad | Not verified on hardware | Pixel-event normalization is covered by the focused test. |
| UI-consumed pointer | N/A | No client UI surface exists yet; the future ownership gate is implemented and tested. |
| Responsiveness under input | Pending user observation | Report any visible stall during continuous pan and rapid zoom; no threshold is assumed. |

## Fixture and limitations

The rendered grid, axes, and asymmetric markers are generated entirely inside
the client and the window title labels the view as a diagnostic camera fixture.
They are not world queries, chunk or cell identifiers, generated geology, or an
accepted visual ontology.

The final pan binding, inversion preference, scroll preference, sensitivity,
bounds, accessibility behavior, reduced-motion behavior, and remapping remain
open. Hardware trackpad behavior and the complete manual matrix must not be
claimed until their rows above are updated with observed evidence. Marketing is
not routed from this packet until Art declares the result capture-safe.

## Required acceptance

- **Art / Technical Art impact:** Action required. Art must inspect the actual
  result and record visual acceptance.
- **Dev Review:** Independent implementation and maintainability review required.
- **Systems Architecture:** Boundary review required; the implementation must
  remain client-owned and must not make world state or refinement authoritative.
