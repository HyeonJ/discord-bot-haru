#!/bin/bash
# 하루 NAS 백업 스크립트
# cron: 0 * * * * /home/bpx27/discord-bot-haru/hooks/backup-memory-to-nas.sh

NAS_HOST="192.168.68.76"
NAS_PORT="2222"
NAS_USER="bpx27"
NAS_BASE="/mnt/d/Darren/backup/haru"
SSH_OPTS="-p $NAS_PORT -o ConnectTimeout=10 -o StrictHostKeyChecking=no"
RSYNC_OPTS="--no-perms --no-owner --no-group -r"
LOG="/tmp/haru-memory-backup.log"

# 1. Claude Code memory 백업
rsync $RSYNC_OPTS \
  -e "ssh $SSH_OPTS" \
  "$HOME/.claude/projects/-home-bpx27-discord-bot-haru/memory/" \
  "$NAS_USER@$NAS_HOST:$NAS_BASE/memory/" \
  2>/dev/null
MEMORY_OK=$?

# 2. Discord history 백업
rsync $RSYNC_OPTS \
  -e "ssh $SSH_OPTS" \
  "$HOME/discord-bot-haru/memory/discord-history/" \
  "$NAS_USER@$NAS_HOST:$NAS_BASE/discord-history/" \
  2>/dev/null
HISTORY_OK=$?

# 3. .env 암호화 백업 (1일 1회 — 시간이 0시일 때만)
ENV_OK=0
HOUR=$(date +%H)
if [ "$HOUR" = "00" ]; then
  AGE_KEY="$HOME/.claude/haru-age-key.txt"
  AGE_PUB="age10egtn2s9fxwjpyhwmxs9s0fd53hu7d2lrjnr8yalpsfvvk4tu56ql9zc89"
  ENV_FILE="$HOME/discord-bot-haru/.env"
  if [ -f "$ENV_FILE" ] && command -v age >/dev/null 2>&1; then
    age -r "$AGE_PUB" -o /tmp/haru-env.age "$ENV_FILE" 2>/dev/null
    scp -P "$NAS_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
      /tmp/haru-env.age "$NAS_USER@$NAS_HOST:$NAS_BASE/env.age" 2>/dev/null
    ENV_OK=$?
    rm -f /tmp/haru-env.age
  fi
fi

if [ $MEMORY_OK -eq 0 ] && [ $HISTORY_OK -eq 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M')] backup OK (memory+history)" >> "$LOG"
else
  echo "[$(date '+%Y-%m-%d %H:%M')] backup PARTIAL (memory=$MEMORY_OK history=$HISTORY_OK env=$ENV_OK)" >> "$LOG"
fi
