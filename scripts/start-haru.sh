#!/usr/bin/env bash
# 하루 봇 시작 스크립트 (WSL용)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_NAME="haru"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$LOG_DIR"

# git pull (손상된 오브젝트 방어 포함)
echo "[start] git pull 중..."
cd "$SCRIPT_DIR"
find .git/objects -type f -empty -delete 2>/dev/null || true
git fetch --all 2>&1 | tail -1
git reset --hard origin/main 2>&1 | tail -1
echo "[start] 최신 커밋: $(git log --oneline -1)"

# tmux 세션이 이미 있으면 종료
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "[start] Existing session found, killing..."
  tmux kill-session -t "$SESSION_NAME"
fi

# .env 로드
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# autoCompact 설정 (컨텍스트 비대화 방지)
source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
claude config set autoCompact true 2>/dev/null && echo "[start] autoCompact enabled" || true

# tmux 세션 생성 + Claude Code 실행
tmux new-session -d -s "$SESSION_NAME" -c "$SCRIPT_DIR"
tmux send-keys -t "$SESSION_NAME" "claude --model 'opus[1m]' --dangerously-skip-permissions" C-m

# auto-approve watcher 시작 (기존 프로세스 종료 후 재시작)
pkill -f "auto-approve-claude.sh" 2>/dev/null || true
nohup bash "$SCRIPT_DIR/hooks/auto-approve-claude.sh" > /dev/null 2>&1 &
echo "[start] auto-approve watcher 시작됨"

# relay 시작 (systemd user service — 죽어도 자동 재시작됨)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user restart haru-relay.service
echo "[start] relay 시작됨 (systemd)"

# 시스템 메시지 전송 (봇-놀이터)
"$SCRIPT_DIR/../scripts/discord-send" -c 1480479067881865347 '> **[system]** 컴퓨터 재부팅 후 하루 세션이 시작되었습니다.'

# Claude Code가 준비될 때까지 대기 후 초기 메시지 전송
sleep 8
TODAY=$(TZ=Asia/Seoul date +%Y-%m-%d)
HISTORY_FILE="$SCRIPT_DIR/memory/discord-history/$TODAY.jsonl"
if [[ -f "$HISTORY_FILE" ]]; then
  tmux send-keys -t "$SESSION_NAME" "새 세션 시작됐어. 봇-놀이터(1480479067881865347)에 '하루 부팅했어' 보내줘. 그리고 memory/discord-history/$TODAY.jsonl 읽고 못 봤던 대화 파악해줘." C-m
else
  tmux send-keys -t "$SESSION_NAME" "새 세션 시작됐어. 봇-놀이터(1480479067881865347)에 '하루 부팅했어' 보내줘. 그리고 memory/current-tasks.md 읽고 이어서 진행해줘." C-m
fi

echo "[start] 하루 시작 완료! tmux session: $SESSION_NAME"
