# Workshop Slides — Design Review

**Deck:** `workshop-slides/index.html` (42 slides; `workshop-slides/speaker.html` is the notes variant and must be kept in sync)
**Reviewed:** 2026-07-14, rendered at 1920×1080 via headless Chrome, every slide screenshotted and inspected.
**Verdict:** Clean, coherent GitHub-dark aesthetic with some genuinely strong slides ("Let agents verify their own work", "The contract", "Go build."). Held back by four systemic habits and one outright rendering bug.

> Slide references below use the on-screen counter (`N/42`) plus the slide title, since the HTML comment numbering (9b, 12b, 17b…) has drifted from the rendered order.

---

## 0. Defect (fix before presenting)

### D1 — Clipped prompt text on "Plan before you build" (41/42)
The first prompt block renders as `> "Read EPIC.md and brainstorm how to split the work into par` — the string is cut mid-word at the card edge. `<pre>` doesn't wrap and the overflow is invisible in a talk; nobody scrolls a slide. **Fix:** add manual line breaks (as the code block on "Let Claude do the decomposition" 17/42 already does) or set `white-space: pre-wrap` on that block.

---

## 1. Systemic issues (fixing these lifts all 42 slides)

### S1 — Everything floats in the vertical center; titles jump between slides
Content typically occupies a narrow band in the middle ~40% of the screen. Slides 2, 3, 12, 25 and 29 feel especially sparse. Because every slide is auto-centered, the title lands at a different height on each one (compare "Sequential execution", "Easiest two ways to get a worktree", "The scenario"), so advancing slides makes the layout visibly lurch.

**Fix:** give content slides a fixed header zone — title anchored ~10–12% from the top — and let the body fill the remaining space. Add a small mono uppercase "eyebrow" label showing the current act (WORKTREES / PARALLEL / TEAMS / HOOKS / LAB) above the title for orientation in a 42-slide deck. Act-title and statement slides (title, "Questions?", "Go build.") stay centered. Highest-impact change in this review.

### S2 — Rainbow keyword highlighting carries no meaning and dilutes emphasis
Five accent colors are sprinkled decoratively: "Key takeaway" (12/42) colors four consecutive phrases blue/green/purple/orange for no reason; bullets on 17/42 and 41/42 use rotating lead-in colors. It actively misfires on "What you're building" (38/42): `format-on-save — PostToolUse` is blue while `codacy-analyze-on-save — PostToolUse` is green — the **same event type** in two colors, on the slide that teaches event types.

**Fix:** one brand accent (blue) for emphasis; green/red strictly semantic for good/bad (already used well on "Parallel OK / Must be sequential" and "check their work / drift"); purple/orange only where meaning demands. On 38/42, color by event: both PostToolUse hooks share one color, SessionStart gets another.

### S3 — Body text too dim for projection
Muted grey `#8b949e` on `#0d1117` (~5.4:1) carries most body copy. Projectors crush dark tones; this reads murky from the back of a room. Microcopy is worse: "merge → review →" (4/42) at 0.8rem, the SVG's 11px time axis (19/42), the tiny "YOU ARE HERE" marker (27/42).

**Fix:** lift body copy to `--text` (or a new `#b6c2cf`); reserve muted grey for captions. Raise the floor on microcopy to ~0.95rem/15px equivalents.

### S4 — Screenshots melt into the background and are mostly illegible
All four images are dark terminal UIs on a dark deck with a near-invisible 1px border. On 13/42, 15/42 and 16/42 they're too small to read — grey rectangles of noise. The 220px "New Session" dialog on "Worktree gotchas" adds nothing.

**Fix:** per screenshot, either make it the hero (large, cropped/zoomed to the meaningful region, lighter border, real drop shadow, caption) or cut it. One readable screenshot beats three decorative ones.

---

## 2. Highest-value slide-specific changes

### H1 — "Sequential execution" (3/42) + "Parallel execution in waves" (4/42): the visual contradicts the pitch
On 3/42, eight hours spans the full content width; on 4/42, two hours spans… the same width. Nothing visually says "4× faster."

**Fix:** merge onto **one slide with a shared time axis** (hour ticks 0→8). Sequential row runs full width; the two wave blocks stop at the ¼ mark with the reclaimed 6 hours conspicuously empty. Mute the sequential row to monotone grey/red (rainbow reads cheerful, not painful); color parallel blocks by wave; add a chevron between Wave 1 → Wave 2 to show sequence; keep "~8 hours" red vs "~2 hours" green.

### H2 — "Agent Orchestrator" (10/42)
Intro paragraph reads like speaker notes; the 5-row status legend misaligns ("Needs Attention" wraps); the GIF — the actual star — is small and unreadable.

**Fix:** one positioning line + an "infosec-approved" chip; GIF at ~60% width center; legend as a compact horizontal strip of dot+label chips beneath it (drop the per-status descriptions); Slack CTA as a footer badge.

### H3 — Git-branch SVG, "The full picture" (19/42)
Drawn too delicately: 2px dashed strokes, 13px mono labels, unlabeled merge dots, 11px axis caption.

**Fix:** render ~1.3× larger, thicken strokes (3→5 main, 2→3 dashed), labels to 16–18px, label the merge dots. Retitle — "The full picture" says nothing; "What your git history looks like" is the message.

### H4 — "The spectrum" (27/42)
Reads as four disconnected boxes of unequal height; "YOU ARE HERE" floats detached above the green card.

**Fix:** equalize card heights; run a gradient track or arrows beneath the four stages so it reads as a continuum; attach the marker to the green card (larger arrow, touching the border).

### H5 — "Why worktrees matter for agents" (8/42)
Both columns use identical blue bullet dots, and the red/green panel pairing relies on color alone.

**Fix:** red ✗ markers in the "Without" column, green ✓ in the "With" column. Stronger pop and colorblind-safe.

### H6 — "Let Claude do the decomposition" (17/42)
Densest slide in the deck: four multi-line bullets + tall code block + callout.

**Fix:** either split into two slides (principles / prompt), or restructure as a 2×2 card grid of the four principles above a full-width prompt block. Unify the four lead-in colors to one accent.

### H7 — "Worktree gotchas" (13/42)
Two warning cards stretch ~1370px (past the deck's usual 800–900px measure) with centered multi-clause sentences; tiny illegible screenshot on the right; red styling although these are cautions, not errors.

**Fix:** cut the screenshot; cap card width ~900px; left-align copy; restyle from red to orange/warning (red stays reserved for "never do this").

---

## 3. Smaller consistency notes

| # | Where | Issue → fix |
|---|-------|-------------|
| C1 | All content slides | Title scale varies arbitrarily between h2 and h3 ("The scenario" huge, "Sequential execution" small). Pick one content-title size. |
| C2 | Throughout | Card styling drift: padding 1rem/1.2rem/1.5rem, radii 6/8/12px, border alphas 0.2/0.25/0.3, two inline-code chip styles (13/42 vs elsewhere). Extract a shared `.card` class and one chip style; the inline styles are how the drift happened. |
| C3 | Act titles + closer | Gradient language differs: act titles blue→purple, "Go build." green→blue. Unify. Consider a ghost act numeral ("02") and a one-line promise on act titles — currently the emptiest slides. |
| C4 | "Subagents vs Agent Teams" (23/42) | Table set at ~0.85–1.1rem — small for projection. Bump size + row padding; optionally shade the winning cell per row. |
| C5 | "Easiest two ways…" (9/42) | Bottom caption repeats the "My preference" badge's message. Drop one. |
| C6 | "Let's put this into practice" (37/42) | Stat chips break their own pattern (3, 3, ✓). Use "3 hooks · 3 worktrees · 1 rule: keep what you like". |
| C7 | "Worktree directory structure" (11/42) | Inline `# ←` comments sit at slightly different x-positions. Align the comment column. |
| C8 | Stagger animation | Delays run to 1.7s; advancing quickly leaves bullets mid-fade. Use 0.1–0.15s steps. |
| C9 | "Tasks MUST be independent" (16/42) | Three elements compete (A/B diagram, unreadable screenshot, tip pill). Enlarge the A/B diagram, cut or enlarge the screenshot per S4. |
| C10 | "Init a Claude session per worktree & execute plan" (15/42) | Title is a full sentence; shorten (e.g. "The workflow"). Step 4's inline code chip breaks rhythm. |
| C11 | "Quick start" (40/42) | Comment `# one per hook…` floats far right of its command; keep adjacent. |
| C12 | "Pick the right layer" (34/42) | Three layer rows could express stack depth (indent/arrow down); row label colors are arbitrary — single accent with depth shading. |
| C13 | "If you remember three things" (35/42) | Second line wraps awkwardly ("independent tasks, / independent files"); adjust max-width. |
| C14 | Fonts | 'SF Pro Display' first — fine when presenting from a Mac; self-host Inter if the deck must render identically elsewhere. |

---

## 4. Priority order

1. **D1** — fix the clipped prompt text (defect).
2. **S1** — fixed header zone + act eyebrows instead of vertical centering.
3. **H1** — merge slides 3+4 onto a shared time axis so "4× faster" is visible, not stated.
4. **S2** — collapse palette to blue + semantic green/red (incl. the 38/42 PostToolUse mismatch).
5. **S3** — brighten body text; raise microcopy floor.
6. **S4 / H2 / H7** — screenshot treatment (hero or cut).
7. **H3–H6**, then the C-list.
