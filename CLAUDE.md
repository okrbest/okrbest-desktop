<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

# okrbest-desktop — Claude Code Guide

## Project conventions

This repo's full engineering conventions (architecture, build system, IPC, code
style, testing) live in **[AGENTS.md](AGENTS.md)**. Read it before writing code.
Everything in AGENTS.md applies to Claude Code too; this file only adds the
spec-kit + superpowers development workflow.

## Spec-Kit + Superpowers Integrated Workflow

This is a **spec-kit project**. Feature work runs a fixed pipeline that combines
`superpowers` (idea formation + implementation discipline) with `spec-kit`
(specification → planning → tasks → implementation). Follow it for any feature,
behavior change, or new functionality.

### Pipeline

```
Feature request
  │
  ├─ [Complexity gate]
  │     • Complex / ambiguous  → superpowers:brainstorming first
  │                              (form intent, requirements, design)
  │     • Simple / well-defined → go straight to /speckit-specify
  │
  ├─ ★ EXPLICIT handoff (NEVER silent) — after brainstorming, present a visible choice:
  │     ① proceed to /speckit-specify   ② refine the design more   ③ pause/hold
  │     Do not auto-end brainstorming or auto-enter spec-kit. The user decides
  │     the handoff timing and what design is carried over.
  │
  ├─ /speckit-specify  → /speckit-clarify (if needed) → /speckit-plan → /speckit-tasks
  │
  ├─ Offer /speckit-analyze (cross-artifact consistency). Run it on request.
  │     ▶ Completing tasks (+ optional analyze) = SPEC PHASE DONE ◀
  │
  ├─ ★ COMMIT GATE 1 (recommend only — never auto-commit):
  │     Recommend committing the spec artifacts under specs/. Wait for the user.
  │
  ├─ /speckit-implement — during implementation, superpowers skills engage:
  │     • superpowers:test-driven-development      (write tests first)
  │     • superpowers:subagent-driven-development   (independent tasks)
  │     • superpowers:systematic-debugging          (any bug/test failure)
  │     • superpowers:verification-before-completion (evidence before claims)
  │
  ├─ Verify: run `npm run check` (lint + type check + unit tests). Confirm green.
  │
  └─ ★ COMMIT GATE 2 (recommend only — never auto-commit):
        Recommend committing the implementation. Wait for the user.
```

### Rules (do not violate)

1. **Commit gates are recommend-only.** Never auto-commit at Gate 1 or Gate 2.
   Suggest the commit, show what would be committed, and let the user decide.
2. **The brainstorming → spec-kit handoff is an explicit user choice.** Never
   silently transition. Present options ①②③ and wait.
3. **Brainstorming is complexity-gated.** Skip the long Q&A for simple/clear
   work and go straight to `/speckit-specify`. Use brainstorming for complex or
   ambiguous work. The goal is avoiding pointless Q&A, never skipping design.
   Record reasonable defaults as Assumptions; reserve `[NEEDS CLARIFICATION]`
   for decisions that genuinely matter.
4. **spec-kit artifacts under `specs/` ARE committed** at Gate 1. The general
   "don't commit ad-hoc planning markdown" rule targets scratch files (e.g. a
   root PLAN.md), not spec-kit's `specs/` outputs.
5. **Before recommending Gate 2**, run `npm run check` and verify it passes.
   For UI/behavior changes, verify the actual app where practical (see AGENTS.md
   Troubleshooting / `npm run watch`).
6. **`.specify/extensions.yml` auto-offers an agent-context refresh** after
   specify/plan. Accept it when prompted.
7. **superpowers always applies.** Brainstorming and the implementation-phase
   skills (TDD, systematic-debugging, verification-before-completion) are not
   optional disciplines — only their *triggering* is gated by complexity/phase.

### speckit skills available

`/speckit-constitution`, `/speckit-specify`, `/speckit-clarify`,
`/speckit-plan`, `/speckit-tasks`, `/speckit-analyze` (optional),
`/speckit-checklist` (optional), `/speckit-implement`. Skills installed under
`.claude/skills/speckit-*`; shared infrastructure under `.specify/`.
