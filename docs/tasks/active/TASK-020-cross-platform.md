# TASK-020: Phase 12 Cross-platform Setup

- **Status:** In Progress (2026-10-07) — 범위·방식 결정, 구현 중
- **Goal:** Windows 밖(Linux / macOS / WSL / SSH)에서도 같은 Config가 에러 없이 켜지고 같은 조작으로 쓰이도록 Platform Layer([D-003](../../DECISIONS.md))를 채운다. Windows의 Git Bash 실행 문제도 고친다.

## Background
- 사용자 지시 (2026-10-07): TASK-019 완료 후 Phase 12 시작
- 예정 범위: [PROJECT.md](../../PROJECT.md) "남은 Phase 계획" 12번
- 현재 `platform/linux.lua`·`macos.lua`는 빈 `setup()`. 사용하는 쪽은 값이 없을 때 Linux/macOS 기본값으로 동작하도록 이미 작성됨: `python` → `python3`, `venv_bin` → `bin`, `exe_suffix` → 없음, `terminal_shell` → 'shell', `terminal_exec` → 'shell' + 'shellcmdflag', `dart_exe`/`flutter_cmd` → PATH의 `dart`/`flutter`, `ime` → 없음 (한/영 전환 안 함)

## 조사 (2026-10-07)
- **Git Bash `:!` 깨짐 재현:** Git Bash(`SHELL=/bin/bash.exe`)에서 `nvim` 실행 시 'shell' = `"C:\Program Files\Git\bin\bash.exe"`, 'shellcmdflag' = `/s /c`, 'shellxquote' = `"` → `system('echo hi')` 결과 `/usr/bin/bash: /s: No such file or directory`. `SHELL`이 비어 있으면 'shell' = `cmd.exe`로 정상
- **검증 환경:** WSL `Ubuntu-24.04` (WSL2, 24.04.2 LTS) 있음 — git, python3, node, gcc, sshd 있음 / **nvim, ripgrep, lazygit, tree-sitter 없음**, `~/.config/nvim` 없음. WSL에서 Windows 쪽 `win32yank.exe`(`C:\Program Files\Neovim\bin`), `clip.exe`, `powershell.exe` 보임. Docker Desktop 있음 (`docker-desktop` WSL 배포판). macOS 환경 없음

## 범위 (안)
1. **Windows — Git Bash에서 실행 시 'shell' 보정:** `:!`·`system()`이 동작하게
2. **Linux / macOS Platform 모듈:** Terminal Shell(`$SHELL` 기본), `python`(`python3`), Dart/Flutter(PATH), 기본값으로 충분한 항목은 명시만
3. **WSL:** clipboard provider (Windows clipboard 공유), Linux 설정 그대로 + WSL 차이만
4. **SSH:** 원격 접속 중 clipboard (OSC 52로 로컬 clipboard에 복사)
5. **config 연결 방식 (D-005 후속):** Linux/macOS에서 `~/.config/nvim` → Repository symlink. 자동화는 Phase 13
6. **한/영 자동 전환:** Windows 전용 유지 (다른 OS는 `ime` 없음 → 동작 안 함)
7. **검증:** WSL Ubuntu에서 실제 Startup·Terminal·Run·clipboard 확인, SSH는 WSL `sshd`로 접속해 확인. macOS는 UNVERIFIED

## Decisions (2026-10-07 사용자 결정, 모두 추천안)
1. Git Bash: Windows에서는 'shell'을 항상 `cmd.exe`로 되돌림 (PowerShell에서 실행할 때와 같은 동작). Terminal 창은 지금처럼 Git Bash
2. WSL clipboard: Neovim 기본 감지(`win32yank.exe`) 사용, 코드 추가 없이 검증. 안 되면 그때 명시
3. SSH clipboard: 복사만 OSC 52, 붙여넣기는 Neovim 안에서 마지막으로 복사한 내용 (Windows Terminal은 OSC 52 읽기 미지원)
4. 검증: WSL Ubuntu에 공식 Neovim v0.12.5를 `~/.local`에 설치(sudo 없음), `~/.config/nvim` → Repository symlink. 외부 CLI는 필요할 때 따로 확인

## Acceptance Criteria
- Windows: PowerShell·Git Bash 어디서 실행해도 Startup 에러 없음, `:!`·`system()` 동작
- WSL Ubuntu: Startup 에러 없음, Terminal(Shell)·Run 동작, Neovim ↔ Windows clipboard 복사/붙여넣기
- SSH 접속 중: Startup 에러 없음, yank가 로컬 clipboard로 감
- macOS: 코드 경로만 작성, UNVERIFIED로 기록
- 검증하지 못한 OS·항목은 PROGRESS Unverified에 남김

## Related Files
`lua/sinbin/platform/{init,windows,linux,macos}.lua`, `lua/sinbin/options.lua`(clipboard), `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`(D-005 후속), `docs/VERIFICATION.md`(Environment), `docs/USAGE.md`
