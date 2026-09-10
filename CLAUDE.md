# CLAUDE.md

Guidance for Claude Code sessions working in this repo. Full product context lives in [docs/PRD.md](docs/PRD.md) — read it before scoping any feature work; this file is the condensed, enforceable subset.

## Session workflow — do this every time

- **Read [PLANNING.md](PLANNING.md) at the start of every new conversation.** It has the vision, architecture, and tech stack — don't start designing or picking tools without it.
- **Check [TASKS.md](TASKS.md) before starting work.** Find the relevant milestone and task; don't duplicate or contradict what's already tracked there.
- **Mark tasks complete in TASKS.md immediately** when finished — not batched at the end of a session.
- **Add newly discovered tasks to TASKS.md as soon as they're found** — under the right milestone if they fit, otherwise under Backlog or Open items. Don't let discovered work go untracked.

## What this project is

**Cold Open** — a home-screen widget (iOS, Android, later macOS/Windows) that shows a random quote from a *Star Wars: The Clone Wars* pre-credits cold open, and lets the user share it in one tap. The widget is the product — there is no requirement to open a companion app for the core loop (get quote → share quote).

Fan project. Non-commercial: no ads, no paywall, no in-app purchase, ever, unless the user explicitly changes this constraint in conversation. Every quote and share card must carry attribution to *Star Wars: The Clone Wars* and its episode of origin — never drop attribution to simplify a layout.

## Content scope — do not drift

The quote corpus is **cold open narration lines only** (the narrator's line right before the title card), not general episode dialogue. If a task implies pulling in arbitrary in-episode quotes, stop and confirm with the user first — that's explicitly a separate, later effort per the PRD, not a natural extension of this one.

Quote data model, per entry: `text`, `episodeTitle`, `season`, `episode`, `arc`. Treat this as the stable schema; changes to it affect every platform's widget code and the share-card renderer, so surface schema changes explicitly rather than making them incidentally while working on one platform.

## Architecture

- **Data is static and offline-first.** The full quote corpus (~130 episodes) ships bundled with the app as versioned JSON/SQLite. No live backend for v1 — don't introduce a network dependency for rendering the widget.
- **Platform-native widgets, shared data layer.** iOS/macOS use WidgetKit (Swift); Android uses Jetpack Glance / App Widgets (Kotlin); Windows uses the Widgets Board API (treat as stretch — build after the other three are stable). Keep the quote corpus and any quote-selection logic platform-agnostic where the platform allows it; widget rendering code is necessarily platform-specific.
- **Share cards are generated on-device at share time** — themed background + quote + attribution line, exported at 1080×1920 and 1080×1080. Don't pre-render or cache share images server-side; there is no server.

## Priority discipline (from the PRD)

When picking up unscoped or ambiguous work, default to P0 before P1, and don't start P2 work without the user asking for it by name:

- **P0:** randomized quote display, manual refresh, tap-to-share, native share targets (IG/X/Facebook/OS sheet), small/medium/large widget sizes.
- **P1:** scheduled auto-refresh, favorites, companion quote browser.
- **P2:** faction-themed skins, lock screen widget.

## Explicitly out of scope (v1)

Don't add these without the user asking first — they were deliberately cut:

- General in-episode dialogue quotes beyond the cold open line
- User-submitted/edited quotes
- Any monetization, ads, or IAP
- Android tablet/foldable-specific layouts
- Audio playback of the narrator's actual voice line (real licensing exposure, distinct from text quotes)

## Non-functional constraints

- Respect each OS's widget refresh/timeline budget — don't work around it with background polling or foreground services just to hit the <150ms refresh goal; that goal is aspirational within the OS's real constraints, not a license to fight the platform.
- Widget text must hit WCAG AA contrast at every size; VoiceOver/TalkBack should read quote + attribution as a single label, not two.
- v1 is English-only; don't hardcode layout assumptions that make later localization harder for free.

## IP awareness

*The Clone Wars* is Lucasfilm/Disney property. This project's non-commercial framing (no ads, no paywall, full attribution) is the whole basis for it being reasonable to build — don't introduce anything that erodes that (monetization, removing attribution, claiming original authorship of quotes). If a task pushes toward public app-store distribution specifics, flag it — that decision (sideload/TestFlight vs. public listing) hasn't been made yet per the PRD's open risks.

## Design direction

Clean, minimal, Clone Wars-themed, beautiful — in that priority order. Deep space-navy/gunmetal grounds, one desaturated accent color per widget instance, generous negative space around the quote text. At most one faction emblem, and only at the large widget size. Refresh transitions should be quick (sub-200ms) and subtle — a wipe or flicker, never a loading spinner.

## Commit standards

This repo enforces quality gates and a commit format via git hooks (husky) — see [PLANNING.md](PLANNING.md#quality-gates) for what each gate checks.

- **Every commit message must follow [Conventional Commits](https://www.conventionalcommits.org/):** `type(scope): subject` — e.g. `feat(ios): add small widget layout`, `fix(corpus): correct season number for Rookies`, `docs: update PRD milestone table`. Common types: `feat`, `fix`, `docs`, `build`, `test`, `refactor`, `chore`. The commit-msg hook (commitlint) rejects anything else.
- **Never bypass the hooks** (`--no-verify`) to force a commit through. If `npm run lint`, `npm test`, `npm run build`, or `npm run audit` fails, fix the underlying issue — a failing gate is real signal, not friction to route around. This matches the general git safety rule already in effect for this project.
- **A failing `npm run audit`** (new dependency vulnerability) should be fixed by upgrading or overriding the vulnerable transitive dependency (see the `overrides` field in `package.json` for a precedent — `smol-toml` was force-upgraded this way rather than downgrading `markdownlint-cli2`), not by lowering `--audit-level` or skipping the check.
- **If a task needs a test that doesn't exist yet, write the test first**, then make it pass — don't commit new corpus/tooling logic without corresponding coverage in `tests/`.

## Session summary

**2026-09-09**

- Wrote the initial PRD (published as a designed artifact and as [docs/PRD.md](docs/PRD.md)), scoping the widget: randomized cold-open quotes, one-tap social sharing, iOS/Android/macOS/Windows.
- Initialized this repo and pushed it to GitHub as a public repo: [AiraDeCastro/clone-wars-quotes](https://github.com/AiraDeCastro/clone-wars-quotes).
- Generated this file (CLAUDE.md), [PLANNING.md](PLANNING.md), and [TASKS.md](TASKS.md) from the PRD, then added the session workflow rules above (read PLANNING.md every session, check/update TASKS.md continuously).
- Started M1's quote-corpus task: created [corpus/quotes.json](corpus/quotes.json) with the schema and one verified seed entry, and [corpus/README.md](corpus/README.md) explaining why the remaining ~129 quotes weren't bulk-transcribed from memory (copyright + accuracy risk — see PRD §11) and how to fill them in properly. TASKS.md updated to reflect this: schema task checked off, transcription task left open with the blocker noted, and a new task added for sourcing the rest of the corpus from a legitimate transcript source.
- Set up the pre-commit quality pipeline: husky-managed `pre-commit` hook running markdown/corpus lint, the new corpus test suite ([tests/corpus.test.js](tests/corpus.test.js)), a corpus build/validation step ([scripts/validate-corpus.js](scripts/validate-corpus.js)), and `npm audit`; a `commit-msg` hook running commitlint to enforce Conventional Commits. Hit and fixed 2 high-severity vulnerabilities in the tooling's own dependencies (`smol-toml`, via a `package.json` override) before wiring the audit gate. Verified the hooks actually block a non-conventional commit message and pass a conventional one — this was committed as `build: add pre-commit quality gates and conventional commit enforcement` (commit `1dccdf6`).
- Documented all of this in [PLANNING.md](PLANNING.md) (new Quality Gates section, Node.js added to Required Tools) and this file (new Commit standards section above), plus follow-on TASKS.md items for wiring native iOS/Android lint+build+test into the same hook once those projects are scaffolded.
- The doc updates (PLANNING.md, TASKS.md, this file) made after that commit are still local, pending review before push.
