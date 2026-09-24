# MemoryCore

The root setup wizard, setup guide and AGENTS.md are the entry points. This folder contains the universal rules, bundled skills and helper scripts. The template has no accounts, memories, keys or runtime reports.

## Operation

Run Status, then setup or authenticated Login. Login supplies the registered user, AI identity, shared project context and current skill catalog. Route helps the AI select skills for each instruction. RecordTurn saves its outcome to both memory and diary. Start-MemoryCore prepares the same identity and context for a supported provider.

Team users authenticate through GitHub CLI and locally unlock the project vault. The owner registers members; GitHub repository access is managed separately. All members holding the shared passphrase can read shared project events. Author labels are helper-generated provenance, not digital signatures or protection against a key holder rewriting history.

## Data after setup

| Path | Purpose | Git |
| --- | --- | --- |
| team.json | Team roster and primary AI names | Shared |
| project-vault.json | Encryption parameters and verifier | Shared |
| project-events/*.json | Encrypted append-only project history | Shared |
| state.json | Solo account metadata | Ignored |
| users/ | Local per-user cache and personal skills | Ignored |
| .login.json / .vault-key.dpapi | Device login receipt / Windows-protected key cache | Ignored |
| .runtime/ | Temporary briefings and review reports | Ignored |
| Feature/ | Bundled and shared skills | Shared |

Team Login rebuilds the active member's profile, memory, diary, topics and session from the shared log, including on a second device. Pull before Login to receive other-device events. Solo mode is tied to the configured local OS account. Active turn memory is bounded at 100 entries; Compact keeps 20 recent turns and a previous memory snapshot. Diary history remains searchable.

The key cache uses Windows DPAPI, so team key caching currently requires Windows. Cross-provider instructions do not imply support for every operating system or AI host. Keys are not AI-only. Revoking a former member's access to old copies requires key rotation outside this helper.

## Tools and checks

Setup-Tools automatically provisions missing RTK and SkillSpector on Windows x64. Ponytail and Caveman behavior is bundled as native skills; security review uses the active AI. External binaries live in the device cache, outside the project.

See [Feature catalog](Feature/README.md), [skills/MCP operations](skills-and-mcp.md) and [provider adapters](adapters/README.md). Run `tools/Test-Template.ps1` for static template checks and `tests/Test-MemoryCore.ps1` for isolated behavior tests. These do not prove every provider will obey instructions; test the actual host before claiming compatibility.
