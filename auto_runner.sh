cat << 'EOF' > auto_runner.sh
#!/bin/bash

BRANCH="main"
CHECK_INTERVAL=15

[ -f .env ] && source .env
termux-wake-lock

echo "=========================================="
echo "Listening for updates on branch: $BRANCH"
echo "=========================================="

while true; do
    git fetch origin $BRANCH > /dev/null 2>&1

    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null)
    REMOTE_HASH=$(git rev-parse origin/$BRANCH 2>/dev/null)

    if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%H:%M:%S')] Update detected: $REMOTE_HASH"

        # Force termination of ANY running instance of main.py
        pkill -9 -f "main.py" > /dev/null 2>&1
        sleep 2

        # Reset code to match remote commit
        git reset --hard origin/$BRANCH

        # Check for requirements update
        if git diff --name-only $LOCAL_HASH $REMOTE_HASH | grep -q "requirements.txt"; then
            echo "[$(date '+%H:%M:%S')] Updating dependencies..."
            pip install -r requirements.txt
        fi

        if [ -f "main.py" ]; then
            echo "[$(date '+%H:%M:%S')] Restarting main.py..."
            # -u enables unbuffered output so logs print immediately
            python -u main.py &
        fi
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x auto_runner.sh
./auto_runner.sh