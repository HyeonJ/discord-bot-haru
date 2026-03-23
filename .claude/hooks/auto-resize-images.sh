#!/bin/bash
# PreToolUse(Read) hook — 2000px 초과 이미지를 원본 덮어쓰기로 리사이즈
# WSL용: Pillow(uvx) 사용

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Read 도구만 처리
if [ "$TOOL" != "Read" ]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 이미지 파일만 처리
case "$FILE_PATH" in
  *.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.webp|*.WEBP)
    ;;
  *)
    exit 0
    ;;
esac

# 파일 존재 확인
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# uvx로 Pillow 사용해서 리사이즈 (2000px 초과 시 원본 덮어쓰기)
uvx --from Pillow python3 -c "
from PIL import Image
img = Image.open('$FILE_PATH')
w, h = img.size
if max(w, h) > 2000:
    ratio = 2000 / max(w, h)
    new_w, new_h = int(w * ratio), int(h * ratio)
    img = img.resize((new_w, new_h), Image.LANCZOS)
    img.save('$FILE_PATH')
    print(f'Resized {w}x{h} -> {new_w}x{new_h}')
" 2>/dev/null

exit 0
