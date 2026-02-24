# Claude Code Statusline

Custom statusline configurations for [Claude Code](https://claude.ai/code) CLI.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master/install.sh | bash
```

Interactive menu with 4 options:

```
╔════════════════════════════════════════════════════════════════════╗
║              Claude Code Statusline Installer                      ║
╚════════════════════════════════════════════════════════════════════╝

  [1] Minimal
      user@host:/current/directory

  [2] Standard
      user@host:/directory (main) [Opus] [12%]

  [3] Full
      user@host:/dir (main) [Opus] [12%] 5m23s +120/-15 ↓45k/↑12k

  [4] Custom (Recommended)
      Toggle each feature ON/OFF
```

## Versions

### 1. Minimal
```
user@host:/current/directory
```

### 2. Standard
```
user@host:/current/directory (main) [Opus] [12%]
```

| Element | Color | Description |
|---------|-------|-------------|
| `user@host` | Green | Username and hostname |
| `/directory` | Blue | Current working directory |
| `(main)` | Yellow | Git branch |
| `[Opus]` | Cyan | Claude model |
| `[12%]` | Magenta | Context usage |

### 3. Full
```
user@host:/dir (main) [Opus] [12%] 5m23s +120/-15 ↓45k/↑12k
```

| Element | Color | Description |
|---------|-------|-------------|
| `5m23s` | White | Session duration |
| `+120` | Green | Lines added |
| `-15` | Red | Lines removed |
| `↓45k` | Cyan | Input tokens |
| `↑12k` | Cyan | Output tokens |

### 4. Custom (Recommended)

Toggle any feature ON/OFF by editing the config section:

```bash
# Edit after install
nano ~/.claude/statusline.sh
```

```bash
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFIGURATION - Set to true or false
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHOW_USER_HOST=true      # user@host
SHOW_DIRECTORY=true      # /current/directory
SHOW_GIT_BRANCH=true     # (main)
SHOW_MODEL=true          # [Opus]
SHOW_CONTEXT_PCT=true    # [12%]
SHOW_DURATION=true       # 5m23s
SHOW_LINES_CHANGED=true  # +120/-15
SHOW_TOKENS=true         # ↓45k/↑12k
SHOW_COST=false          # $0.45
```

**Examples:**

| Config | Result |
|--------|--------|
| All true | `user@host:/dir (main) [Opus] [12%] 5m23s +120/-15 ↓45k/↑12k` |
| Model + Context only | `[Opus] [12%]` |
| Git + Tokens | `(main) ↓45k/↑12k` |
| Dir + Cost | `/current/directory $0.45` |

## Available Features

| Feature | Variable | Example | Color |
|---------|----------|---------|-------|
| User & Host | `SHOW_USER_HOST` | `user@host` | Green |
| Directory | `SHOW_DIRECTORY` | `/path/to/dir` | Blue |
| Git Branch | `SHOW_GIT_BRANCH` | `(main)` | Yellow |
| Model | `SHOW_MODEL` | `[Opus]` | Cyan |
| Context % | `SHOW_CONTEXT_PCT` | `[12%]` | Magenta |
| Duration | `SHOW_DURATION` | `5m23s` | White |
| Lines Changed | `SHOW_LINES_CHANGED` | `+120/-15` | Green/Red |
| Tokens | `SHOW_TOKENS` | `↓45k/↑12k` | Cyan |
| Cost | `SHOW_COST` | `$0.45` | Yellow |
| Remaining % | `SHOW_REMAINING_PCT` | `[88% left]` | Magenta |
| API Wait Time | `SHOW_API_DURATION` | `api:2s` | Dim |
| Vim Mode | `SHOW_VIM_MODE` | `VIM:NORMAL` | Cyan |
| Agent Name | `SHOW_AGENT_NAME` | `agent:name` | Yellow |
| CC Version | `SHOW_VERSION` | `v1.0.80` | Dim |

## Manual Installation

### 1. Install jq

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Arch Linux
sudo pacman -S jq
```

### 2. Download script

```bash
mkdir -p ~/.claude

# Choose ONE:
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master/statusline-minimal.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master/statusline-standard.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master/statusline-full.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master/statusline-custom.sh

chmod +x ~/.claude/statusline.sh
```

### 3. Configure

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 2
  }
}
```

> `padding` adds extra horizontal spacing (in characters). Optional, defaults to `0`.

## JSON Data Reference

Data available from Claude Code via stdin:

| Data | JSON Path | Notes |
|------|-----------|-------|
| Model display name | `.model.display_name` | e.g. `"Opus"` |
| Model ID | `.model.id` | e.g. `"claude-opus-4-6"` |
| Current directory | `.workspace.current_dir` | Preferred over `.cwd` |
| Project directory | `.workspace.project_dir` | Where Claude Code was launched |
| Current directory (alias) | `.cwd` | Same value as `.workspace.current_dir` |
| Context used % | `.context_window.used_percentage` | Pre-calculated; use this, not manual math |
| Context remaining % | `.context_window.remaining_percentage` | Pre-calculated |
| Context size | `.context_window.context_window_size` | 200000 default, 1000000 with extended |
| Current usage | `.context_window.current_usage` | `null` before first API call |
| Input tokens (cumulative) | `.context_window.total_input_tokens` | Across entire session |
| Output tokens (cumulative) | `.context_window.total_output_tokens` | Across entire session |
| Total cost | `.cost.total_cost_usd` | USD |
| Session duration | `.cost.total_duration_ms` | Wall-clock ms |
| API wait time | `.cost.total_api_duration_ms` | ms waiting for API |
| Lines added | `.cost.total_lines_added` | |
| Lines removed | `.cost.total_lines_removed` | |
| Exceeds 200k tokens | `.exceeds_200k_tokens` | Boolean; fixed 200k threshold |
| Vim mode | `.vim.mode` | `"NORMAL"` or `"INSERT"`; absent when vim off |
| Agent name | `.agent.name` | Absent unless `--agent` flag is used |
| Output style | `.output_style.name` | |
| Claude Code version | `.version` | |
| Session ID | `.session_id` | |
| Transcript path | `.transcript_path` | |

### Full JSON Schema

```json
{
  "cwd": "/current/working/directory",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.jsonl",
  "model": {
    "id": "claude-opus-4-6",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory"
  },
  "version": "1.0.80",
  "output_style": { "name": "default" },
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 8,
    "remaining_percentage": 92,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "exceeds_200k_tokens": false,
  "vim": { "mode": "NORMAL" },
  "agent": { "name": "security-reviewer" }
}
```

> **Note:** `vim` is absent when vim mode is off. `agent` is absent unless `--agent` is used. `context_window.current_usage` is `null` before the first API call.

## Compatibility

- ✅ Linux (Ubuntu, Debian, Arch, etc.)
- ✅ macOS (Intel and Apple Silicon)
- ✅ Windows (WSL)

## Official Documentation

- [Claude Code Statusline](https://docs.anthropic.com/en/docs/claude-code/statusline)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code GitHub](https://github.com/anthropics/claude-code)

## Troubleshooting

**Statusline not appearing?**
```bash
chmod +x ~/.claude/statusline.sh
jq --version  # Ensure jq is installed
```

If `disableAllHooks` is set to `true` in your `~/.claude/settings.json`, the status line is also disabled. Remove it or set it to `false`.

**Colors showing as escape codes?**
- Use `$'\033[...'` syntax (not `\033[...]` strings)

**Testing manually:**
```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp/test"},"context_window":{"used_percentage":25,"remaining_percentage":75}}' | ~/.claude/statusline.sh
```

## License

MIT
