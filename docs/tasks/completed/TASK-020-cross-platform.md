# TASK-020: Phase 12 Cross-platform Setup

- **Status:** Done (2026-10-07) — PR #18 merge. 실제 SSH 접속은 미검증으로 남김 (PROGRESS Unverified)
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
5. Treesitter: 빠진 parser가 있는데 `tree-sitter` CLI가 없으면 설치 대신 경고 1회 (매 시작 parser 10개 빌드 에러 대신). WSL에는 tree-sitter CLI v0.27.0 설치해 구문 강조까지 확인
- 기록: [D-025](../../DECISIONS.md)

## 구현 (2026-10-07)
- `platform/windows.lua`: 'shell'이 cmd가 아니면 `COMSPEC`(`cmd.exe`)로
- `platform/init.lua`: `is_ssh` (`SSH_CONNECTION`/`SSH_TTY`), SSH면 `vim.g.clipboard` = 복사 OSC 52(`vim.ui.clipboard.osc52`) + 붙여넣기는 마지막 복사 내용(regtype 포함)
- `platform/linux.lua`·`macos.lua`: `python = "python3"`, 나머지는 사용하는 쪽 기본값 (주석에 목록)
- `plugins/treesitter.lua`: CLI 없고 빠진 parser 있으면 `install()` 대신 WARN 1회
- 문서: README(Linux/macOS symlink), USAGE(WSL·SSH clipboard, tree-sitter 안내, Shell), ARCHITECTURE, VERIFICATION(WSL 환경·방법)

## 검증 (2026-10-07)
- **Windows:** Git Bash에서 실행 → 'shell' `C:\WINDOWS\system32\cmd.exe`, `system('echo hi')` = `hi`, `:!echo` 동작 (수정 전 `/usr/bin/bash: /s: No such file or directory`). `SHELL` 없이·PowerShell에서도 cmd.exe. Terminal Shell은 Git Bash 그대로. `nvim --headless +qa` 출력 없음, exit 0
- **WSL Ubuntu 24.04 (Neovim v0.12.5):** 첫 실행 `vim.pack` Plugin 21개 설치, exit 0. `os=linux`, `is_wsl=true`, `python3`, 'shell' `/bin/bash`, `system()` 정상
  - clipboard: provider `win32yank` 자동. Neovim `yy` → Windows `Get-Clipboard` = `yanked-line`, Windows `Set-Clipboard` → Neovim `"+` = `from-windows`
  - Run: `hello.py` `run.file("run")` → `python3 '/tmp/sbtest/hello.py'` 출력 `run-ok /usr/bin/python3`
  - Terminal: 하단 Terminal `/bin/bash`, `echo shell-$((1+2)) $0` → `shell-3 /bin/bash`
  - 실제 TUI(pty `script`): 파일 없이 시작 → 시작 화면, 파일 열고 시작 → 코드 창 + 오른쪽 Shell(`/bin/bash`), 알림·에러 없음 (`E1568`은 pty가 DSR에 응답 안 해서, `E216 FileExplorer`는 Windows에서도 같은 기존 `silent!` 메시지)
  - Treesitter: CLI 없을 때 경고 1건 (`tree-sitter CLI 없음: 구문 강조 parser 10개 설치 건너뜀 (...)`), 빌드 에러 없음 → CLI 설치 후 parser 10개 빌드, Python 파일 highlighter 활성
- **SSH 모드 (WSL에서 `SSH_CONNECTION` 설정):** `is_ssh=true`, provider `OSC 52 (copy only)`. pty에서 `yy` → 출력에 `ESC]52;c;<base64>` 1건, 디코드 = `osc52-test`. `"+` 읽기 0ms (터미널 응답 안 기다림)
- **미검증:** 실제 SSH 접속(Windows Terminal에서 OSC 52가 내 PC 클립보드에 들어가는지), macOS, WSL 아닌 Linux, WSL의 LSP·Debug(Mason 패키지 없음)·ripgrep·lazygit

## Acceptance Criteria
- Windows: PowerShell·Git Bash 어디서 실행해도 Startup 에러 없음, `:!`·`system()` 동작
- WSL Ubuntu: Startup 에러 없음, Terminal(Shell)·Run 동작, Neovim ↔ Windows clipboard 복사/붙여넣기
- SSH 접속 중: Startup 에러 없음, yank가 로컬 clipboard로 감
- macOS: 코드 경로만 작성, UNVERIFIED로 기록
- 검증하지 못한 OS·항목은 PROGRESS Unverified에 남김

## Related Files
`lua/sinbin/platform/{init,windows,linux,macos}.lua`, `lua/sinbin/options.lua`(clipboard), `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`(D-005 후속), `docs/VERIFICATION.md`(Environment), `docs/USAGE.md`
