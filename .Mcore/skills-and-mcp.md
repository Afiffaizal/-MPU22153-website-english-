# Skills and MCP operations

This is the operating guide, not a development plan. Keep it with the template.

## Automatic selection

After Login, the AI receives the current shared and personal skill catalog. For every new instruction call:

```powershell
.\.Mcore\tools\Setup-MemoryCore.ps1 -Action Route -Instruction "Review the login code"
```

Route returns baseline skills and task suggestions using English/Malay terms and explicit names. The AI chooses additional skills by meaning from the catalog; keyword matching is assistance, not proof of relevance. Read the relevant SKILL.md before using it. Ponytail, Caveman and RTK are considered on every task, and only applicable actions are taken. A writing task does not need a fake terminal command merely to use RTK.

The catalog is rebuilt from files on Login and Skills/Route actions. New shared skills appear after pull; the active user's personal skills are included without opening another user's cache. No native provider menu is required. The AI may identify a missing capability and recommend a skill, but asks Team or Personal before adding one unless scope is already known. All bundled skills are shared.

## Setup and dependencies

The 26 bundled SKILL.md files run as instructions in the active AI. They do not require separate AI accounts. Strix-Security is an AI-performed local security review with a checklist and evidence requirements; no Strix engine, endpoint or key is used. Ponytail/Caveman are native behavior skills, not installed traffic proxies.

Setup and the launcher run `tools/Setup-Tools.ps1`. On Windows x64 it installs missing RTK from a pinned, SHA256-verified official archive and SkillSpector from a pinned source commit using uv/Python. It can bootstrap a pinned uv binary too. Existing executable tools are checked rather than silently replaced. Binaries and package caches live on the device outside this project; no binaries, accounts or test reports are shipped in the template. A missing network connection or blocked installation produces a real error and setup must be retried.

Use `Setup-Tools.ps1 -CheckOnly` for paths and availability without installation. The launcher supplies those paths to the provider process. `Read-Context.ps1` provides bounded text reads with line numbers and raw fallback for any task. RTK applies to supported shell commands; none of these tools can intercept every proprietary host tool.

## Adding a skill

1. Use the stated scope or ask Team versus Personal. Shared skills go in `.Mcore/Feature/<name>/`; personal skills in ignored `.Mcore/users/<user-id>/skills/<name>/`.
2. Obtain the exact local candidate without executing it. Run `Feature/Skill-Recommender/Invoke-SkillFlow.ps1 -Action Review -CandidatePath <path> -Name <name> -Scope Team` (or Personal).
3. Inspect the full SkillSpector report and candidate code, dependencies, network and credential use. Static analysis is not a guarantee. No skill contents are sent to an LLM with `--no-llm`; dependency metadata may be queried against OSV.
4. Run `-Action Install -ReviewId <id> -ManualReviewComplete` only after that inspection. Changed content, a blocking result or an existing target stops installation.
5. Call RecordTurn and publish shared changes only within the user's Git authorization.

Review reports belong to a configured instance's ignored runtime. Maintainer tests run on temporary copies outside the distributed template.

## MCP and provider switching

Shared MCP declarations live in `mcp-servers.json`; personal declarations stay in the active user's ignored folder. Credentials stay on the device. The blank template has no selected MCP servers and does not claim to configure arbitrary provider hosts. Consult `adapters/README.md` for supported launchers.

Use Start-MemoryCore with Codex, Claude, Qwen or ContextOnly. The authenticated briefing contains the same user/AI identity, recent events and catalog; Team history arrives on another device after Git push/pull and vault unlock. A host needs access to the briefing/files and the tools needed by a task. A browser-only host needs the user to supply context. Video rendering needs actual media tools/assets; a scheduled job needs an actual scheduler. MemoryCore cannot manufacture capabilities the host does not provide.

## Recording

Call RecordTurn after every instruction. Reuse an EventId only to retry the exact same outcome; a changed outcome needs a new ID. The active agent chosen at Login is used by subsequent helper actions unless another AgentId is explicit. Team Login rebuilds that member's cache from encrypted events. Active turn memory is bounded while diary history remains searchable. Skill choice and verification evidence should be included in the concise outcome when they matter.
