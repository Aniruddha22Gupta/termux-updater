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

    # 1. Check for new commit updates
    if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "[$(date '+%H:%M:%S')] Update detected ($REMOTE_HASH)..." >> bot.log

        REQUIREMENTS_CHANGED=$(git diff --name-only $LOCAL_HASH $REMOTE_HASH | grep "requirements.txt")

        pkill -9 -f "main.py" > /dev/null 2>&1
        sleep 2

        git reset --hard origin/$BRANCH > /dev/null 2>&1

        if [ -n "$REQUIREMENTS_CHANGED" ] && [ -f "requirements.txt" ]; then
            echo "[$(date '+%H:%M:%S')] Updating requirements..." >> bot.log
            pip install -r requirements.txt >> bot.log 2>&1
        fi

        if [ -f "main.py" ]; then
            echo "[$(date '+%H:%M:%S')] Starting updated main.py..." >> bot.log
            nohup python -u main.py >> bot.log 2>&1 &
        fi
    else
        # 2. If no new commit, verify main.py is alive. Relaunch if crashed!
        if ! pgrep -f "main.py" > /dev/null; then
            echo "[$(date '+%H:%M:%S')] main.py is not running. Restarting process..." >> bot.log
            nohup python -u main.py >> bot.log 2>&1 &
        fi
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x auto_runner.sh