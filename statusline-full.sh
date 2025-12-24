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

# Total tokens
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
