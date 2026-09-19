cat << 'EOF' > auto_runner.sh
#!/bin/bash

BRANCH="main"
CHECK_INTERVAL=15

# Load token from .env if present
[ -f .env ] && source .env

termux-wake-lock

echo "=========================================="
echo "Listening for updates on branch: $BRANCH"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "=========================================="

while true; do
    git fetch origin $BRANCH > /dev/null 2>&1

    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_HASH=$(git rev-parse origin/$BRANCH 2>/dev/null)

    if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%H:%M:%S')] Update detected ($REMOTE_HASH)..."

        REQUIREMENTS_CHANGED=$(git diff --name-only $LOCAL_HASH $REMOTE_HASH | grep "requirements.txt")

        # Kill existing running instances
        pkill -9 -f "main.py" > /dev/null 2>&1
        sleep 2

        # Reset working tree to match remote
        git reset --hard origin/$BRANCH > /dev/null 2>&1

        # Re-install dependencies if requirements.txt changed
        if [ -n "$REQUIREMENTS_CHANGED" ] && [ -f "requirements.txt" ]; then
            echo "[$(date '+%H:%M:%S')] Updating python packages..."
            pip install -r requirements.txt
        fi

        if [ -f "main.py" ]; then
            echo "[$(date '+%H:%M:%S')] Launching main.py headlessly..."
            # Redirect stdout and stderr to bot.log so output buffering doesn't block execution
            nohup python -u main.py >> bot.log 2>&1 &
        fi
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x auto_runner.sh