---
name: writing-plans
description: "Use after requirements or a design are accepted and the work needs multiple ordered changes. Produce an executable Markdown plan before implementation."
---

# Writing Plans

Write a plan another capable engineer can execute without reconstructing the
design from chat history.

## Before writing

- Read the accepted specification, repository instructions, relevant code,
  tests, and recent decisions.
- Confirm the work is one coherent deliverable. Split independent subsystems
  into separate plans.
- Map the files and interfaces that already own the behavior.

Save the plan under `docs/plans/YYYY-MM-DD-<topic>.md` unless the repository
specifies another location.

## Required header

Start with:

```markdown
# <Deliverable> implementation plan

**Goal:** <one observable outcome>
**Approach:** <two or three sentences>
**Constraints:** <security, compatibility, dependency, and scope limits>
**Verification:** <commands and read-backs that define completion>
```

## Task contract

Each task must be independently reviewable and contain:

- the exact files to create, modify, and test;
- the behavior and interfaces it consumes and produces;
- dependencies on earlier tasks;
- one small sequence of test, implementation, and verification steps;
- exact commands with expected outcomes;
- a focused commit boundary.

Use checkboxes so the plan can act as execution state:

```markdown
### Task N: <result>

**Files**
- Modify: `path/to/file`
- Test: `path/to/test`

**Contract**
- Input: `<exact input>`
- Output: `<exact observable behavior>`

- [ ] Add the failing check for `<behavior>`.
- [ ] Run `<command>`; expect `<specific failure>`.
- [ ] Implement the smallest change at `<owner path>`.
- [ ] Run `<focused command>`; expect pass.
- [ ] Run `<regression command>`; expect pass.
- [ ] Commit the task with `<message intent>`.
```

Include concrete snippets when an interface or data shape could otherwise be
interpreted more than one way. Do not fill the plan with code that is already
obvious from an established local pattern.

## Plan review

Before handoff:

1. Map every accepted requirement to a task and verification step.
2. Remove placeholders, speculative features, duplicate work, and vague
   phrases such as “handle errors.”
3. Check that names, types, paths, and task dependencies agree throughout.
4. Confirm security, accessibility, and data-loss protections were not
   simplified away.
5. Ensure the final task performs the repository release gates and read-back.

Return the plan path, key decisions encoded in it, and the first executable
task. When execution mode is not already specified, ask whether to execute
inline or by bounded independent workers.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the executable-plan pattern in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
