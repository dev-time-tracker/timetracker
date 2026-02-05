#!/bin/sh
# devtime.sh - Minimal developer time tracker (v1.0)
#
# HOW IT WORKS:
#   Every 15 seconds, checks if you edited files in the current project.
#   If yes, sends: project name, git branch, timestamp. That's it.
#   NO file names, NO code content, NO keystrokes, NO screenshots.
#
# SETUP:
#   1. cd to your project directory
#   2. Run: ./devtime.sh
#
# =============================================================================
# CONFIGURATION - Edit these values
# =============================================================================
SERVER_URL="https://dev-time.com/api/event"
# =============================================================================
# END OF CONFIGURATION - No need to edit below
# =============================================================================

ID_FILE="$HOME/.devtime_id"

# Get or create client ID
if [ -f "$ID_FILE" ]; then
    CLIENT_ID=$(cat "$ID_FILE")
else
    CLIENT_ID=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || cat /proc/sys/kernel/random/uuid)
    echo "$CLIENT_ID" > "$ID_FILE"
    echo "Generated client ID: $CLIENT_ID"
fi

# Determine project directory (git root or current directory)
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    PROJECT_DIR=$(git rev-parse --show-toplevel)
else
    PROJECT_DIR=$(pwd)
fi

PROJECT=$(basename "$PROJECT_DIR")

echo "Client ID: $CLIENT_ID"

while true; do
    # Check for files modified in last 15 seconds
    if find "$PROJECT_DIR" -type f -newermt "15 seconds ago" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/.venv/*' \
        2>/dev/null | head -1 | grep -q .; then

        BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        echo "[$(date +%H:%M:%S)] Active: $PROJECT @ $BRANCH"

        curl -s -X POST "$SERVER_URL" \
            -H "Content-Type: application/json" \
            -d "{\"project_name\":\"$PROJECT\",\"git_branch\":\"$BRANCH\",\"client_id\":\"$CLIENT_ID\",\"created_at\":\"$TIME\"}" &
    fi

    sleep 15
done
