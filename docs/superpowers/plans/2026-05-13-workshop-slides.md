# Workshop Slides Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone HTML slide deck for a 45-minute presentation on parallel workflows, worktrees, and agent teams.

**Architecture:** Single self-contained HTML file using vanilla HTML/CSS/JS (no build step). Keyboard navigation (arrow keys), slide transitions, and embedded diagrams/code blocks. Magazine-quality design with dark theme to match the terminal-heavy content.

**Tech Stack:** HTML, CSS, vanilla JS. No dependencies. All diagrams built with CSS/SVG (no CDN dependencies — the deck works fully offline).

**Spec:** `docs/superpowers/specs/2026-05-13-ai-workshop-design.md` — Part 1

---

## File Structure

```
workshop-slides/
  index.html          # The complete slide deck (self-contained)
```

The slide deck lives in its own directory at `/Users/stanton.borthwick/SProjects/workshop-slides/`. One file. Everything inline — CSS, JS, content. This makes it trivially shareable and presentable from any machine.

---

## Chunk 1: Slide Deck

### Task 1: Scaffold the HTML slide framework

**Files:**
- Create: `workshop-slides/index.html`

- [ ] **Step 0: Create the project directory and initialise git**

```bash
mkdir -p /Users/stanton.borthwick/SProjects/workshop-slides
cd /Users/stanton.borthwick/SProjects/workshop-slides
git init
```

- [ ] **Step 1: Create the base HTML with slide framework**

Create `workshop-slides/index.html` with:
- HTML5 boilerplate
- CSS for full-viewport slides (100vw x 100vh per slide)
- Slide navigation via left/right arrow keys
- Slide counter (e.g. "3 / 24")
- Dark theme base (dark background, light text — matches terminal aesthetic)
- Smooth transitions between slides
- `<section class="slide">` pattern for each slide
- Responsive font sizing using `clamp()`
- Code block styling with monospace font and syntax-like colouring
- Support for speaker notes (hidden by default, toggle with 'N' key)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Parallel Workflows, Worktrees & Agent Teams</title>
  <style>
    /* Dark theme, full-viewport slides, navigation, code blocks, tables */
  </style>
</head>
<body>
  <div class="deck">
    <!-- slides go here -->
  </div>
  <div class="slide-counter"></div>
  <script>
    /* Arrow key navigation, slide counter, speaker notes toggle */
  </script>
</body>
</html>
```

- [ ] **Step 2: Verify the scaffold works**

Open `workshop-slides/index.html` in a browser. Confirm:
- Dark background renders
- Arrow keys navigate between placeholder slides
- Slide counter updates
- 'N' toggles speaker notes area

- [ ] **Step 3: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: scaffold HTML slide deck with navigation and dark theme"
```

---

### Task 2: Act 1 slides — "The Problem" (5 min, ~4-5 slides)

**Files:**
- Modify: `slides/index.html`

- [ ] **Step 1: Add Act 1 slides**

Add the following slides:

**Slide 1 — Title slide:**
- "Parallel Workflows, Worktrees & Agent Teams"
- Subtitle: "From one agent to many"
- Speaker name placeholder
- Speaker notes: "Welcome, introduce yourself, set the scene"

**Slide 2 — The scenario:**
- "You have 8 features to build."
- "You open Claude Code."
- "You do them one at a time."
- "It takes all day."
- Animated reveal of each line (CSS animation, staggered)
- Speaker notes: "Relatable scenario — who has been here?"

**Slide 3 — Sequential timeline diagram:**
- A horizontal timeline showing 8 tasks executed one after another
- Each task is a coloured block on a single row
- Total time label: "~8 hours"
- Built with CSS grid/flexbox (no image dependency)
- Speaker notes: "This is how most people work with Claude Code today"

**Slide 4 — Parallel timeline diagram:**
- Same 8 tasks but distributed across 4 rows (4 parallel agents)
- Total time label: "~2 hours"
- Visual contrast with the sequential diagram
- Speaker notes: "Same work, fraction of the time. That's what we're learning today."

**Slide 5 — The hook:**
- Large text: "What if you could run 5 agents at once, each in its own isolated branch, and merge them all?"
- Speaker notes: "This is the agenda for the next 40 minutes. Let's start with the foundation."

- [ ] **Step 2: Verify Act 1 renders correctly**

Open in browser, navigate through Act 1 slides. Confirm:
- Timeline diagrams render with correct layout
- Staggered animation works on Slide 2
- All text is readable

- [ ] **Step 3: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: add Act 1 slides — The Problem with timeline diagrams"
```

---

### Task 3: Act 2 slides — "Worktrees: The Foundation" (10 min, ~6-7 slides)

**Files:**
- Modify: `slides/index.html`

- [ ] **Step 1: Add Act 2 slides**

**Slide 6 — Act title:**
- "Worktrees: The Foundation"
- Speaker notes: "Transition — now let's understand the key primitive"

**Slide 7 — What is a git worktree?**
- Diagram: one repo, multiple working directories branching off
- Key point: "One repo. Multiple checkouts. Each with its own branch."
- Built with CSS boxes and connecting lines
- Speaker notes: "Git worktrees have been around since Git 2.5 (2015). Most people don't know they exist."

**Slide 8 — Why worktrees matter for agents:**
- Two-column layout:
  - Left: "Without worktrees" — agents fight over the same files, branch switching chaos
  - Right: "With worktrees" — each agent has its own copy, zero conflicts
- Speaker notes: "The key insight: isolation is what makes parallelism safe"

**Slide 9 — The command:**
- Large code block: `claude --worktree`
- Bullet: "Creates an isolated worktree with its own branch"
- Bullet: "Agent works in its own directory"
- Bullet: "It's just git — nothing magical"
- Speaker notes: "One flag. That's it. Demo time."

**Slide 10 — Demo: creating a worktree session (LIVE DEMO)**
- Slide text: "LIVE DEMO"
- Subtitle: "Creating a worktree session in Agent Orchestrator"
- Checklist of what to show:
  - Create a session with --worktree
  - Show the new branch in git
  - Show the .claude/worktrees/ directory
- Speaker notes: "Switch to Agent Orchestrator. Create a session. Show the branch. Show the directory."

**Slide 11 — Worktree directory structure:**
- Code block showing the `.claude/worktrees/` structure
- Annotated with arrows explaining each part
- Speaker notes: "If the demo didn't work or was too fast, this is the reference"

**Slide 12 — Key takeaway:**
- "Worktree = isolated branch + working directory"
- "Each agent gets its own sandbox"
- "Merge when done — just like a feature branch"
- Speaker notes: "Make sure this is crystal clear before moving on"

- [ ] **Step 2: Verify Act 2 renders correctly**

Open in browser, check diagram layouts and code block styling.

- [ ] **Step 3: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: add Act 2 slides — Worktrees foundation with diagrams"
```

---

### Task 4: Act 3 slides — "Parallel Workflows" (15 min, ~8-9 slides)

**Files:**
- Modify: `slides/index.html`

- [ ] **Step 1: Add Act 3 slides**

**Slide 13 — Act title:**
- "Parallel Workflows"
- Speaker notes: "Now we combine worktrees with multiple agents"

**Slide 14 — The pattern:**
- 5-step numbered flow (large, visual):
  1. Decompose work into independent tasks
  2. Create a worktree per task
  3. Assign each task to an agent
  4. Monitor progress
  5. Review and merge
- Speaker notes: "This is the workflow you'll practice in the hands-on session"

**Slide 15 — "Independent" is the key word:**
- Large text: "The tasks MUST be independent"
- Subtext: "If Feature B depends on Feature A's output, they can't run in parallel"
- Diagram: Task A and Task B with no arrows between them = parallel OK. Task A → Task B with dependency arrow = must be sequential.
- Speaker notes: "This is the most common mistake. Spend time on decomposition."

**Slide 16 — Demo: spinning up parallel sessions (LIVE DEMO)**
- "LIVE DEMO"
- Subtitle: "3-4 sessions running simultaneously in Agent Orchestrator"
- Checklist:
  - Spin up 3-4 sessions with different tasks
  - Show status indicators (Working, Idle, Finished)
  - Show all worktree branches in git
- Speaker notes: "Switch to Agent Orchestrator. This is the money shot — multiple agents working at once."

**Slide 17 — Status monitoring:**
- Screenshot placeholder / description of Agent Orchestrator's status view
- Working (green pulse), Idle (yellow), Needs Attention (orange), Finished (blue), Error (red)
- Speaker notes: "You need visibility into what each agent is doing. AO gives you this."

**Slide 18 — Demo: merging a worktree (LIVE DEMO)**
- "LIVE DEMO"
- Subtitle: "Merging a completed worktree back to main"
- Code block: `git merge <worktree-branch>`
- Speaker notes: "Show a clean merge. Emphasise: because the work was independent, there are no conflicts."

**Slide 19 — The full picture:**
- Diagram showing the complete lifecycle:
  - Main branch at top
  - 4 worktree branches forking off
  - Each labelled with a task
  - Merge arrows back to main
  - Timeline showing parallel execution
- Built with CSS/SVG
- Speaker notes: "This is what your git history looks like when you work this way"

**Slide 20 — Common pitfalls:**
- "Don't edit shared files across worktrees" (merge conflicts)
- "Start hard tasks first" (more wall-clock time)
- "Review before merging" (agents make mistakes too)
- Speaker notes: "Quick hits before we move to agent teams"

- [ ] **Step 2: Verify Act 3 renders correctly**

Check diagrams, demo placeholder slides, and flow diagram.

- [ ] **Step 3: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: add Act 3 slides — Parallel workflows with live demo points"
```

---

### Task 5: Act 4 slides — "Agent Teams & When to Use What" (10 min, ~8-9 slides)

**Files:**
- Modify: `slides/index.html`

- [ ] **Step 1: Add Act 4 slides**

**Slide 21 — Act title:**
- "Agent Teams & When to Use What"
- Speaker notes: "Final concept section before the workshop"

**Slide 22 — What are agent teams?**
- "Claude Code coordinates a team lead + teammates"
- Diagram: Team Lead in center, 3 Teammates around it, Shared Task List below, Mailbox arrows between them
- Key points: shared task list, inter-agent messaging, each teammate has own context window
- Speaker notes: "This is a step up from manual parallel sessions. Claude Code manages the coordination."

**Slide 23 — Subagents vs Agent Teams:**
- Table (styled to match dark theme):

| | Subagents | Agent Teams |
|---|---|---|
| Context | Own window; results return to caller | Own window; fully independent |
| Communication | Report back to main agent only | Teammates message each other directly |
| Coordination | Main agent manages all work | Shared task list with self-coordination |
| Best for | Focused tasks where only the result matters | Complex work requiring discussion & collaboration |
| Token cost | Lower | Higher |

- Speaker notes: "Use subagents when you just need a result. Use agent teams when agents need to talk."

**Slide 24 — Architecture diagram:**
- Side-by-side comparison:
  - Left: Subagent model (parent → child → result back to parent)
  - Right: Agent team model (lead + teammates with bidirectional arrows and shared task list)
- Speaker notes: "Visual reinforcement of the table"

**Slide 25 — My honest take:**
- "I use agent teams to get a plan built quicker"
- "Spin up teammates to research, explore, validate different angles"
- "Arrive at a solid plan faster"
- "For implementation → worktrees and parallel sessions"
- Speaker notes: "Be real with the audience. Agent teams are great for planning, not great for implementation orchestration."

**Slide 26 — Where agent teams struggle:**
- "Higher-level orchestration across multiple features"
- "Session resumption doesn't work with in-process teammates"
- "Task status can lag"
- "One team at a time"
- "Still experimental"
- Speaker notes: "Don't oversell. These are real limitations."

**Slide 27 — Best practices (from the docs):**
- 3-5 teammates
- 5-6 tasks per teammate
- Each teammate owns different files
- Start with research/review
- Speaker notes: "Quick practical tips if they want to try agent teams after this session"

**Slide 28 — For higher-level orchestration:**
- "Want multi-feature orchestration? Look into:"
- Gastown — multi-agent orchestration across repos
- Citadel — dependency-aware task scheduling
- Mission Control — higher-level orchestration layer
- Speaker notes: "Pointer for self-study. We won't cover these today."

**Slide 29 — The spectrum:**
- Horizontal spectrum diagram:
  - Left: "Single Agent" (simple)
  - Middle-left: "Worktrees + Parallel Sessions" (today's focus)
  - Middle-right: "Agent Teams" (planning acceleration)
  - Right: "Full Orchestration" (Gastown/Citadel/MC)
- Arrow pointing to "Worktrees + Parallel Sessions" with "YOU ARE HERE"
- Speaker notes: "Position what we've learned on the spectrum. Today we practice the sweet spot. Transition: Today in the workshop, you'll use worktrees and parallel sessions to implement features independently. That's the foundation. Agent teams build on top of that — try them once you're comfortable with the parallel workflow."

**Slide 30 — Questions?**
- Large text: "Questions?"
- Subtitle: "Before we jump into the hands-on session"
- Speaker notes: "5 min buffer. Take questions. If no questions, use the time to let people set up early."

- [ ] **Step 2: Verify Act 4 renders correctly**

Check table styling, architecture diagrams, spectrum diagram.

- [ ] **Step 3: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: add Act 4 slides — Agent teams, honest take, and spectrum"
```

---

### Task 6: Workshop transition slides and final polish

**Files:**
- Modify: `slides/index.html`

- [ ] **Step 1: Add transition and closing slides**

**Slide 31 — Transition to workshop:**
- "Let's put this into practice"
- "You'll build a Repo Doctor tool using parallel worktrees"
- "45 min slides ✓ → 1h45 hands-on"
- Speaker notes: "Bridge to the hands-on section"

**Slide 32 — Workshop overview:**
- What you're building: `repo-doctor` — CLI tool that produces an HTML health report
- Show sample HTML report screenshot/mockup
- 5 core analyzers, 3 stretch goals
- Speaker notes: "Quick preview of what they'll build"

**Slide 33 — Your workflow for the next 1h45:**
- Timeline table:
  - 0:00-0:10 — Setup (clone, install, run skeleton)
  - 0:10-0:20 — Plan (read epic, set up worktrees)
  - 0:20-1:20 — Build (parallel agents, one per worktree)
  - 1:20-1:35 — Merge & Run (merge branches, view report)
  - 1:35-1:45 — Show & Tell
- Speaker notes: "Set expectations for timing"

**Slide 34 — Quick start commands:**
- Code blocks:
  ```
  git clone <repo-url>
  cd repo-doctor
  bun install          # or: bundle install
  bun run doctor test-fixtures/unhealthy-repo/
  ```
- Speaker notes: "This is what they do in the first 10 minutes"

**Slide 35 — The parallel workflow (recap):**
- Code blocks:
  ```
  # Terminal 1
  claude --worktree
  > "Implement the TODO/FIXME Debt Tracker per EPIC.md"

  # Terminal 2
  claude --worktree
  > "Implement the Dead Code Detector per EPIC.md"

  # Terminal 3
  claude --worktree
  > "Implement the Dependency Staleness Checker per EPIC.md"
  ```
- Speaker notes: "Concrete commands they'll run. Reference slide they can come back to."

**Slide 36 — Go!**
- Large text: "Go build."
- Subtext: "Read EPIC.md. Decompose. Parallelise. Merge."
- Speaker notes: "Release them. Walk around and help."

- [ ] **Step 2: Final polish pass**

Review all slides in sequence:
- Consistent styling (fonts, colours, spacing)
- All diagrams render correctly
- Slide count matches navigation
- No orphaned speaker notes
- Ensure total slide count is 36 (~1.25 min per slide, good pace)
- Verify no TODO or placeholder text remains
- Verify all CSS class names are consistent across slides

- [ ] **Step 3: Verify full deck**

Open in browser, navigate through all 36 slides. Confirm flow, transitions, readability.

- [ ] **Step 4: Commit**

```bash
git add workshop-slides/index.html
git commit -m "feat: add workshop transition slides and final polish"
```
