# Claude Code Statusline

Custom statusline configurations for [Claude Code](https://claude.ai/code) CLI.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/install.sh | bash
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
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-minimal.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-standard.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-full.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-custom.sh

chmod +x ~/.claude/statusline.sh
```

### 3. Configure

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## JSON Data Reference

Data available from Claude Code:

| Data | JSON Path |
|------|-----------|
| Model name | `.model.display_name` |
| Context size | `.context_window.context_window_size` |
| Current usage | `.context_window.current_usage` |
| Input tokens | `.context_window.total_input_tokens` |
| Output tokens | `.context_window.total_output_tokens` |
| Duration (ms) | `.cost.total_duration_ms` |
| Lines added | `.cost.total_lines_added` |
| Lines removed | `.cost.total_lines_removed` |
| Session cost | `.cost.total_cost_usd` |
| Version | `.version` |
| Session ID | `.session_id` |

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

**Colors showing as escape codes?**
- Use `$'\033[...'` syntax (not `\033[...]` strings)

**Testing manually:**
```bash
echo '{"model":{"display_name":"Opus"}}' | ~/.claude/statusline.sh
```

## License

MIT
