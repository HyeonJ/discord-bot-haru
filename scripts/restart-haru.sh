#!/usr/bin/env bash
# 하루 봇 재시작 스크립트
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_NAME="haru"

# auto-approve watcher 시작 (기존 프로세스 종료 후 재시작)
pkill -f "auto-approve-claude.sh" 2>/dev/null || true
nohup bash "$SCRIPT_DIR/hooks/auto-approve-claude.sh" > /dev/null 2>&1 &
echo "[restart] auto-approve watcher 시작됨"

# relay 일시정지 (경합 방지)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user stop haru-relay.service 2>/dev/null && echo "[restart] relay paused" || true

# Claude Code 세션 재시작
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  if tmux respawn-pane -k -t "$SESSION_NAME" "cd $SCRIPT_DIR && claude --model 'opus[1m]' --dangerously-skip-permissions --continue" 2>/dev/null; then
    echo "[restart] Claude Code restarted"
  else
    echo "[restart] respawn-pane failed, falling back to start-haru.sh..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    "$SCRIPT_DIR/start-haru.sh"
    exit 0
  fi
else
  echo "[restart] No tmux session found, falling back to start-haru.sh..."
  "$SCRIPT_DIR/start-haru.sh"
  exit 0
fi

# relay 재개
sleep 2
systemctl --user start haru-relay.service 2>/dev/null && echo "[restart] relay resumed" || true

# 시스템 메시지 전송 (봇-놀이터)
"$SCRIPT_DIR/../scripts/discord-send" -c 1480479067881865347 '> **[system]** 하루 세션을 재시작했습니다.'

# Claude Code 준비 대기 (프롬프트 감지)
PANE="${SESSION_NAME}:0.0"
for i in $(seq 1 60); do
  CONTENT=$(tmux capture-pane -t "$PANE" -p 2>/dev/null | tail -5)
  if echo "$CONTENT" | grep -qE '❯|human:|Human:'; then
    break
  fi
  sleep 2
done

# 플러그인 리로드 먼저 (idle 상태에서만 동작)
tmux send-keys -t "$SESSION_NAME" '/reload-plugins' C-m
sleep 10

# 히스토리 트리거
TODAY=$(TZ=Asia/Seoul date +%Y-%m-%d)
HISTORY_FILE="$SCRIPT_DIR/memory/discord-history/$TODAY.jsonl"

# 재부팅 알림 파일 확인
NOTIFY_FILE="$SCRIPT_DIR/logs/pending-restart-notify.txt"
if [[ -f "$NOTIFY_FILE" ]]; then
  tmux send-keys -t "$SESSION_NAME" "재부팅했어. logs/pending-restart-notify.txt 있으니까 처리해줘. 그리고 memory/discord-history/$TODAY.jsonl 읽고 못 봤던 대화 파악해줘." C-m
elif [[ -f "$HISTORY_FILE" ]]; then
  tmux send-keys -t "$SESSION_NAME" "재시작됐어. memory/discord-history/$TODAY.jsonl 읽고 못 봤던 대화 있으면 파악해줘." C-m
fi

echo "[restart] 하루 재시작 완료!"
