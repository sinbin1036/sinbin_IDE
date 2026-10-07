# TASK-017: Windows 한/영 자동 전환 (창 종류별)

- **Status:** Active (2026-10-07) — 구현·검증(빌드·상태 읽기) 완료, PR #15로 main에 merge됨. 실제 전환(`to-english`)은 사용자 확인 대기 → 확인되면 완료 처리
- **Goal:** 코드 창으로 이동하면 한글 입력 상태일 때만 영어로 바꾼다. Agent·Terminal 창에서는 한/영을 자유롭게 쓴다.

## Background
사용자 요청 (2026-10-07). Normal 모드 명령은 영어가 필요한데, Agent 창에서 한글로 질문한 뒤 코드 창으로 돌아오면 한글 상태가 남아 명령이 안 먹음.
요구사항: Agent 창은 그대로 / 코드 창 진입 시 한글일 때만 영어로 / 이미 영어면 아무것도 안 함 / ENG 키보드 레이아웃 전환 방식 금지 / Microsoft Korean IME 유지, IME 안의 한/영 상태만 / 창 이동 시에만 (polling 없음) / WinEnter·BufEnter 기준.

## Decisions (2026-10-07 사용자 결정)
1. **전환 방식 A:** 한/영 키(`VK_HANGUL`)를 흉내 내지 않고 IME 변환 모드를 직접 설정 — 전경 창의 기본 IME 창(`ImmGetDefaultIMEWnd`)에 `WM_IME_CONTROL` `IMC_GETCONVERSIONMODE` / `IMC_SETCONVERSIONMODE`로 `IME_CMODE_NATIVE`(한글) 비트만 끔. 키 두 번 눌림·포커스가 바뀐 창으로 키가 가는 문제 없음 ([D-022](../../DECISIONS.md))
2. 도우미: C# 소스(`lua/sinbin/platform/ime_helper.cs`)를 처음 쓸 때 .NET Framework `csc.exe`로 `stdpath("data")/sinbin/ime-helper.exe`에 빌드 (소스가 더 새로우면 다시 빌드). 매번 PowerShell 실행(0.5~1초)보다 빠름
3. 바로 구현 (설계 문서 먼저 아님)

## 구현 (2026-10-07)
- `lua/sinbin/ime.lua` (OS 중립): WinEnter/BufEnter 묶어서 한 번 → 코드 창(일반 파일 버퍼, floating 아님)이고 Neovim이 focus 중(FocusGained/Lost)이고 **터미널 UI(`nvim_list_uis()`의 `stdout_tty`)일 때만** Platform Layer의 `ime.to_english()` 비동기 호출. Platform에 `ime`가 없으면(Windows 외) 아무것도 안 함
- `lua/sinbin/platform/windows_ime.lua`: 도우미 빌드·실행 (`to-english` / `get`), 실패 시 알림 1회
- `lua/sinbin/platform/ime_helper.cs`: 전경 창 프로세스가 터미널(`WindowsTerminal`, `OpenConsole`, `conhost`, `wezterm-gui`, `alacritty`)일 때만 동작 → 다른 프로그램의 IME는 건드리지 않음. 한글일 때만 한글 비트를 끔
- `platform/windows.lua`에서 `platform.ime` 등록, `init.lua`에서 `sinbin.ime` 로드

## 검증 (2026-10-07)
- 도우미 자동 빌드: 첫 호출 빌드+상태 읽기 707ms, 이후 호출 약 0.1초 (비동기, Neovim 멈춤 없음)
- **상태 읽기:** 전경 Windows Terminal의 IME 상태 `ko` 정상 읽힘 (사용자가 한글 입력 중이던 상태)
- 전경 창이 목록 밖 프로세스 → `get`/`to-english` 모두 종료 코드 3 (아무것도 안 함)
- `nvim --embed`(테스트 하네스)는 `stdout_tty=false` → 전환 안 함, 사용자 TUI Neovim은 `stdout_tty=true` (읽기만 확인)
- **미검증 (사용자 확인 필요):** 실제 전환(`to-english`) — 테스트 중 실행하면 사용자가 입력 중인 창의 IME가 바뀌므로 실행하지 않음. 확인 방법: Agent 창에서 한글 입력 상태로 → `Alt+a`로 코드 창 → 영어로 바뀌는지, 영어 상태에서 이동 → 그대로인지

## Acceptance Criteria
- 코드 창 진입 시 한글 → 영어, 영어 → 그대로
- Agent·Terminal 창 진입 시 아무 동작 없음
- 다른 프로그램이 앞에 있을 때 동작 없음
- Startup 에러 없음, 체감 지연 없음

## Related Files
`lua/sinbin/ime.lua`, `lua/sinbin/platform/windows_ime.lua`, `lua/sinbin/platform/ime_helper.cs`, `lua/sinbin/platform/windows.lua`, `init.lua`, `docs/USAGE.md`, `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`
