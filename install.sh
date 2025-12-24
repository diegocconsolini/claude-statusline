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

REPO_URL="https://raw.githubusercontent.com/diegocconsolini/claude-statusline/master"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Create directory
mkdir -p ~/.claude

# Custom version: interactive checkbox selection
if [ "$VERSION" = "custom" ]; then
    # Feature definitions: name|label|example|default
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

    # Initialize states from defaults
    declare -a STATES
    for i in "${!FEATURES[@]}"; do
        IFS='|' read -r _ _ _ default <<< "${FEATURES[$i]}"
        STATES[$i]=$default
    done

    current=0
    total=${#FEATURES[@]}

    # Hide cursor
    tput civis 2>/dev/null || true

    # Cleanup on exit
    cleanup() {
        tput cnorm 2>/dev/null || true
        stty echo 2>/dev/null || true
    }
    trap cleanup EXIT

    draw_menu() {
        # Move cursor up to redraw (after first draw)
        if [ "$1" = "redraw" ]; then
            tput cuu $((total + 4)) 2>/dev/null || printf "\033[%dA" $((total + 4))
        fi

        echo ""
        echo "${BOLD}Configure your statusline:${RESET}"
        echo "${DIM}↑/↓ navigate • Space toggle • Enter confirm${RESET}"
        echo ""

        for i in "${!FEATURES[@]}"; do
            IFS='|' read -r name label example _ <<< "${FEATURES[$i]}"

            if [ "${STATES[$i]}" = "1" ]; then
                checkbox="${GREEN}[✓]${RESET}"
            else
                checkbox="${DIM}[ ]${RESET}"
            fi

            if [ "$i" = "$current" ]; then
                pointer="${CYAN}▸${RESET}"
                line="${BOLD}${label}${RESET} ${DIM}${example}${RESET}"
            else
                pointer=" "
                line="${label} ${DIM}${example}${RESET}"
            fi

            printf " %s %s %s\n" "$pointer" "$checkbox" "$line"
        done
    }

    # Initial draw
    draw_menu

    # Read input
    while true; do
        # Read single keypress
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')  # Escape sequence
                read -rsn2 key2
                case "$key2" in
                    '[A')  # Up arrow
                        ((current > 0)) && ((current--))
                        ;;
                    '[B')  # Down arrow
                        ((current < total - 1)) && ((current++))
                        ;;
                esac
                ;;
            ' ')  # Space - toggle
                if [ "${STATES[$current]}" = "1" ]; then
                    STATES[$current]=0
                else
                    STATES[$current]=1
                fi
                ;;
            ''|$'\n')  # Enter - confirm
                break
                ;;
            'k'|'K')  # Vim up
                ((current > 0)) && ((current--))
                ;;
            'j'|'J')  # Vim down
                ((current < total - 1)) && ((current++))
                ;;
        esac

        draw_menu "redraw"
    done

    # Show cursor again
    tput cnorm 2>/dev/null || true

    # Extract final values
    for i in "${!FEATURES[@]}"; do
        IFS='|' read -r name _ _ _ <<< "${FEATURES[$i]}"
        if [ "${STATES[$i]}" = "1" ]; then
            eval "${name}=true"
        else
            eval "${name}=false"
        fi
    done

    echo ""
    echo "${CYAN}Installing custom version...${RESET}"

    # Install the script (local first, then GitHub fallback)
    LOCAL_FILE="${SCRIPT_DIR}/statusline-${VERSION}.sh"
    if [ -f "$LOCAL_FILE" ]; then
        cp "$LOCAL_FILE" ~/.claude/statusline.sh
        echo "${DIM}(installed from local file)${RESET}"
    else
        curl -fsSL "${REPO_URL}/statusline-${VERSION}.sh" -o ~/.claude/statusline.sh
        echo "${DIM}(downloaded from GitHub)${RESET}"
    fi

    # Apply user's feature selections
    sed -i.tmp "s/^SHOW_USER_HOST=.*/SHOW_USER_HOST=${SHOW_USER_HOST}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_DIRECTORY=.*/SHOW_DIRECTORY=${SHOW_DIRECTORY}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_GIT_BRANCH=.*/SHOW_GIT_BRANCH=${SHOW_GIT_BRANCH}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_MODEL=.*/SHOW_MODEL=${SHOW_MODEL}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_CONTEXT_PCT=.*/SHOW_CONTEXT_PCT=${SHOW_CONTEXT_PCT}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_DURATION=.*/SHOW_DURATION=${SHOW_DURATION}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_LINES_CHANGED=.*/SHOW_LINES_CHANGED=${SHOW_LINES_CHANGED}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_TOKENS=.*/SHOW_TOKENS=${SHOW_TOKENS}/" ~/.claude/statusline.sh
    sed -i.tmp "s/^SHOW_COST=.*/SHOW_COST=${SHOW_COST}/" ~/.claude/statusline.sh
    rm -f ~/.claude/statusline.sh.tmp
else
    echo ""
    echo "${CYAN}Installing ${VERSION} version...${RESET}"

    # Install the script (local first, then GitHub fallback)
    LOCAL_FILE="${SCRIPT_DIR}/statusline-${VERSION}.sh"
    if [ -f "$LOCAL_FILE" ]; then
        cp "$LOCAL_FILE" ~/.claude/statusline.sh
        echo "${DIM}(installed from local file)${RESET}"
    else
        curl -fsSL "${REPO_URL}/statusline-${VERSION}.sh" -o ~/.claude/statusline.sh
        echo "${DIM}(downloaded from GitHub)${RESET}"
    fi
fi
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
    echo "${BOLD}Your configuration:${RESET}"
    echo "  SHOW_USER_HOST=${SHOW_USER_HOST}"
    echo "  SHOW_DIRECTORY=${SHOW_DIRECTORY}"
    echo "  SHOW_GIT_BRANCH=${SHOW_GIT_BRANCH}"
    echo "  SHOW_MODEL=${SHOW_MODEL}"
    echo "  SHOW_CONTEXT_PCT=${SHOW_CONTEXT_PCT}"
    echo "  SHOW_DURATION=${SHOW_DURATION}"
    echo "  SHOW_LINES_CHANGED=${SHOW_LINES_CHANGED}"
    echo "  SHOW_TOKENS=${SHOW_TOKENS}"
    echo "  SHOW_COST=${SHOW_COST}"
    echo ""
    echo "${DIM}To change later: nano ~/.claude/statusline.sh${RESET}"
    echo ""
fi

echo "${BOLD}Restart Claude Code to see your new statusline.${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Documentation: ${CYAN}https://docs.anthropic.com/en/docs/claude-code${RESET}"
echo "Repository:    ${CYAN}https://github.com/diegocconsolini/claude-statusline${RESET}"
echo ""
