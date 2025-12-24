#!/bin/bash

# Claude Code Statusline Installer
# Interactive installer with version selection

set -e

# Colors
GREEN=$'\033[01;32m'
BLUE=$'\033[01;34m'
YELLOW=$'\033[01;33m'
CYAN=$'\033[01;36m'
MAGENTA=$'\033[01;35m'
WHITE=$'\033[01;37m'
RED=$'\033[01;31m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[00m'

REPO_URL="https://raw.githubusercontent.com/diegocconsolini/claude-statusline/main"

echo ""
echo "${BOLD}╔════════════════════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}║              Claude Code Statusline Installer                      ║${RESET}"
echo "${BOLD}╚════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "${RED}Error: jq is required but not installed.${RESET}"
    echo ""
    echo "Install it with:"
    echo "  ${CYAN}brew install jq${RESET}        # macOS"
    echo "  ${CYAN}sudo apt install jq${RESET}   # Ubuntu/Debian"
    echo "  ${CYAN}sudo pacman -S jq${RESET}     # Arch Linux"
    echo ""
    exit 1
fi

echo "${BOLD}Choose a statusline version:${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${BOLD}[1] Minimal${RESET}"
echo "      ${GREEN}user@host${RESET}:${BLUE}/current/directory${RESET}"
echo "      ${DIM}Just the basics${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${BOLD}[2] Standard${RESET}"
echo "      ${GREEN}user@host${RESET}:${BLUE}/directory${RESET} ${YELLOW}(main)${RESET} ${CYAN}[Opus]${RESET} ${MAGENTA}[12%]${RESET}"
echo "      ${DIM}+ git branch, model, context %${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${BOLD}[3] Full${RESET}"
echo "      ${GREEN}user@host${RESET}:${BLUE}/dir${RESET} ${YELLOW}(main)${RESET} ${CYAN}[Opus]${RESET} ${MAGENTA}[12%]${RESET} ${WHITE}5m23s${RESET} ${GREEN}+120${RESET}/${RED}-15${RESET} ${CYAN}↓45k${RESET}/${CYAN}↑12k${RESET}"
echo "      ${DIM}+ duration, lines changed, tokens${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${BOLD}[4] Custom${RESET} ${YELLOW}(Recommended)${RESET}"
echo "      Toggle each feature ON/OFF in the config section:"
echo ""
echo "      ${DIM}SHOW_USER_HOST=true${RESET}      ${GREEN}user@host${RESET}"
echo "      ${DIM}SHOW_DIRECTORY=true${RESET}      ${BLUE}/directory${RESET}"
echo "      ${DIM}SHOW_GIT_BRANCH=true${RESET}     ${YELLOW}(main)${RESET}"
echo "      ${DIM}SHOW_MODEL=true${RESET}          ${CYAN}[Opus]${RESET}"
echo "      ${DIM}SHOW_CONTEXT_PCT=true${RESET}    ${MAGENTA}[12%]${RESET}"
echo "      ${DIM}SHOW_DURATION=true${RESET}       ${WHITE}5m23s${RESET}"
echo "      ${DIM}SHOW_LINES_CHANGED=true${RESET}  ${GREEN}+120${RESET}/${RED}-15${RESET}"
echo "      ${DIM}SHOW_TOKENS=true${RESET}         ${CYAN}↓45k${RESET}/${CYAN}↑12k${RESET}"
echo "      ${DIM}SHOW_COST=false${RESET}          ${YELLOW}\$0.45${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Enter your choice [1-4]: " choice

case $choice in
    1) VERSION="minimal" ;;
    2) VERSION="standard" ;;
    3) VERSION="full" ;;
    4) VERSION="custom" ;;
    *)
        echo "${RED}Invalid choice. Exiting.${RESET}"
        exit 1
        ;;
esac

echo ""
echo "${CYAN}Installing ${VERSION} version...${RESET}"

# Create directory
mkdir -p ~/.claude

# Download the script
curl -fsSL "${REPO_URL}/statusline-${VERSION}.sh" -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Update settings.json
SETTINGS_FILE=~/.claude/settings.json

if [ -f "$SETTINGS_FILE" ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"

    # Check if statusLine already exists
    if grep -q '"statusLine"' "$SETTINGS_FILE" 2>/dev/null; then
        echo "${YELLOW}Note: statusLine already configured in settings.json${RESET}"
        echo "Backup saved to ${SETTINGS_FILE}.backup"
    else
        # Add statusLine to existing settings using jq if available
        if command -v jq &> /dev/null; then
            jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
            mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        else
            # Fallback: simple sed approach
            sed -i.tmp '$ d' "$SETTINGS_FILE"
            echo '  ,"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}' >> "$SETTINGS_FILE"
            echo '}' >> "$SETTINGS_FILE"
            rm -f "${SETTINGS_FILE}.tmp"
        fi
    fi
else
    # Create new settings file
    echo '{"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' > "$SETTINGS_FILE"
fi

echo ""
echo "${GREEN}✓ Installation complete!${RESET}"
echo ""
echo "  Installed: ~/.claude/statusline.sh (${VERSION})"
echo "  Settings:  ~/.claude/settings.json"
echo ""

if [ "$VERSION" = "custom" ]; then
    echo "${BOLD}To customize features:${RESET}"
    echo "  ${CYAN}nano ~/.claude/statusline.sh${RESET}"
    echo ""
    echo "  Then change any feature to true/false:"
    echo "    SHOW_GIT_BRANCH=false"
    echo "    SHOW_COST=true"
    echo ""
fi

echo "${BOLD}Restart Claude Code to see your new statusline.${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: ${CYAN}https://docs.anthropic.com/en/docs/claude-code${RESET}"
echo "Repository:    ${CYAN}https://github.com/diegocconsolini/claude-statusline${RESET}"
echo ""
