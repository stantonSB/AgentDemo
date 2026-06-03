# Workshop Demo TODO

- [ ] **Fix Ruby and TS repo-doctor projects so both have genuinely failing tests**
  - The Ruby repo-doctor has a path resolution bug (`Dir.children` fails on relative paths) — ensure the test suite catches this
  - The TS repo-doctor needs similar coverage gaps — tests should exist but fail against known broken fixtures
  - Both projects should have a realistic "red" state so the live demo starts with actual failing tests to fix

- [ ] **Refocus demo to show brainstorming a prompt and splitting a design doc into plans**
  - The core demo flow should be: start with a vague feature request, use the brainstorming skill to explore intent and requirements, then show how that output feeds into a design doc that gets decomposed into discrete implementation plans
  - Show the full loop: brainstorm → design doc → write-plan → parallel execution
  - Make it clear this is how you go from "I want X" to structured, executable work

- [ ] **Add a slide about the brainstorming/write-plan skills used for decomposition**
  - Cover the brainstorming skill (explores user intent, surfaces edge cases, shapes requirements before any code is written)
  - Cover the write-plan skill (takes a spec or design doc and produces a step-by-step implementation plan with dependencies)
  - Show how these two skills chain together: brainstorm clarifies *what*, write-plan clarifies *how*
  - Mention that plans can then be executed in parallel via subagent-driven development
