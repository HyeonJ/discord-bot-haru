---
name: mage-image
description: Mage (mage.space)에서 AI 이미지 생성 + 다운로드. agent-browser CDP로 자동화.
disable-model-invocation: true
argument-hint: [프롬프트 설명]
---

# Mage 이미지 생성 skill

## 사전 조건
- HP노트북 Chrome이 `--remote-debugging-port=9222`로 실행 중
- Mage (mage.space) Google 로그인 완료
- agent-browser CLI 설치됨

## 실행 순서

### 1. 로그인 확인
```bash
agent-browser --cdp 9222 eval 'document.title'
```
- "Mage"가 포함되어 있으면 OK
- 아니면 `agent-browser --cdp 9222 navigate 'https://www.mage.space/explore'`

### 2. 프롬프트 입력
```bash
agent-browser --cdp 9222 click '[contenteditable="true"]'
sleep 1
agent-browser --cdp 9222 eval '
(() => {
  const el = document.querySelector("[contenteditable=\"true\"]");
  el.focus(); el.innerHTML = "";
  document.execCommand("selectAll");
  document.execCommand("insertText", false, "$ARGUMENTS");
  el.dispatchEvent(new InputEvent("input", {bubbles: true}));
  return "typed";
})()'
```

### 3. 이미지 참조 업로드 (필요한 경우)
- Reference 버튼 클릭 → New → 업로드 영역 클릭 → file input 나타남
- `agent-browser --cdp 9222 upload 'input[type="file"]' 'C:\Users\Darren\Downloads\파일명.png'`

### 4. 전송
```bash
agent-browser --cdp 9222 press Enter
```

### 5. 생성 대기 + 이미지 추출
```bash
# 5초마다 체크, temp/30d/creations 경로 이미지 찾기
for i in $(seq 1 30); do
  sleep 5
  result=$(agent-browser --cdp 9222 eval '(() => {
    const imgs = [...document.querySelectorAll("img")].filter(i => i.src.includes("temp/30d/creations"));
    if (imgs.length > 0) return imgs[imgs.length-1].src;
    return "WAITING";
  })()' 2>&1 | tr -d '"')
  if [[ "$result" != "WAITING" && ${#result} -gt 20 ]]; then
    curl -sL "$result" -o /tmp/mage-result.jpg
    break
  fi
done
```

### 6. Discord에 전송
```bash
discord-send -f /tmp/mage-result.jpg -c 채널ID "이미지 생성 완료"
```

## 주의사항
- **로그인 항상 먼저 확인** (feedback_agent_browser.md 참고)
- **생성된 이미지 셀렉터**: `img[src*="temp/30d/creations"]` (내 생성물만)
- **Gems**: 무료 300/일, 장당 약 60 Gems (모델에 따라 다름)
- **contenteditable에 입력**: `document.execCommand("insertText")` 사용 (React 호환)
- **전송은 Enter 키**: `agent-browser --cdp 9222 press Enter`
- **저작권 주의**: Squirtle 등 캐릭터 이름은 Mage에서는 OK, ChatGPT에서는 거부됨
- **이미지 프롬프트 원칙**: 영어, 구체적 스펙, 네거티브 포함, 짧게 (feedback_image_prompt.md 참고)
