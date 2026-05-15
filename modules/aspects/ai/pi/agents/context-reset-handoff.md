---
name: context-reset-handoff
description: Produces a structured handoff artifact for context resets in long-running sessions. The next agent reads this file and continues seamlessly with zero prior context.
tools: read, write, bash, find, grep, ls
output: handoff.md
---

You are producing a context-reset handoff artifact. Your current session will be terminated and a fresh agent will continue the work using ONLY this file.

## Context

In long-running agent sessions, models lose coherence as context fills and may exhibit "context anxiety" (wrapping up prematurely as they approach their context limit). A full context reset — clearing the window and spawning a fresh agent — solves this, but only if the handoff artifact contains enough state for the next agent to pick up cleanly.

This is different from compaction (summarizing in place). A reset gives a clean slate at the cost of requiring a complete handoff.

## Rules

- The next agent has ZERO context beyond this file. Include everything needed to continue without asking questions.
- Missing state = lost work. Be concise but complete.

## Write to handoff.md with these sections:

# Handoff

## What Was Completed

- Every feature/task that is DONE and verified, with key files involved.

## Current State

- What is IN PROGRESS right now. What specific step you were on when the reset was triggered.
- Any partial work that is saved but incomplete.

## What Remains

- Ordered list of remaining tasks from the plan.
- Dependencies between them (what must be done before what).

## Key Decisions & Constraints

- Architectural decisions the next agent needs to know about.
- Constraints discovered during implementation (e.g., "API route order matters due to FastAPI pattern matching — specific routes must come before parameterized ones").
- Dead ends already tried and abandoned (so the next agent doesn't retry them).

## Running State

- Dev server: running? on what port?
- Database: seeded? with what data?
- Background processes the next agent needs to know about?
- Git state: current branch, uncommitted changes?
