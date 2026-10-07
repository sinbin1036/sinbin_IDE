# sinbin_IDE

> AI Coding Agent와 CLI 중심 Workflow에 맞춘 Neovim 기반 개인 개발환경

## 목적

완성형 IDE를 복제하지 않고, AI 수정 코드·Diff·Diagnostic·Build/Test·Terminal 확인을
Neovim 안에서 처리하는 가벼운 개인용 개발 Console을 구성한다.
Windows / Linux / macOS / WSL / SSH에서 동일한 조작 방식을 목표로 한다.

## 현재 상태

Phase 1 완료 (Core Config, Plugin Manager `vim.pack`), Phase 2 준비. 상세: [docs/PROGRESS.md](docs/PROGRESS.md)

## 주요 기술

Neovim (Lua), Git, ripgrep 등 CLI Tool, Terminal 기반 AI Coding Agent

## 실행 / 개발

Windows: 저장소를 받은 폴더에서 설치 스크립트를 실행한다 (winget 필요, Windows PowerShell 5.1 이상).

```powershell
git clone https://github.com/sinbin1036/sinbin_IDE.git   # Git이 없으면 GitHub에서 ZIP으로 받기
cd sinbin_IDE
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Neovim·Git·ripgrep·fd, tree-sitter CLI·C compiler·lazygit·Nerd Font, config Junction(`%LOCALAPPDATA%\nvim`), Plugin, Treesitter parser, LSP·디버거(Mason)를 확인하고 없는 것만 설치한다. 언어 Runtime(Python / Node.js / Java)은 물어볼 때 고르거나 `-With python,node`로 지정한 것만 설치한다. `-CheckOnly`는 설치 없이 확인만 한다. 자세한 내용은 [docs/USAGE.md](docs/USAGE.md) "설치".

Linux / macOS / WSL (Neovim 0.12+ 필요, macOS는 미검증). `~/.config/nvim`을 symlink로 연결한다:

```bash
ln -s "<repository 경로>" ~/.config/nvim
nvim .
```

구문 강조 parser 설치에는 `tree-sitter` CLI와 C compiler가 필요하다 ([docs/USAGE.md](docs/USAGE.md)). Linux / macOS 설치 스크립트는 아직 없음.

## 문서

[docs/README.md](docs/README.md)
