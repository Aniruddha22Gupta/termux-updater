cat << 'EOF' > auto_runner.sh
#!/bin/bash

BRANCH="main"
CHECK_INTERVAL=30

# Load environment variables if .env exists
[ -f .env ] && source .env

termux-wake-lock

echo "=========================================="
echo "Listening for commits on branch: $BRANCH"
echo "=========================================="

while true; do
    git fetch origin $BRANCH > /dev/null 2>&1

    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_HASH=$(git rev-parse origin/$BRANCH 2>/dev/null)

    if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] New commit detected ($REMOTE_HASH)!"

        REQUIREMENTS_CHANGED=$(git diff --name-only $LOCAL_HASH $REMOTE_HASH | grep "requirements.txt")

        pkill -f "python main.py" > /dev/null 2>&1
        git reset --hard origin/$BRANCH > /dev/null 2>&1

        if [ -n "$REQUIREMENTS_CHANGED" ] && [ -f "requirements.txt" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing dependencies..."
            pip install -r requirements.txt
        fi

        if [ -f "main.py" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing main.py..."
            python main.py &
        fi
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x auto_runner.sh