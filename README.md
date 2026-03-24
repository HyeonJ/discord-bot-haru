<h1 align="center">하루 — Discord 비서 봇</h1>

<p align="center">
  Discord 서버의 공용 비서 봇. WSL에서 Claude Code 기반으로 동작.
</p>

---

## 주요 기능

- **Discord 릴레이** — 서버 메시지를 Claude Code 세션으로 전달 + 응답
- **봇 헬스체크** — 니노/룬드와 상호 상태 감시 (/health 엔드포인트)
- **리서치** — idle 시간에 자율 리서치 + 결과 md-web으로 공유
- **이미지 생성** — agent-browser + Mage/ChatGPT로 AI 이미지 생성
- **NAS 백업** — memory + discord-history 매시간 자동 백업

## 기술 스택

| 영역 | 기술 |
|------|------|
| 런타임 | Node.js (discord.js v14) |
| AI | Claude Code (Opus 4.6, 1M context) |
| 네트워크 | Tailscale (봇 간 헬스체크) |
| 뷰어 | md-web (Bun + Caddy) |
| 백업 | rsync + age 암호화 |
| 환경 | WSL2 Ubuntu, tmux, systemd |
