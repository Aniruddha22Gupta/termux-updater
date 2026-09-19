#!/bin/bash

# Configuration
BRANCH="main"          # Set to your repository's default branch (e.g., main or master)
CHECK_INTERVAL=30      # Polling interval in seconds

echo "Starting GitHub listener for main.py..."

# Acquire Termux wake lock programmatically
termux-wake-lock

while true; do
    # Fetch latest commits without merging
    git fetch origin $BRANCH > /dev/null 2>&1

    # Compare local branch HEAD with remote branch HEAD
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse origin/$BRANCH)

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] New commit detected! Pulling changes..."
        git pull origin $BRANCH

        if [ -f "main.py" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing main.py..."
            python main.py
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: main.py not found in repo."
        fi
    fi

    sleep $CHECK_INTERVAL
done
