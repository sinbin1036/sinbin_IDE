# TASK-022: 자잘한 개선 (Phase 13 Linux/macOS 결정 전)

- **Status:** In Progress (2026-10-07)
- **Goal:** Phase 13 남은 범위로 넘어가기 전에 사용자가 요청한 작은 개선을 모아 처리한다. 항목은 요청이 올 때마다 추가.

## 항목

### 1. 강제 종료 확인 창 (2026-10-07 사용자 요청)
- 요구: `:q!`를 실행하면 강제 종료 경고와 예/아니오를 띄우고, 예일 때만 `:q!` 실행
- 사용자 결정: 강제 종료 명령 전부(`:qa!`·`:wq!`·`:x!` 등) + `ZQ` 포함, 저장 안 된 파일 유무와 관계없이 **항상** 확인
- 구현: `lua/sinbin/quit_confirm.lua` (init.lua에서 `commands` 다음 로드)
  - Neovim은 `:q` 같은 기본 명령을 덮어쓸 수 없고 `QuitPre`에서 종료를 취소할 수 없음 → `:` 명령줄의 `<CR>`·`<kEnter>`·`<NL>`을 expr 매핑으로 가로챔. 강제 종료 명령이 아니면 `<CR>` 그대로
  - 강제 종료 명령: `:q[uit]!`, `:qa[ll]!`, `:quita[ll]!`, `:wq!`, `:wqa[ll]!`, `:x[it]!`, `:exi[t]!`, `:xa[ll]!`, `:cq[uit]`(! 없어도 저장 안 하고 종료). 뒤에 파일 이름·숫자 인자 허용
  - 해당하면 명령줄을 `<C-c>`로 빠져나오고 기록에 `histadd` → `vim.schedule`에서 확인 창 → 예일 때만 입력했던 창으로 돌아가 `vim.cmd`로 원래 명령 실행 (오류는 ErrorMsg로 표시)
  - 확인 창 (사용자 요청 2026-10-07: 하단 `confirm()` 대신 가운데 직사각형, 너무 넓지 않게): 가운데 floating 창 폭 44·높이 7, rounded 테두리, 제목 ` 강제 종료 `, 내용 = 입력한 명령(WarningMsg) + `저장 안 된 파일 N개의 변경이 사라집니다`(목록 버퍼 수, 없으면 `저장 안 된 파일 없음`) + 버튼 `예 (y)` / `아니오 (n)`, footer에 키 안내
  - 키: `y` 예, `n`·`q`·`Esc` 아니오, `h`/`l`·`←`/`→`·`Tab` 버튼 선택, `Enter`·`Space` 선택한 버튼 (처음은 아니오). 창을 벗어나면(WinLeave) 취소. 한글 hotkey는 한글 입력 상태에서만 눌려서 `y`/`n` 사용
  - Plugin·스크립트의 `vim.cmd("q!")`, `nvim +qa` 등은 매핑을 거치지 않아 그대로 동작
- 검증 (2026-10-07):
  - 판별 함수 29 case 통과 (`q!`·` :q! `·`wq! foo.txt`·`cq 3` 등 → 확인, `q`·`wq`·`w!`·`e!`·`ex!`·`q!foo`·`bd!` 등 → 그대로)
  - 일반 시작 `nvim --headless +qa` 에러 없음, 매핑 3개(`c`) + `ZQ`(`n`) 등록
  - `pynvim` RPC + UI attach (`nvim --embed --headless -n`, 수정된 버퍼):
    - 처음 `confirm()` 버전: `:q!<CR>` → 확인(mode `r?`), `n`/`Enter`/`Esc` → 살아 있음 / `y` → 종료 / 일반 명령 `:let`·검색 `/` 정상 / 기록에 `q!` 남음 / `:wq`(! 없음)는 확인 없이 원래대로 `E32`
    - 가운데 창 버전 (120x36): `:q!<CR>` → 현재 창이 floating(row 13, col 38, 44x7, 가운데), 커서는 `아니오` 버튼 / `n` → 창 닫힘·살아 있음·수정 유지 / `Enter`(처음) → 살아 있음 / `ZQ` 제목 `ZQ  (:q!)`, `Esc` → 살아 있음 / 확인 창에서 `<C-w>w` → 창 닫힘(취소) / `vsplit` 후 `:q!`+`y` → 그 창만 닫힘(2→1) / `h`+`Enter` → 종료 / `ZQ`+`y` → 종료 / 수정 버퍼 2개 `:qa!` → `저장 안 된 파일 2개`, `y` → 종료
  - 미검증: 실제 Windows Terminal 화면에서 확인 창 모양·버튼 색 (선택된 `예`는 `DiffDelete`, `아니오`는 `PmenuSel`, 나머지 `Pmenu`)

### 2. 오른쪽 영역 Shell 탭 이름 `Agent` (2026-10-07 사용자 요청)
- 문제: 오른쪽 영역(Agent 영역)에 시작 시 열리는 일반 Shell의 탭 이름이 `Terminal`이라 Agent 칸이 Terminal로 보임
- 처음에 상태줄 모드 칸으로 잘못 이해해 Claude Code·Codex 창 Terminal 모드를 `AGENT`로 표시하도록 구현·검증했다가, 사용자 확인 후 되돌림 (코드·문서 원복, 상태줄은 `TERMINAL` 그대로)
- 사용자 결정: 탭 이름만 `Agent`로 (Shell 그대로, 시작 시 Claude Code 자동 실행 안 함)
- 구현: `agent.lua` `toggle_shell()`의 `name = "Terminal"` → `"Agent"`. Terminal id(`side`)·키(`<Space>at`)·동작은 그대로
- 검증 (2026-10-07, `pynvim` UI attach `nvim --embed -n README.md` 160x40, `NVIM` 환경변수 없이 — 있으면 Neovim 안의 Neovim으로 보고 오른쪽 영역을 열지 않음): 시작 시 오른쪽 Shell(`side`) 실행, winbar ` Agent ` / Claude Code 자리(`agent:claude`, cmd.exe)를 열면 ` Agent  Claude Code ` / 일반 시작 에러 없음
- 상태줄 원복 확인: `statusline.lua`·`terminal.lua`·`agent.lua`를 HEAD 내용으로 되돌린 뒤 `agent.lua` 한 줄만 diff

### 3. 최근 프로젝트로 들어가면 시작 화면 닫기 (2026-10-07 사용자 요청)
- 문제: 시작 화면에서 최근 프로젝트(`1`~`5`)를 고르면 작업 폴더만 바뀌고 시작 화면이 그대로 남음 → 프로젝트에 들어간 줄 알고 `q`를 누르면 시작 화면의 `q 종료`(`qall`)가 실행돼 Neovim 종료
- 구현: `starter.lua` 최근 프로젝트 항목 action = `chdir(dir)` 후 `vim.schedule`로 `enew` (시작 화면 버퍼는 mini.starter가 wipe). 빈 코드 창이 되면 기존 "시작 화면 뒤 첫 진입" BufEnter 처리로 오른쪽 영역 Shell이 그 프로젝트 폴더에서 열림
  - `enew`를 action 안에서 바로 하면 hit-enter 프롬프트(mode `r`, 메시지 없음)에 멈춤 → mini.starter가 action 뒤 자기 버퍼를 다루기 때문으로 보임, `vim.schedule`로 미루면 없음 (수정 전 원래 코드에서는 프롬프트 없음 확인)
- 검증 (2026-10-07, `pynvim` UI attach `nvim --embed -n`, `NVIM` 없이): 시작 화면(ministarter 1개) → `1` → 시작 화면 버퍼 0개, 현재 창 일반 빈 버퍼, cwd = 고른 폴더, 창 2개(코드 + 오른쪽), 오른쪽 탭 ` Agent `·Shell cwd = 고른 폴더 / 이어서 `q` → 종료 안 됨(매크로 레지스터 대기) / 일반 시작 에러 없음
- 참고: 검증 중 실제 `projects.txt` 순서가 바뀜 (`~/AppData/Local/Temp`가 맨 위로)

### 4. `:Home` / `:Home!` 시작 화면으로 돌아가기 (2026-10-07 사용자 요청)
- 요구: 메인 화면(시작 화면)으로 돌아가는 명령. `!`를 붙이면 저장 안 된 버퍼가 있어도 저장하지 않고 넘어감
- 구현: `commands.lua` `:Home` (`bang`) → `starter.home(force)`
  - 목록 파일 버퍼 중 저장 안 된 것이 있고 `!`가 없으면 `저장 안 된 파일: a, b  (:w / :wa 후 다시, 버리려면 :Home!)` (ErrorMsg) 후 중단
  - scratch 버퍼로 새 탭 페이지(`tab sbuffer`) → `tabonly!` → 나머지 창(floating 포함) 닫기 → `MiniStarter.open()` → 파일 버퍼 전부 삭제(force). 빈 일반 버퍼를 쓰면 시작 화면 뒤 첫 진입 처리(`agent.lua`)가 오른쪽 영역을 열 수 있어 scratch 사용 (TASK-021 `:Setup`과 같은 이유)
  - Terminal(오른쪽 Agent Shell·Claude Code·Codex, 하단 패널, Run)은 닫지 않고 숨김 상태로 계속 실행 (Agent 대화 유지)
  - mini.starter가 없으면(Plugin 로드 실패) 에러 알림
- 검증 (2026-10-07, `pynvim` UI attach `nvim --embed -n README.md`, `NVIM` 없이): 파일 3개·탭 페이지 2개·창 4개, USAGE.md 수정 상태에서 `:Home` → 그대로(창 4·탭 2·파일 3), 메시지 `저장 안 된 파일: USAGE.md ...` / 오른쪽 Terminal 창에서 `:Home!` → 탭 1·창 1·시작 화면, 파일 버퍼 0개, winbar 없음·region 표시 없음, 오른쪽 Shell(`side`) 계속 실행 / 디스크의 README.md·USAGE.md 변경 없음 / 일반 시작 에러 없음
- 처음 구현에서 확인된 동작: `:Home` 뒤 최근 프로젝트로 들어가면 오른쪽 영역이 자동으로 열리지 않고(시작 시 1회용 처리), `Alt+a`로 열면 이전 폴더의 Shell이 보임 → 항목 5에서 변경

### 5. 시작 폴더 = 홈, 프로젝트 진입 시 오른쪽 Shell 새로 (2026-10-07 사용자 결정)
- 문제: `:Home` 뒤에도 작업 폴더가 이전 프로젝트라 Recent Projects에 그 프로젝트가 안 보임(현재 폴더는 목록에서 제외)
- 사용자 결정
  - `:Home`은 홈 폴더(`C:\Users\<사용자>`)로 이동. 그냥 `nvim`도 홈 폴더에서 시작 (프로젝트 안에서는 `nvim .`)
  - 시작 화면에서 프로젝트로 들어가면 오른쪽 Agent Shell을 그 폴더에서 새로 시작, 이전 Shell은 종료. Claude Code·Codex는 그대로 (선택지 2)
- 구현
  - `starter.home()`: `MiniStarter.open()` 전에 `chdir(os_homedir())` (홈은 projects 목록에 기록 안 됨)
  - `projects.lua` VimEnter: `argc() == 0`이면 기록 없이 홈 폴더로 `chdir`, 아니면 기존처럼 시작 폴더 기록 (`nvim .`·`nvim <파일>`)
  - `terminal.close(id)`: Terminal을 바로 끝냄(같은 영역 다른 Terminal로 바꾸거나 창 닫기, 버퍼 삭제) → 같은 id로 바로 다시 시작 가능. 기존 종료 callback은 그 id가 같은 버퍼일 때만 목록에서 지움 (새 Terminal을 지우지 않게)
  - `agent.enter_project()`: `terminal.close("side")` 후 설정 `startup_terminal`이 켜져 있으면 `toggle_shell(true)`. 최근 프로젝트 action이 `enew` 뒤 호출 (시작 직후 1회용 처리는 오른쪽 창이 이미 있어 건너뜀)
- 검증 (2026-10-07, `pynvim` UI attach, `NVIM` 없이)
  - 저장소 폴더에서 그냥 `nvim` → cwd `C:\Users\bro`, 시작 화면, Recent `1 ~/Desktop/sb_git/sinbin_IDE` / `nvim .` → cwd 저장소 그대로
  - `nvim README.md` + Claude Code 자리(cmd.exe) → 오른쪽 ` Agent  Claude Code ` → `:Home` → cwd 홈, Recent에 sinbin_IDE → 선택 → cwd sinbin_IDE, 오른쪽 ` Agent  Claude Code `, Shell pid 287680 → 261568(새 Shell, `term://~\Desktop\sb_git\sinbin_IDE//...`), Claude 자리 pid 260684 유지
  - 시작 직후 프로젝트 선택: 창 2개, 오른쪽 ` Agent ` 하나(중복 없음), Shell cwd = 고른 폴더, 이어서 `q` → 종료 안 됨
  - 일반 시작 `nvim --headless +qa` 에러 없음

## Related Files
`lua/sinbin/quit_confirm.lua`, `init.lua`, `lua/sinbin/agent.lua`, `lua/sinbin/{starter,commands,projects,terminal}.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`
