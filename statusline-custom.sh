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
