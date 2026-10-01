# sinbin_IDE

> AI Coding Agent와 CLI 중심 Workflow에 맞춘 Neovim 기반 개인 개발환경

## 목적

완성형 IDE를 복제하지 않고, AI 수정 코드·Diff·Diagnostic·Build/Test·Terminal 확인을
Neovim 안에서 처리하는 가벼운 개인용 개발 Console을 구성한다.
Windows / Linux / macOS / WSL / SSH에서 동일한 조작 방식을 목표로 한다.

## 현재 상태

Phase 1 — Core Config 완료, Phase 2 준비. 상세: [docs/PROGRESS.md](docs/PROGRESS.md)

## 주요 기술

Neovim (Lua), Git, ripgrep 등 CLI Tool, Terminal 기반 AI Coding Agent

## 실행 / 개발

Windows (Neovim 0.12+ 필요). 이 Repository를 Neovim config 경로에 Junction으로 연결한다:

```powershell
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "<repository 경로>"
nvim .
```

Linux / macOS: 미정 (Phase 12).

## 문서

[docs/README.md](docs/README.md)
