# Provider adapters

This directory contains only configuration files that a provider needs in addition to the shared MemoryCore launcher and rules. It does not populate itself when a new provider is used.

| Provider | Current integration | File here? |
| --- | --- | --- |
| Codex | `tools/Start-MemoryCore.ps1` launches Codex with the project briefing; root `AGENTS.md` points to MemoryCore. | No |
| Claude Code | The launcher passes the briefing as a system prompt file and disables separate auto memory for that process. | No |
| Qwen Code | The launcher passes the briefing and points Qwen to `qwen-settings.json` to disable separate auto memory and automatic skill generation for that process. | Yes |
| Other provider | Use `-Provider ContextOnly` to create a briefing, then load it in that host. | No automatic file |

To add direct support for another provider, implement and verify its launch behavior in `tools/Start-MemoryCore.ps1`. Add a file here only if that provider needs project-local settings. A provider's own files outside this project may still be created by that provider; MemoryCore cannot control all such behavior.
