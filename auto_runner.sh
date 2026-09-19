#!/bin/bash

# Configuration
BRANCH="main"
CHECK_INTERVAL=30

# Keep CPU awake when screen is off/locked
termux-wake-lock

echo "=========================================="
echo "Listening for commits on branch: $BRANCH"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "=========================================="

while true; do
    # Fetch remote references silently
    git fetch origin $BRANCH > /dev/null 2>&1

    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_HASH=$(git rev-parse origin/$BRANCH 2>/dev/null)

    # Check if a new commit exists on remote
    if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] New commit detected ($REMOTE_HASH)!"

        # Kill any previously running main.py process
        pkill -f "python main.py" > /dev/null 2>&1

        # Force local working directory to match remote
        git reset --hard origin/$BRANCH > /dev/null 2>&1

        if [ -f "main.py" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing updated main.py..."
            # Run in background so the loop continues checking
            python main.py &
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: main.py not found in repository."
        fi
    fi

    sleep $CHECK_INTERVAL
done
