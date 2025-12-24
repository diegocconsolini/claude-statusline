# Claude Code Statusline

Custom statusline configurations for [Claude Code](https://claude.ai/code) CLI.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/install.sh | bash
```

This will show an interactive menu to choose your preferred version.

## Versions

### 1. Minimal
```
user@host:/current/directory
```
Simple and clean - just shows your location.

### 2. Standard (Recommended)
```
user@host:/current/directory (main) [Opus] [12%]
```
| Element | Color | Description |
|---------|-------|-------------|
| `user@host` | Green | Username and hostname |
| `/directory` | Blue | Current working directory |
| `(main)` | Yellow | Git branch (if in repo) |
| `[Opus]` | Cyan | Active Claude model |
| `[12%]` | Magenta | Context window usage |

### 3. Full
```
user@host:/dir (main) [Opus] [12%] 5m23s +120/-15 ↓45k/↑12k
```
Everything in Standard, plus:

| Element | Color | Description |
|---------|-------|-------------|
| `5m23s` | White | Session duration |
| `+120` | Green | Lines added |
| `-15` | Red | Lines removed |
| `↓45k` | Cyan | Input tokens |
| `↑12k` | Cyan | Output tokens |

## Manual Installation

### 1. Install jq (required)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Arch Linux
sudo pacman -S jq
```

### 2. Download your preferred version

```bash
mkdir -p ~/.claude

# Choose ONE:
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-minimal.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-standard.sh
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline-full.sh

chmod +x ~/.claude/statusline.sh
```

### 3. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Available Data

The statusline script receives JSON from Claude Code with this data:

| Data | JSON Path | Used In |
|------|-----------|---------|
| Model name | `.model.display_name` | Standard, Full |
| Context size | `.context_window.context_window_size` | Standard, Full |
| Current tokens | `.context_window.current_usage` | Standard, Full |
| Session duration | `.cost.total_duration_ms` | Full |
| Lines added | `.cost.total_lines_added` | Full |
| Lines removed | `.cost.total_lines_removed` | Full |
| Input tokens | `.context_window.total_input_tokens` | Full |
| Output tokens | `.context_window.total_output_tokens` | Full |
| Session cost | `.cost.total_cost_usd` | (available) |
| Claude Code version | `.version` | (available) |
| Session ID | `.session_id` | (available) |

## Customization

Edit `~/.claude/statusline.sh` to customize colors or add/remove elements.

### Color Codes

```bash
GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
YELLOW=$'\033[01;33m'
CYAN=$'\033[01;36m'
MAGENTA=$'\033[01;35m'
WHITE=$'\033[01;37m'
RED=$'\033[01;31m'
RESET=$'\033[00m'
```

## Compatibility

- ✅ Linux (Ubuntu, Debian, Arch, etc.)
- ✅ macOS (Intel and Apple Silicon)
- ✅ Windows (WSL)

## Official Documentation

- **Claude Code Statusline Guide**: https://docs.anthropic.com/en/docs/claude-code/statusline
- **Claude Code Documentation**: https://docs.anthropic.com/en/docs/claude-code
- **Claude Code GitHub**: https://github.com/anthropics/claude-code

## Troubleshooting

**Statusline doesn't appear?**
- Ensure script is executable: `chmod +x ~/.claude/statusline.sh`
- Check jq is installed: `jq --version`
- Restart Claude Code

**Colors not showing?**
- Make sure your terminal supports ANSI colors
- Try running the script manually to test

**Escape codes showing as text?**
- Use `$'\033[...'` syntax (not `\033[...` strings)
- See the scripts in this repo for correct usage

## License

MIT
