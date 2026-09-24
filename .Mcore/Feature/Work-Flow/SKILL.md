---
name: memorycore-workflow
description: Route a project request through direct work, a single build, an epic, or a multi-epic project while preserving decisions and handoff in MemoryCore. Use for planning, implementing, reviewing, or resuming project work.
---

# MemoryCore workflow

Use the authenticated MemoryCore identity from `Login`. The active AI provider carries out the work under the same registered agent name. Read `.Mcore/skills-and-mcp.md` when changing skill routing or integration; ordinary tasks need only this skill.

## Choose the smallest sufficient path

- **Direct:** The outcome is clear, small, and low risk. Inspect what is needed, make the change, verify it, then call `RecordTurn`.
- **Build:** One outcome needs investigation or substantive implementation. State the intended outcome and acceptance checks, inspect the existing project, resolve material gaps from evidence, implement, review, verify, and record the result.
- **Epic:** One outcome needs several work sessions or people. Write a short spec with constraints and ordered stories. Give each story a stable ID, owner, acceptance checks, dependencies, and current status. Build and verify one story at a time, then check the stories together and record a retrospective.
- **Project:** Several epics need shared product or technical decisions. Record those decisions once, link each epic to them, and check integration at epic boundaries.

The amount of planning follows the size and risk of the work. Do not require a spec or approval ceremony for an obvious edit. Ask only for decisions that project evidence cannot settle. If the user already asked for execution, proceed within that authorization and the host's permissions.

## Record and hand off

Use `SaveTopic -TopicId <stable-id> -Text <concise update>` for a reusable spec, story decision, status change, or retrospective. In Team mode this creates an encrypted project event. Use `UpdateSession -Text <next step and blockers>` before a provider or device handoff. Use `Recall -Query <id or keyword>` to recover older decisions. The helper's existing topic notes are append-only; clearly mark superseded decisions instead of silently rewriting history.

After **every user instruction**, call `RecordTurn` for memory and diary, even when the instruction led only to planning or was blocked. Confirm the helper succeeded before saying a record was saved. When no setup/login exists, edit only public template material as permitted by `.Mcore/rules.md` and disclose the pending personal record.

For reviews, report what was checked, which findings belong to the current work, what was fixed, and what remains. Do not call one model's self-review independent. Keep unverified assumptions visible, and preserve full evidence when a compact tool output omits a needed detail.
