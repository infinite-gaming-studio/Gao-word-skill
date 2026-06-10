#!/bin/bash
set -euo pipefail

# ============================================================
# Gao-word-skill Update Script
# ============================================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/infinite-gaming-studio/Gao-word-skill/main/scripts/update.sh | bash
#
# Or download and run locally:
#   bash scripts/update.sh
# ============================================================

SKILL_NAME="Gao-word-skill"
SKILL_REPO="infinite-gaming-studio/Gao-word-skill"
WORKDIR="/tmp/gao-word-skill-update-$(date +%s)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo ""
echo -e "${GREEN}=== Gao-word-skill Update ===${NC}"
echo ""

# Step 1: create working directory
mkdir -p "$WORKDIR"

# Step 2: backup current installation
SKILL_PATH=""
for dir in "$HOME/.opencode/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.cursor/skills"; do
    if [ -d "$dir/$SKILL_NAME" ]; then
        SKILL_PATH="$dir/$SKILL_NAME"
        break
    fi
done

if [ -n "$SKILL_PATH" ]; then
    echo -e "${YELLOW}Backing up current installation...${NC}"
    cp -r "$SKILL_PATH" "$WORKDIR/backup"
    echo "  Backup saved to: $WORKDIR/backup"
else
    echo -e "${YELLOW}No existing installation found. Will install fresh.${NC}"
fi

# Step 3: clone latest version
echo -e "${YELLOW}Fetching latest version from GitHub...${NC}"
if ! git clone --depth 1 "https://github.com/$SKILL_REPO.git" "$WORKDIR/repo" 2>/dev/null; then
    echo -e "${RED}Failed to clone repository. Check your internet connection.${NC}"
    exit 1
fi
echo "  Cloned to: $WORKDIR/repo"

# Step 4: verify SKILL.md exists
if [ ! -f "$WORKDIR/repo/SKILL.md" ]; then
    echo -e "${RED}Invalid repository: SKILL.md not found.${NC}"
    exit 1
fi

# Step 5: remove old installation
echo -e "${YELLOW}Removing old installation...${NC}"
npx skills remove "$SKILL_NAME" -g -y 2>/dev/null || true
echo "  Done."

# Step 6: install latest version from local path
echo -e "${YELLOW}Installing latest version...${NC}"
if ! npx skills add "$WORKDIR/repo" -g; then
    echo -e "${RED}Installation from local path failed. Trying GitHub source...${NC}"
    if ! npx skills add "$SKILL_REPO" -g; then
        echo -e "${RED}Installation failed.${NC}"
        if [ -n "$SKILL_PATH" ]; then
            echo -e "${YELLOW}Restoring from backup...${NC}"
            cp -r "$WORKDIR/backup" "$SKILL_PATH" 2>/dev/null || true
            echo "  Backup restored to: $SKILL_PATH"
        fi
        exit 1
    fi
fi

# Step 7: verify installation
INSTALLED=""
for dir in "$HOME/.opencode/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.cursor/skills"; do
    if [ -d "$dir/$SKILL_NAME" ]; then
        INSTALLED="$dir/$SKILL_NAME"
        break
    fi
done

if [ -n "$INSTALLED" ]; then
    VERSION=$(cd "$WORKDIR/repo" && git log --oneline -1 2>/dev/null || echo "latest")
    echo ""
    echo -e "${GREEN}=== Update complete! ===${NC}"
    echo "  Version: $VERSION"
    echo "  Installed at: $INSTALLED"
    echo ""
    echo -e "${YELLOW}Please restart your AI assistant to load the updated skill.${NC}"
else
    echo -e "${RED}Installation completed but skill not found in expected locations.${NC}"
    echo "Try manual install: npx skills add $SKILL_REPO -g"
    exit 1
fi
