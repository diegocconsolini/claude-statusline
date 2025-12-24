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
dir=$(pwd)

# Model name
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
case "$model" in
  *"Opus"*) model_short="Opus" ;;
  *"Sonnet"*) model_short="Sonnet" ;;
  *"Haiku"*) model_short="Haiku" ;;
  *) model_short=$(echo "$model" | awk '{print $1}') ;;
esac

# Git branch
git_part=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_part=" ${YELLOW}(${git_branch})${RESET}"
  fi
fi

# Context usage
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
