#!/bin/bash

# Claude Code Statusline - CUSTOM
# Toggle features ON/OFF below (true/false)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFIGURATION - Set to true or false
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHOW_USER_HOST=true      # user@host
SHOW_DIRECTORY=true      # /current/directory
SHOW_GIT_BRANCH=true     # (main)
SHOW_MODEL=true          # [Opus]
SHOW_CONTEXT_PCT=true    # [12%]
SHOW_DURATION=true       # 5m23s
SHOW_LINES_CHANGED=true  # +120/-15
SHOW_TOKENS=true         # ↓45k/↑12k
SHOW_COST=false          # $0.45

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
RESET=$'\033[00m'

output=""

# User@Host
if [ "$SHOW_USER_HOST" = true ]; then
  user=$(whoami)
  host=$(hostname -s)
  output="${GREEN}${user}@${host}${RESET}"
fi

# Directory
if [ "$SHOW_DIRECTORY" = true ]; then
  dir=$(pwd)
  if [ -n "$output" ]; then
    output="${output}:${BLUE}${dir}${RESET}"
  else
    output="${BLUE}${dir}${RESET}"
  fi
fi

# Git branch
if [ "$SHOW_GIT_BRANCH" = true ]; then
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$git_branch" ]; then
      output="${output} ${YELLOW}(${git_branch})${RESET}"
    fi
  fi
fi

# Model name
if [ "$SHOW_MODEL" = true ]; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  case "$model" in
    *"Opus"*) model_short="Opus" ;;
    *"Sonnet"*) model_short="Sonnet" ;;
    *"Haiku"*) model_short="Haiku" ;;
    *) model_short=$(echo "$model" | awk '{print $1}') ;;
  esac
  output="${output} ${CYAN}[${model_short}]${RESET}"
fi

# Context usage %
if [ "$SHOW_CONTEXT_PCT" = true ]; then
  usage=$(echo "$input" | jq '.context_window.current_usage')
  if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    if [ "$current" != "null" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ]; then
      pct=$((current * 100 / size))
      output="${output} ${MAGENTA}[${pct}%]${RESET}"
    fi
  fi
fi

# Duration
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

# Tokens
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

echo "$output"
