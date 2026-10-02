# PROJECT

프로젝트 자체의 정본. Label: `Current` / `Planned` / `Experimental` / `Deferred`

## Purpose

Neovim 기반 **개인 맞춤형 개발환경**. 완성형 IDE(VS Code, JetBrains)를 복제하지 않고,
**AI Coding Agent + CLI 중심 개발 방식**에 맞춘 개인용 개발 Console / IDE를 직접 구성·관리한다.

## Motivation

AI Agent 활용이 늘면서 개발자의 주 작업이 "직접 작성"에서 다음으로 이동했다:
AI 수정 코드 확인, Git Diff, Error/Diagnostic, Build/Test 결과, Server Log, Terminal 명령, 프로젝트 상태 확인.
이 작업들을 IDE↔Terminal 왕복 없이 Neovim 안에서 처리하는 것이 목적이다.

## Target User / Workflow

사용자 본인 (개인용). 목표 Workflow:

```
nvim . → 프로젝트 탐색 → AI Agent 실행 → 코드 생성/수정 → Diff 확인
      → Error/Diagnostic 확인 → Build/Test → Git Commit
```

## Scope

| 영역 | 내용 | 상태 |
|---|---|---|
| 편집·탐색 | Syntax, Treesitter, LSP, 자동완성, Definition/Reference, Rename, Code Action, Formatting, 파일·문자열·Symbol 검색 | Current (Phase 2~5) |
| Git | 변경 파일, Diff, Hunk 단위 확인, Stage/Reset, Branch, Commit, 필요 시 LazyGit 연동 | Current (Phase 6) |
| Terminal | Neovim 내부 Terminal (dev server, test, docker, git 등) | Current (Phase 7) |
| Run / Test | 프로젝트 종류 감지 후 공통 키(`<leader>r`)로 실행 명령 자동 선택 (Next.js / Spring / Flutter / Go / Python …) | Planned |
| Debug | Debugger 연동 | Planned |
| AI Agent | Claude Code, Codex CLI 등 Terminal 기반 Agent를 Terminal/Panel에서 실행 | Planned |
| UI / Layout | 목적별 Layout 전환 (Coding / Debug / Git / AI / Focus Mode) | Planned |
| Cross-platform | Windows, Linux, macOS, WSL, SSH 환경에서 동일 Config | Planned |
| 환경 재현 | `git clone` → install script → `nvim` | Planned |

예상 기본 Layout (Planned):

```
┌──────────────┬───────────────────────────┬─────────────┐
│ File Explorer│           Code            │ Diagnostics │
│              │                           │ Symbols/Git │
├──────────────┴───────────────────────────┴─────────────┤
│ Terminal / Claude Code / Test / Server Logs            │
└─────────────────────────────────────────────────────────┘
```

## Out of Scope

- 기존 IDE 전체 기능 복제
- AI Agent를 Neovim Core에 내장/종속 ([D-002](DECISIONS.md))
- 실제로 쓰지 않는 기능·Plugin

## Capabilities

- Current: 편집·탐색, Git, Terminal (상세: [USAGE.md](USAGE.md), 구조: [ARCHITECTURE.md](ARCHITECTURE.md))
- Planned: Run / Test, Debug, AI Agent, UI / Layout, Cross-platform, 환경 재현

## Supported Platform

- Planned: Windows, Linux, macOS, WSL, SSH 개발환경. OS 차이는 Platform Layer로 격리 ([D-003](DECISIONS.md))
- Current 개발/검증 환경: Windows 11 (상세: [VERIFICATION.md](VERIFICATION.md) Environment)

## Technology Direction

- Neovim + Lua Config
- 외부 CLI Tool 활용: Git, ripgrep, fd, fzf, lazygit 등
- Plugin 최소화 ([RULES.md](RULES.md) Plugin)
- Plugin Manager: 내장 `vim.pack` ([D-007](DECISIONS.md)). 개별 Plugin 선택은 [DECISIONS.md](DECISIONS.md) D-008 이후

### Dependency 분류 (Planned — Phase 13에서 확정)

| 분류 | 예상 항목 |
|---|---|
| Required | Neovim, Git, ripgrep |
| Optional | fd, fzf, lazygit, Nerd Font |
| Language-specific | LSP Server, Formatter, Debugger, Runtime/SDK |
| Platform-specific | Shell, Package Manager 차이 |

## Keymap 방향 (Planned)

일관된 Leader Key 그룹. 세부 Keymap은 Plugin 구성 시 충돌 확인 후 결정.

```
<leader>f File       <leader>s Search    <leader>e Error/Diagnostic
<leader>g Git        <leader>t Terminal  <leader>a AI Agent
<leader>r Run        <leader>x Test      <leader>d Debug
```

## Roadmap

현재 Phase는 [PROGRESS.md](PROGRESS.md) 참조.

```
Phase 0  Neovim 설치 및 Bootstrap        Phase 8  Run / Test
Phase 1  Core Config                     Phase 9  Debug
Phase 2  기본 Editing UX                 Phase 10 AI Coding Agent Integration
Phase 3  Search / Navigation + 기본 UI   Phase 11 Custom UI / Layout
Phase 4  LSP / Completion                Phase 12 Cross-platform Setup
Phase 5  Diagnostics                     Phase 13 Installer / Bootstrap 자동화
Phase 6  Git                             Phase 14 안정화 및 최적화
Phase 7  Terminal
```

## Core Terminology

| 용어 | 의미 |
|---|---|
| Mode | 목적별 Layout 프리셋 (Coding / Debug / Git / AI / Focus) |
| Platform Layer | OS별 차이(Shell, Path, Package Manager)를 격리하는 Config 계층 |
| Agent | Terminal에서 실행되는 독립 AI Coding CLI (Claude Code, Codex CLI 등) |

## Long-term Goal

어떤 PC·OS에서도 **동일한 조작 방식**으로 쓰는 개인 개발환경.
필요한 기능만 남기고 AI Agent, CLI, Git, Terminal 중심으로 재구성한 빠르고 가벼운 환경.
