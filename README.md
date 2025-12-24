# Claude Code Statusline

A custom statusline for [Claude Code](https://claude.ai/code) that displays useful information at the bottom of your terminal.

## Features

- **User@Host** - Your username and hostname (green)
- **Directory** - Current working directory (blue)
- **Git Branch** - Current git branch when in a repository (yellow)
- **Model** - Active Claude model: Opus, Sonnet, or Haiku (cyan)
- **Context Usage** - Percentage of context window used (magenta)

## Preview

```
diegocc@macbook:/home/user/project (main) [Opus] [12%]
```

## Installation

### 1. Install jq (required)

```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# Arch Linux
sudo pacman -S jq
```

### 2. Download and install the script

```bash
mkdir -p ~/.claude
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main/statusline.sh
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

If you already have a `settings.json`, just add the `statusLine` key to your existing configuration.

## Manual Installation

If you prefer, copy the script manually:

```bash
mkdir -p ~/.claude
cat > ~/.claude/statusline.sh << 'EOF'
#!/bin/bash

# Claude Code Statusline Script
# Shows: user@host:dir (git-branch) [Model] [context%]

input=$(cat)

GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
YELLOW=$'\033[01;33m'
CYAN=$'\033[01;36m'
MAGENTA=$'\033[01;35m'
RESET=$'\033[00m'

user=$(whoami)
host=$(hostname -s)
dir=$(pwd)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
case "$model" in
  *"Opus"*) model_short="Opus" ;;
  *"Sonnet"*) model_short="Sonnet" ;;
  *"Haiku"*) model_short="Haiku" ;;
  *) model_short=$(echo "$model" | awk '{print $1}') ;;
esac

git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_part=" ${YELLOW}(${git_branch})${RESET}"
  fi
fi

context_part=""
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
  current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  if [ "$current" != "null" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ]; then
    pct=$((current * 100 / size))
    context_part=" ${MAGENTA}[${pct}%]${RESET}"
  fi
fi

echo "${GREEN}${user}@${host}${RESET}:${BLUE}${dir}${RESET}${git_part} ${CYAN}[${model_short}]${RESET}${context_part}"
EOF

chmod +x ~/.claude/statusline.sh
```

## Customization

Edit `~/.claude/statusline.sh` to customize:

- **Colors** - Change ANSI codes at the top of the script
- **Format** - Modify the final `echo` statement
- **Content** - Add/remove sections as needed

### Available JSON Data

The script receives JSON via stdin with:

```json
{
  "model": { "display_name": "Opus" },
  "workspace": { "current_dir": "/path" },
  "context_window": {
    "context_window_size": 200000,
    "current_usage": {
      "input_tokens": 5000,
      "cache_creation_input_tokens": 1000,
      "cache_read_input_tokens": 500
    }
  },
  "cost": { "total_cost_usd": 0.05 }
}
```

## Compatibility

- Linux (Ubuntu, Debian, Arch, etc.)
- macOS (Intel and Apple Silicon)
- Windows (WSL)

## License

MIT
