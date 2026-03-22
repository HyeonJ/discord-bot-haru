#!/bin/bash
TMUX_SESSION="${TMUX_SESSION:-haru}"
PANE="${TMUX_SESSION}:0.0"
LOG="/tmp/haru-auto-approve.log"

while true; do
  LAST_LINE=$(tmux capture-pane -t "$PANE" -p 2>/dev/null | sed "/^$/d" | tail -1)
  if echo "$LAST_LINE" | grep -q "Esc to cancel"; then
    tmux send-keys -t "$PANE" '2'
    echo "[$(date "+%H:%M:%S")] Auto-approved .claude/ edit prompt" >> "$LOG"
    sleep 10  # 화면 갱신 대기
  fi
  sleep 5
done
