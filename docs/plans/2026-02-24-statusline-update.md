# Claude Statusline Update — Feb 2026 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update all statusline scripts, installer, and README to reflect the current official Claude Code statusline JSON schema and best practices as documented at https://code.claude.com/docs/en/statusline (verified Feb 2026).

**Architecture:** Each shell script reads a JSON payload from stdin piped by Claude Code. Scripts are updated to use the pre-calculated `used_percentage` field instead of manual arithmetic, read `workspace.current_dir` from JSON instead of calling `pwd`, use `git branch --show-current` instead of `git symbolic-ref`, and expose new optional fields in the custom variant. The README and installer are updated to match.

**Tech Stack:** Bash, jq, git. No new dependencies introduced.

---

## Reference: Official JSON Schema (source of truth)

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
  "output_style": {
    "name": "default"
  },
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
  "vim": {
    "mode": "NORMAL"
  },
  "agent": {
    "name": "security-reviewer"
  }
}
```

**Fields that may be absent (not in JSON):**
- `vim` — only present when vim mode is enabled
- `agent` — only present when running with `--agent` flag

**Fields that may be null:**
- `context_window.current_usage` — null before first API call
- `context_window.used_percentage` / `remaining_percentage` — may be null early in session

---

## Task 1: Fix `statusline-minimal.sh`

**Files:**
- Modify: `statusline-minimal.sh`

**What changes:** Replace `$(pwd)` with `workspace.current_dir` from JSON. This is the only field used.

**Step 1: Make the edit**

Replace entire file content with:

```bash
#!/bin/bash

# Claude Code Statusline - MINIMAL
# Shows: user@host:dir

input=$(cat)

GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
RESET=$'\033[00m'

user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

echo "${GREEN}${user}@${host}${RESET}:${BLUE}${dir}${RESET}"
```

**Step 2: Verify manually**

```bash
echo '{"workspace":{"current_dir":"/home/user/myproject"}}' | bash statusline-minimal.sh
```

Expected: colored output showing `user@host:/home/user/myproject`

**Step 3: Commit**

```bash
git add statusline-minimal.sh
git commit -m "fix: read dir from workspace.current_dir JSON field (minimal)"
```

---

## Task 2: Fix `statusline-standard.sh`

**Files:**
- Modify: `statusline-standard.sh`

**What changes:**
1. Replace `$(pwd)` with `.workspace.current_dir` from JSON
2. Replace manual context % arithmetic with `.context_window.used_percentage // 0`
3. Replace `git symbolic-ref --short HEAD || git rev-parse --short HEAD` with `git branch --show-current`

**Step 1: Make the edit**

Replace entire file content with:

```bash
#!/bin/bash

# Claude Code Statusline - STANDARD
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
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

# Model name
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
case "$model" in
  *"Opus"*)   model_short="Opus" ;;
  *"Sonnet"*) model_short="Sonnet" ;;
  *"Haiku"*)  model_short="Haiku" ;;
  *)          model_short=$(echo "$model" | awk '{print $1}') ;;
esac

# Git branch
git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_part=" ${YELLOW}(${git_branch})${RESET}"
  fi
fi

# Context usage % (pre-calculated by Claude Code)
context_part=""
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if [ -n "$pct" ] && [ "$pct" != "0" ]; then
  context_part=" ${MAGENTA}[${pct}%]${RESET}"
fi

echo "${GREEN}${user}@${host}${RESET}:${BLUE}${dir}${RESET}${git_part} ${CYAN}[${model_short}]${RESET}${context_part}"
```

**Step 2: Verify manually**

```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/user/proj"},"context_window":{"used_percentage":42}}' | bash statusline-standard.sh
```

Expected: `user@host:/home/user/proj [Opus] [42%]` (with colors, no git branch since not in a repo during test)

**Step 3: Commit**

```bash
git add statusline-standard.sh
git commit -m "fix: use workspace.current_dir, used_percentage, git branch --show-current (standard)"
```

---

## Task 3: Fix `statusline-full.sh`

**Files:**
- Modify: `statusline-full.sh`

**What changes:**
1. Replace `$(pwd)` with `.workspace.current_dir`
2. Replace manual context % with `.context_window.used_percentage // 0`
3. Replace git branch command

**Step 1: Make the edit**

Replace entire file content with:

```bash
#!/bin/bash

# Claude Code Statusline - FULL
# Shows: user@host:dir (git-branch) [Model] [context%] duration +lines/-lines ↓in/↑out

input=$(cat)

GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
YELLOW=$'\033[01;33m'
CYAN=$'\033[01;36m'
MAGENTA=$'\033[01;35m'
WHITE=$'\033[01;37m'
RED=$'\033[01;31m'
RESET=$'\033[00m'

user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

# Model name
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
case "$model" in
  *"Opus"*)   model_short="Opus" ;;
  *"Sonnet"*) model_short="Sonnet" ;;
  *"Haiku"*)  model_short="Haiku" ;;
  *)          model_short=$(echo "$model" | awk '{print $1}') ;;
esac

# Git branch
git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_part=" ${YELLOW}(${git_branch})${RESET}"
  fi
fi

# Context usage % (pre-calculated by Claude Code)
context_part=""
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if [ -n "$pct" ] && [ "$pct" != "0" ]; then
  context_part=" ${MAGENTA}[${pct}%]${RESET}"
fi

# Session duration
duration_part=""
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
if [ "$duration_ms" != "0" ] && [ "$duration_ms" != "null" ]; then
  duration_sec=$((duration_ms / 1000))
  if [ "$duration_sec" -ge 3600 ]; then
    hours=$((duration_sec / 3600))
    mins=$(((duration_sec % 3600) / 60))
    duration_part=" ${WHITE}${hours}h${mins}m${RESET}"
  elif [ "$duration_sec" -ge 60 ]; then
    mins=$((duration_sec / 60))
    secs=$((duration_sec % 60))
    duration_part=" ${WHITE}${mins}m${secs}s${RESET}"
  else
    duration_part=" ${WHITE}${duration_sec}s${RESET}"
  fi
fi

# Lines added/removed
lines_part=""
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
  lines_part=" ${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
fi

# Total tokens (cumulative)
tokens_part=""
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
if [ "$input_tokens" != "0" ] || [ "$output_tokens" != "0" ]; then
  if [ "$input_tokens" -ge 1000 ]; then
    input_fmt="$((input_tokens / 1000))k"
  else
    input_fmt="$input_tokens"
  fi
  if [ "$output_tokens" -ge 1000 ]; then
    output_fmt="$((output_tokens / 1000))k"
  else
    output_fmt="$output_tokens"
  fi
  tokens_part=" ${CYAN}↓${input_fmt}${RESET}/${CYAN}↑${output_fmt}${RESET}"
fi

echo "${GREEN}${user}@${host}${RESET}:${BLUE}${dir}${RESET}${git_part} ${CYAN}[${model_short}]${RESET}${context_part}${duration_part}${lines_part}${tokens_part}"
```

**Step 2: Verify manually**

```bash
echo '{"model":{"display_name":"Sonnet"},"workspace":{"current_dir":"/tmp/test"},"context_window":{"used_percentage":15,"total_input_tokens":15000,"total_output_tokens":4000},"cost":{"total_duration_ms":125000,"total_lines_added":42,"total_lines_removed":7}}' | bash statusline-full.sh
```

Expected: full status line with model, context %, duration (2m5s), lines (+42/-7), tokens (15k/4k)

**Step 3: Commit**

```bash
git add statusline-full.sh
git commit -m "fix: use workspace.current_dir, used_percentage, git branch --show-current (full)"
```

---

## Task 4: Fix `statusline.sh` (default)

**Files:**
- Modify: `statusline.sh`

**What changes:** Same three fixes as standard. This is the default script that gets overwritten by the installer, so it should match `statusline-standard.sh` in correctness.

**Step 1: Make the edit**

Replace entire file content with:

```bash
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
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

# Model name
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
case "$model" in
  *"Opus"*)   model_short="Opus" ;;
  *"Sonnet"*) model_short="Sonnet" ;;
  *"Haiku"*)  model_short="Haiku" ;;
  *)          model_short=$(echo "$model" | awk '{print $1}') ;;
esac

# Git branch
git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_part=" ${YELLOW}(${git_branch})${RESET}"
  fi
fi

# Context usage % (pre-calculated by Claude Code)
context_part=""
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
if [ -n "$pct" ] && [ "$pct" != "0" ]; then
  context_part=" ${MAGENTA}[${pct}%]${RESET}"
fi

echo "${GREEN}${user}@${host}${RESET}:${BLUE}${dir}${RESET}${git_part} ${CYAN}[${model_short}]${RESET}${context_part}"
```

**Step 2: Verify**

```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/home/user/proj"},"context_window":{"used_percentage":8}}' | bash statusline.sh
```

**Step 3: Commit**

```bash
git add statusline.sh
git commit -m "fix: use workspace.current_dir, used_percentage, git branch --show-current (default)"
```

---

## Task 5: Update `statusline-custom.sh`

**Files:**
- Modify: `statusline-custom.sh`

**What changes:**
1. Apply the same three core fixes (workspace.current_dir, used_percentage, git branch --show-current)
2. Add five new toggleable options: `SHOW_VIM_MODE`, `SHOW_AGENT_NAME`, `SHOW_REMAINING_PCT`, `SHOW_API_DURATION`, `SHOW_VERSION`
3. Each new option defaults to `false` and gracefully handles absent/null fields

**Step 1: Make the edit**

Replace entire file content with:

```bash
#!/bin/bash

# Claude Code Statusline - CUSTOM
# Toggle features ON/OFF below (true/false)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFIGURATION - Set to true or false
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHOW_USER_HOST=true       # user@host
SHOW_DIRECTORY=true       # /current/directory
SHOW_GIT_BRANCH=true      # (main)
SHOW_MODEL=true           # [Opus]
SHOW_CONTEXT_PCT=true     # [12%]
SHOW_REMAINING_PCT=false  # [88% left]
SHOW_DURATION=true        # 5m23s
SHOW_LINES_CHANGED=true   # +120/-15
SHOW_TOKENS=true          # ↓45k/↑12k
SHOW_COST=false           # $0.45
SHOW_API_DURATION=false   # api:2s
SHOW_VIM_MODE=false       # VIM:NORMAL (only shows when vim mode is active)
SHOW_AGENT_NAME=false     # agent:name (only shows when --agent flag is used)
SHOW_VERSION=false        # v1.0.80

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SCRIPT - Don't edit below unless customizing colors
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

input=$(cat)

# Colors
GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
YELLOW=$'\033[01;33m'
CYAN=$'\033[01;36m'
MAGENTA=$'\033[01;35m'
WHITE=$'\033[01;37m'
RED=$'\033[01;31m'
DIM=$'\033[02m'
RESET=$'\033[00m'

output=""

# User@Host
if [ "$SHOW_USER_HOST" = true ]; then
  user=$(whoami)
  host=$(hostname -s)
  output="${GREEN}${user}@${host}${RESET}"
fi

# Directory (from JSON, not pwd)
if [ "$SHOW_DIRECTORY" = true ]; then
  dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
  if [ -n "$output" ]; then
    output="${output}:${BLUE}${dir}${RESET}"
  else
    output="${BLUE}${dir}${RESET}"
  fi
fi

# Git branch
if [ "$SHOW_GIT_BRANCH" = true ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$git_branch" ]; then
      output="${output} ${YELLOW}(${git_branch})${RESET}"
    fi
  fi
fi

# Model name
if [ "$SHOW_MODEL" = true ]; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  case "$model" in
    *"Opus"*)   model_short="Opus" ;;
    *"Sonnet"*) model_short="Sonnet" ;;
    *"Haiku"*)  model_short="Haiku" ;;
    *)          model_short=$(echo "$model" | awk '{print $1}') ;;
  esac
  output="${output} ${CYAN}[${model_short}]${RESET}"
fi

# Context used % (pre-calculated by Claude Code)
if [ "$SHOW_CONTEXT_PCT" = true ]; then
  pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
  if [ -n "$pct" ] && [ "$pct" != "0" ]; then
    output="${output} ${MAGENTA}[${pct}%]${RESET}"
  fi
fi

# Context remaining % (pre-calculated by Claude Code)
if [ "$SHOW_REMAINING_PCT" = true ]; then
  rem=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0' | cut -d. -f1)
  if [ -n "$rem" ]; then
    output="${output} ${MAGENTA}[${rem}% left]${RESET}"
  fi
fi

# Session duration
if [ "$SHOW_DURATION" = true ]; then
  duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
  if [ "$duration_ms" != "0" ] && [ "$duration_ms" != "null" ]; then
    duration_sec=$((duration_ms / 1000))
    if [ "$duration_sec" -ge 3600 ]; then
      hours=$((duration_sec / 3600))
      mins=$(((duration_sec % 3600) / 60))
      output="${output} ${WHITE}${hours}h${mins}m${RESET}"
    elif [ "$duration_sec" -ge 60 ]; then
      mins=$((duration_sec / 60))
      secs=$((duration_sec % 60))
      output="${output} ${WHITE}${mins}m${secs}s${RESET}"
    else
      output="${output} ${WHITE}${duration_sec}s${RESET}"
    fi
  fi
fi

# Lines changed
if [ "$SHOW_LINES_CHANGED" = true ]; then
  lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
  lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
  if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
    output="${output} ${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
  fi
fi

# Tokens (cumulative)
if [ "$SHOW_TOKENS" = true ]; then
  input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
  if [ "$input_tokens" != "0" ] || [ "$output_tokens" != "0" ]; then
    if [ "$input_tokens" -ge 1000 ]; then
      input_fmt="$((input_tokens / 1000))k"
    else
      input_fmt="$input_tokens"
    fi
    if [ "$output_tokens" -ge 1000 ]; then
      output_fmt="$((output_tokens / 1000))k"
    else
      output_fmt="$output_tokens"
    fi
    output="${output} ${CYAN}↓${input_fmt}${RESET}/${CYAN}↑${output_fmt}${RESET}"
  fi
fi

# Cost
if [ "$SHOW_COST" = true ]; then
  cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
  if [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
    output="${output} ${YELLOW}\$${cost}${RESET}"
  fi
fi

# API wait duration
if [ "$SHOW_API_DURATION" = true ]; then
  api_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
  if [ "$api_ms" != "0" ] && [ "$api_ms" != "null" ]; then
    api_sec=$((api_ms / 1000))
    output="${output} ${DIM}api:${api_sec}s${RESET}"
  fi
fi

# Vim mode (only shows when vim mode is active in Claude Code)
if [ "$SHOW_VIM_MODE" = true ]; then
  vim_mode=$(echo "$input" | jq -r '.vim.mode // ""')
  if [ -n "$vim_mode" ]; then
    output="${output} ${CYAN}VIM:${vim_mode}${RESET}"
  fi
fi

# Agent name (only shows when --agent flag is used)
if [ "$SHOW_AGENT_NAME" = true ]; then
  agent_name=$(echo "$input" | jq -r '.agent.name // ""')
  if [ -n "$agent_name" ]; then
    output="${output} ${YELLOW}agent:${agent_name}${RESET}"
  fi
fi

# Claude Code version
if [ "$SHOW_VERSION" = true ]; then
  cc_version=$(echo "$input" | jq -r '.version // ""')
  if [ -n "$cc_version" ]; then
    output="${output} ${DIM}v${cc_version}${RESET}"
  fi
fi

echo "$output"
```

**Step 2: Verify new fields work**

```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":30,"remaining_percentage":70,"total_input_tokens":5000,"total_output_tokens":1000},"cost":{"total_duration_ms":60000,"total_api_duration_ms":3000,"total_lines_added":10,"total_lines_removed":2,"total_cost_usd":0.012},"vim":{"mode":"NORMAL"},"agent":{"name":"test-agent"},"version":"1.0.80"}' | bash statusline-custom.sh
```

Expected: renders all `true` fields, skips the `false` ones (`SHOW_REMAINING_PCT`, `SHOW_COST`, `SHOW_API_DURATION`, `SHOW_VIM_MODE`, `SHOW_AGENT_NAME`, `SHOW_VERSION` all off by default).

**Step 3: Test absent fields don't break output**

```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":5}}' | bash statusline-custom.sh
```

Expected: renders user@host, dir, model, context % — no errors from missing vim/agent/cost fields.

**Step 4: Commit**

```bash
git add statusline-custom.sh
git commit -m "feat: add vim mode, agent name, remaining %, api duration, version toggles; fix core field usage (custom)"
```

---

## Task 6: Update `install.sh`

**Files:**
- Modify: `install.sh`

**What changes:**
1. Add five new feature entries to the `FEATURES` array in the custom interactive menu
2. Add `sed` lines to apply the five new toggles to the installed script
3. Add `"padding": 2` to the `settings.json` block written by the installer

**Step 1: Add new features to FEATURES array**

Find this block in `install.sh` (around line 98):
```bash
    FEATURES=(
        "SHOW_USER_HOST|User@Host|user@host|1"
        "SHOW_DIRECTORY|Directory|/path/to/dir|1"
        "SHOW_GIT_BRANCH|Git Branch|(main)|1"
        "SHOW_MODEL|Model|[Opus]|1"
        "SHOW_CONTEXT_PCT|Context %|[12%]|1"
        "SHOW_DURATION|Duration|5m23s|1"
        "SHOW_LINES_CHANGED|Lines Changed|+120/-15|1"
        "SHOW_TOKENS|Tokens|↓45k/↑12k|1"
        "SHOW_COST|Cost|\$0.45|0"
    )
```

Replace with:
```bash
    FEATURES=(
        "SHOW_USER_HOST|User@Host|user@host|1"
        "SHOW_DIRECTORY|Directory|/path/to/dir|1"
        "SHOW_GIT_BRANCH|Git Branch|(main)|1"
        "SHOW_MODEL|Model|[Opus]|1"
        "SHOW_CONTEXT_PCT|Context %|[12%]|1"
        "SHOW_REMAINING_PCT|Remaining %|[88% left]|0"
        "SHOW_DURATION|Duration|5m23s|1"
        "SHOW_LINES_CHANGED|Lines Changed|+120/-15|1"
        "SHOW_TOKENS|Tokens|↓45k/↑12k|1"
        "SHOW_COST|Cost|\$0.45|0"
        "SHOW_API_DURATION|API Wait Time|api:2s|0"
        "SHOW_VIM_MODE|Vim Mode|VIM:NORMAL|0"
        "SHOW_AGENT_NAME|Agent Name|agent:name|0"
        "SHOW_VERSION|CC Version|v1.0.80|0"
    )
```

**Step 2: Add sed lines for new toggles**

Find the existing sed block (around line 230):
```bash
    sed -i.tmp "s/^SHOW_COST=.*/SHOW_COST=${SHOW_COST}/" ~/.claude/statusline.sh
    rm -f ~/.claude/statusline.sh.tmp
```

Replace with:
```bash
    sed -i.tmp "s/^SHOW_COST=.*/SHOW_COST=${SHOW_COST}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_API_DURATION=.*/SHOW_API_DURATION=${SHOW_API_DURATION}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_VIM_MODE=.*/SHOW_VIM_MODE=${SHOW_VIM_MODE}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_AGENT_NAME=.*/SHOW_AGENT_NAME=${SHOW_AGENT_NAME}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_REMAINING_PCT=.*/SHOW_REMAINING_PCT=${SHOW_REMAINING_PCT}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_VERSION=.*/SHOW_VERSION=${SHOW_VERSION}/" ~/.claude/statusline.sh
    rm -f ~/.claude/statusline.sh.tmp
```

**Step 3: Add `padding` to settings.json**

Find (around line 270):
```bash
        jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
```

Replace with:
```bash
        jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 2}}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
```

Find (around line 282):
```bash
    echo '{"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' > "$SETTINGS_FILE"
```

Replace with:
```bash
    echo '{"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 2}}' > "$SETTINGS_FILE"
```

**Step 4: Update the custom config echo block at bottom of install.sh**

Find:
```bash
    echo "  SHOW_COST=${SHOW_COST}"
    echo ""
```

Replace with:
```bash
    echo "  SHOW_COST=${SHOW_COST}"
    echo "  SHOW_API_DURATION=${SHOW_API_DURATION}"
    echo "  SHOW_VIM_MODE=${SHOW_VIM_MODE}"
    echo "  SHOW_AGENT_NAME=${SHOW_AGENT_NAME}"
    echo "  SHOW_REMAINING_PCT=${SHOW_REMAINING_PCT}"
    echo "  SHOW_VERSION=${SHOW_VERSION}"
    echo ""
```

**Step 5: Commit**

```bash
git add install.sh
git commit -m "feat: add new toggles to installer; add padding to settings.json"
```

---

## Task 7: Update `README.md`

**Files:**
- Modify: `README.md`

**What changes:**
1. Update JSON Data Reference table with all missing fields
2. Add full JSON schema block
3. Update settings example to include `padding`
4. Update Available Features table with new toggles
5. Update test command with fuller mock payload
6. Add `disableAllHooks` troubleshooting note

**Step 1: Replace the JSON Data Reference table**

Find:
```markdown
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
```

Replace with:
```markdown
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
```

**Step 2: Update settings example (add padding)**

Find:
```markdown
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```
```

Replace with:
```markdown
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
```

**Step 3: Update Available Features table**

Find the table in the `### 4. Custom (Recommended)` section. After `SHOW_COST`, add:

```markdown
| API Wait Time | `SHOW_API_DURATION` | `api:2s` | Dim |
| Vim Mode | `SHOW_VIM_MODE` | `VIM:NORMAL` | Cyan |
| Agent Name | `SHOW_AGENT_NAME` | `agent:name` | Yellow |
| Remaining % | `SHOW_REMAINING_PCT` | `[88% left]` | Magenta |
| CC Version | `SHOW_VERSION` | `v1.0.80` | Dim |
```

**Step 4: Update test command**

Find:
```bash
echo '{"model":{"display_name":"Opus"}}' | ~/.claude/statusline.sh
```

Replace with:
```bash
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/tmp/test"},"context_window":{"used_percentage":25,"remaining_percentage":75}}' | ~/.claude/statusline.sh
```

**Step 5: Add disableAllHooks troubleshooting note**

Find:
```markdown
**Statusline not appearing?**
```bash
chmod +x ~/.claude/statusline.sh
jq --version  # Ensure jq is installed
```
```

Replace with:
```markdown
**Statusline not appearing?**
```bash
chmod +x ~/.claude/statusline.sh
jq --version  # Ensure jq is installed
```

If `disableAllHooks` is set to `true` in your `~/.claude/settings.json`, the status line is also disabled. Remove it or set it to `false`.
```

**Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update JSON data reference, schema, settings example, troubleshooting"
```

---

## Task 8: Open GitHub Issue

**After all code commits are done.**

**Step 1: Create the issue**

```bash
gh issue create \
  --title "Update scripts and docs to match current Claude Code statusline JSON schema (Feb 2026)" \
  --body "$(cat <<'EOF'
## Summary

This issue tracks a full update of the statusline scripts and documentation to align with the current official Claude Code statusline specification.

Source: https://code.claude.com/docs/en/statusline (verified Feb 2026)

## Changes Made

### Scripts (`statusline.sh`, `statusline-standard.sh`, `statusline-full.sh`, `statusline-minimal.sh`)

- **Fix:** Use `.workspace.current_dir` from JSON instead of calling `$(pwd)` — official docs prefer this
- **Fix:** Use `.context_window.used_percentage // 0` (pre-calculated) instead of manual arithmetic
- **Fix:** Use `git branch --show-current` instead of `git symbolic-ref --short HEAD || git rev-parse --short HEAD` (matches official doc examples)

### `statusline-custom.sh`

All above fixes plus five new optional toggles (all `false` by default):

| Toggle | Field | Shows |
|--------|-------|-------|
| `SHOW_REMAINING_PCT` | `.context_window.remaining_percentage` | `[88% left]` |
| `SHOW_API_DURATION` | `.cost.total_api_duration_ms` | `api:2s` |
| `SHOW_VIM_MODE` | `.vim.mode` | `VIM:NORMAL` (only when vim mode active) |
| `SHOW_AGENT_NAME` | `.agent.name` | `agent:name` (only when --agent flag used) |
| `SHOW_VERSION` | `.version` | `v1.0.80` |

### `install.sh`

- Added all five new toggles to the interactive checkbox menu
- Added `"padding": 2` to the generated `settings.json` (documented option, previously missing)

### `README.md`

- Updated JSON Data Reference table with all fields from the official schema
- Added full JSON schema block for reference
- Updated settings example with `padding` field
- Updated Available Features table with new toggles
- Updated test command with fuller mock payload
- Added `disableAllHooks` troubleshooting note

## Fields Previously Missing from Docs/Scripts

`.model.id`, `.workspace.project_dir`, `.context_window.remaining_percentage`, `.cost.total_api_duration_ms`, `.exceeds_200k_tokens`, `.vim.mode`, `.agent.name`, `.output_style.name`, `.version`

## Verified Against

- Official docs: https://code.claude.com/docs/en/statusline
- Model overview: https://docs.anthropic.com/en/docs/about-claude/models/overview
- Claude Code version: 2.1.52 (Feb 2026)
EOF
)"
```

---

## Final Verification Checklist

After all tasks complete, run these to verify nothing is broken:

```bash
# Test all four scripts with a realistic payload
PAYLOAD='{"model":{"display_name":"Opus","id":"claude-opus-4-6"},"workspace":{"current_dir":"/tmp/test","project_dir":"/tmp/test"},"context_window":{"used_percentage":42,"remaining_percentage":58,"total_input_tokens":84000,"total_output_tokens":12000,"context_window_size":200000,"current_usage":{"input_tokens":80000,"output_tokens":10000,"cache_creation_input_tokens":3000,"cache_read_input_tokens":1000}},"cost":{"total_cost_usd":0.15,"total_duration_ms":180000,"total_api_duration_ms":8000,"total_lines_added":250,"total_lines_removed":40},"exceeds_200k_tokens":false,"version":"1.0.80","output_style":{"name":"default"}}'

echo "$PAYLOAD" | bash statusline-minimal.sh
echo "$PAYLOAD" | bash statusline-standard.sh
echo "$PAYLOAD" | bash statusline-full.sh
echo "$PAYLOAD" | bash statusline-custom.sh

# Test null-safety: minimal payload, no optional fields
echo '{"model":{"display_name":"Sonnet"},"workspace":{"current_dir":"/home/user"}}' | bash statusline-custom.sh
```

All scripts must produce output without errors on both payloads.

```bash
git log --oneline -10
```

Expected: 6 commits (Tasks 1–4 scripts + Task 5 custom + Task 6 installer + Task 7 readme).
