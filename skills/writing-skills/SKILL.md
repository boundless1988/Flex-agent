---
name: writing-skills
description: Use when creating, editing, or auditing Agent Harness skills under .agent-harness/skills, including SKILL.md structure, trigger metadata, boundaries, cross-skill references, helper files, scripts, and host-specific references.
---

# Writing Skills

Create, adapt, or review Agent Harness skills while preserving local workflow boundaries.

## Entry Conditions

Use this skill for Harness self-maintenance when the task involves:

- creating a new target skill;
- editing an existing skill;
- adapting existing local skill material;
- auditing skill frontmatter, references, helper files, scripts, or boundaries.

Do not use this skill for ordinary repository implementation work, code review, debugging, or verification unless the artifact being changed is a Harness skill.

## Required Inputs

Before changing a skill, identify:

- the design source that governs the work;
- the target skill name and directory;
- the local skill directory, if it already exists;
- the current batch scope.

If any of these inputs are missing and cannot be inferred from the task, return the minimum missing items instead of editing.

## Decision Priority

When instructions or local files conflict, apply this order:

1. Agent Harness design source;
2. current user instruction;
3. existing local skill conventions;
4. general skill authoring practice.

Do not preserve old behavior merely to stay close to prior wording.

## Reading Requirements

For each target skill:

1. Read the governing design source.
2. Read the local skill directory completely, if it exists.
3. Read every helper file, script, prompt, reference, or asset that the target skill currently references.
4. Search the target skill for cross-skill references, host assumptions, fixed paths, tool names, and lifecycle actions.

Do not edit before the necessary source material has been read.

## Skill Shape

Every local skill must use:

```text
skill-name/
├── SKILL.md
├── scripts/              # only for deterministic operations
├── references/           # only for on-demand guidance
│   └── hosts/            # only for host-specific differences
└── agents/               # only if the host needs metadata
```

`SKILL.md` must contain only YAML frontmatter with `name` and `description`, followed by Markdown instructions.

The frontmatter `name` must exactly match the directory name.

The description must state when to use the skill and include concrete trigger terms. Do not put workflow details in the description when they belong in the body.

## Content Rules

Write the public skill behavior in `SKILL.md`:

- trigger conditions and non-triggers;
- inputs and outputs;
- preconditions;
- execution method;
- invariants and failure conditions;
- boundaries with other skills;
- self-checks before returning.

Keep host-specific tool names, pane behavior, subagent invocation syntax, permissions, and result capture details in `references/hosts/` or the integration layer, not in the shared workflow.

Only add helper files when the skill references them and they provide durable value. Prefer no helper file over a copied upstream file that is unused, host-specific, or outside current scope.

Scripts are allowed only for deterministic, repeatable, idempotent operations with structured output. Do not add Unix-only scripts to the shared skill path unless the current design explicitly supports them.

## Harness Boundary Checks

Before saving a skill, remove or rewrite content that does any of the following unless the design source explicitly permits it:

- references deleted or undefined skills;
- uses undefined namespaces;
- writes fixed external paths;
- requires intermediate commits, WIP commits, or frequent commits;
- makes a specialty skill advance global workflow phases;
- makes a specialty skill update `control.md`;
- lets non-controller skills call `multi-agent-coordination`;
- makes TDD mandatory for all changes;
- embeds host-specific tools directly in shared workflow text;
- references helper files that are not present in the local skill directory;
- exposes unsupported Unix-only scripts in the current Windows-first environment.

## Relationship to Other Skills

- `workflow-controller` owns phase decisions, state updates, skill selection, and calls to `multi-agent-coordination`.
- Specialty skills return outputs to the controller or current caller; they do not advance global state.
- `brainstorming` clarifies unresolved requirements and design.
- `writing-plans` produces implementation plans after design is resolved.
- `test-driven-development` is optional unless the controller or implementation context selects it.

Do not create skills outside the confirmed target skill list without explicit design or user approval.

## Adaptation Method

When adapting existing material:

1. Identify the behavior worth keeping.
2. Identify assumptions that conflict with the Harness design.
3. Keep the method, structure, or checklist only when it remains valid after local boundary rules.
4. Rewrite names, paths, skill references, and lifecycle actions into local Harness terms.
5. Drop auxiliary files that are not referenced by the final local skill.
6. Keep the change scoped to the current batch.

When editing an existing local skill, preserve it if the audit finds no conflict, missing capability, or invalid dependency.

## Output

Return a concise report with:

- modified files;
- source files consulted;
- content retained;
- content removed or rewritten;
- design-source mapping;
- new dependencies or helper files;
- unresolved issues;
- required human decisions.

## Self-Review

Before returning, check:

- the directory name and frontmatter `name` match;
- frontmatter has only `name` and `description`;
- every referenced helper file exists;
- cross-skill references point to confirmed local target skills;
- no deleted skill, upstream namespace, or fixed upstream path remains;
- no specialty skill owns controller duties;
- host-specific details are isolated;
- Windows-current constraints are respected;
- no unrelated skill or design file was modified.
