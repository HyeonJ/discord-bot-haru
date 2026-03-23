#!/bin/bash
# PostCompact hook — compact 후 최근 디스코드 히스토리 확인 안내
# watcher test 3

TODAY=$(TZ=Asia/Seoul date +%Y-%m-%d)
HISTORY_FILE="$CLAUDE_PROJECT_DIR/memory/discord-history/$TODAY.jsonl"

if [[ -f "$HISTORY_FILE" ]]; then
  echo "<system-reminder>이전 대화가 압축됐습니다. memory/discord-history/$TODAY.jsonl 읽고 최근 대화를 파악하세요.</system-reminder>"
else
  echo "<system-reminder>이전 대화가 압축됐습니다. memory/current-tasks.md 읽고 이어서 진행하세요.</system-reminder>"
fi

exit 0
