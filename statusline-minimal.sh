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
