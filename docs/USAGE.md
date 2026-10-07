# USAGE

sinbin_IDE 사용법. **현재 설정에 실제로 있는 것만** 적는다.
Plugin 선택 이유는 [DECISIONS.md](DECISIONS.md), 모듈 구조는 [ARCHITECTURE.md](ARCHITECTURE.md) 참조.

- **Part 1 — Neovim 튜토리얼:** 처음부터 순서대로 읽는 기본 사용법 (Neovim 내장 기능)
- **Part 2 — sinbin_IDE 조작법:** 이 설정에서 추가한 Keymap·Plugin·명령 Cheatsheet

표기: `<C-d>` = Ctrl+d, `<CR>` = Enter, `<Esc>` = Esc, `<Space>` = 스페이스.
모드: **N** Normal, **V** Visual, **I** Insert.

---

# Part 1 — Neovim 튜토리얼

직접 따라 하며 익히려면 Neovim 안에서 `:Tutor`를 실행한다 (내장 실습 문서, 약 30분).
아래 내용은 그 요약 + 이 설정 기준의 차이점이다.

## 1. 열기, 저장, 종료

```
nvim 파일명        파일 열기 (없으면 새로 만듦)
nvim .             현재 디렉터리를 파일 탐색기(mini.files)로 열기
```

| 명령 | 동작 |
|---|---|
| `:w` | 저장 |
| `:q` | 종료 (저장 안 된 변경이 있으면 거부) |
| `:wq` 또는 `ZZ` | 저장 후 종료 |
| `:q!` 또는 `ZQ` | 저장하지 않고 강제 종료 |
| `:qa` / `:wqa` | 모든 창 종료 / 모두 저장 후 종료 |

> 길을 잃으면: `<Esc>`를 두세 번 누르고 `:q!` → 일단 빠져나온다.

## 2. 모드

Vim 계열의 핵심은 **모드**다. 키 하나가 모드에 따라 다른 일을 한다.

| 모드 | 들어가는 법 | 하는 일 |
|---|---|---|
| Normal | `<Esc>` (기본 상태) | 이동, 삭제, 복사 등 **명령** |
| Insert | `i`, `a`, `o` 등 | 글자 **입력** |
| Visual | `v`, `V`, `<C-v>` | 영역 **선택** |
| Command | `:` | `:w`, `:s` 같은 **Ex 명령** 입력 |

원칙: **평소에는 Normal 모드에 있고, 입력할 때만 Insert에 들어갔다가 바로 `<Esc>`로 나온다.**

## 3. 이동 (Normal)

| 키 | 이동 |
|---|---|
| `h` `j` `k` `l` | 왼쪽 / 아래 / 위 / 오른쪽 |
| `w` / `b` / `e` | 다음 단어 시작 / 이전 단어 시작 / 단어 끝 |
| `W` `B` `E` | 위와 같지만 공백 기준 단어 (`foo.bar()`를 한 단어로) |
| `0` / `^` / `$` | 줄 맨 앞 / 첫 글자 / 줄 끝 |
| `gg` / `G` / `42G` | 파일 처음 / 끝 / 42번째 줄 |
| `<C-d>` / `<C-u>` | 반 화면 아래 / 위 |
| `{` / `}` | 이전 / 다음 빈 줄 (문단 단위) |
| `%` | 짝이 맞는 괄호로 점프 |
| `f{문자}` / `t{문자}` | 줄 안에서 해당 문자로 / 그 앞까지 이동. `;` 다음, `,` 이전 |
| `<C-o>` / `<C-i>` | 이전 / 다음 점프 위치로 (검색·`G` 등으로 멀리 간 뒤 돌아오기) |

**숫자 + 이동:** `5j` = 5줄 아래, `3w` = 3단어 앞.
이 설정은 **상대 줄 번호**를 켜 두었다. 왼쪽 숫자가 현재 줄에서의 거리이므로 그 숫자를 그대로 `j`/`k` 앞에 붙이면 된다.

## 4. 입력 (Insert 들어가기)

| 키 | 입력 시작 위치 |
|---|---|
| `i` / `a` | 커서 앞 / 커서 뒤 |
| `I` / `A` | 줄 첫 글자 앞 / 줄 끝 |
| `o` / `O` | 아래 / 위에 새 줄 |
| `s` / `S` | 글자 하나 / 줄 전체를 지우고 입력 |

## 5. 편집 문법: 동사 + 대상

Vim 편집은 **동사(operator) + 대상(motion 또는 text object)** 조합이다. 하나를 배우면 나머지에 다 적용된다.

| 동사 | 의미 |
|---|---|
| `d` | 삭제 (delete) |
| `c` | 삭제 후 입력 (change) |
| `y` | 복사 (yank) |
| `>` / `<` | 들여쓰기 / 내어쓰기 |
| `gc` | 주석 토글 |

| 조합 | 결과 |
|---|---|
| `dw` | 단어 끝까지 삭제 |
| `d$` 또는 `D` | 줄 끝까지 삭제 |
| `cw` | 단어 바꾸기 |
| `y3j` | 현재 줄 포함 아래 3줄 복사 |
| `dd` / `cc` / `yy` | 동사를 두 번 = 줄 전체 |
| `dG` | 파일 끝까지 삭제 |

그 밖의 단일 키:

| 키 | 동작 |
|---|---|
| `x` | 커서 글자 삭제 |
| `r{문자}` | 커서 글자를 바꾸기 (Insert 안 들어감) |
| `p` / `P` | 커서 뒤 / 앞에 붙여넣기 |
| `u` / `<C-r>` | 되돌리기 / 다시 실행 |
| `.` | **마지막 변경 반복** (가장 강력한 키) |
| `J` | 아래 줄을 현재 줄에 합치기 |
| `~` | 대소문자 바꾸기 |

## 6. Text Object: "~안쪽", "~전체"

동사 뒤에 `i`(inner, 안쪽) / `a`(around, 감싼 것 포함) + 대상을 붙인다. **커서가 대상 안 어디에 있어도** 동작한다.

| 조합 | 대상 |
|---|---|
| `ciw` / `daw` | 단어 바꾸기 / 단어+공백 삭제 |
| `ci"` / `da"` | `"..."` 안쪽 바꾸기 / 따옴표까지 삭제 |
| `ci(` / `yi{` / `di[` | 괄호 안쪽 |
| `cit` | HTML 태그 안쪽 |
| `dip` / `yap` | 문단 |

예: `print("hello world")`에서 커서가 `w`에 있을 때 `ci"` → `print("|")`로 비우고 입력 시작.

## 7. Visual 모드 (선택)

| 키 | 선택 방식 |
|---|---|
| `v` | 글자 단위 |
| `V` | 줄 단위 |
| `<C-v>` | 블록(세로) 단위 |
| `gv` | 마지막 선택 영역 다시 선택 |

선택 후 `d` `c` `y` `>` `<` `gc` `~` 등을 누른다.
**블록 편집:** `<C-v>`로 여러 줄을 세로로 선택 → `I` → 입력 → `<Esc>` → 모든 줄 앞에 같은 내용 입력.

> Windows Terminal은 `Ctrl+V`를 붙여넣기로 가로챌 수 있다. 그때는 `<C-q>`를 쓴다 (같은 기능).

## 8. 검색과 치환

| 키 | 동작 |
|---|---|
| `/단어` / `?단어` | 아래 / 위로 검색 |
| `n` / `N` | 다음 / 이전 결과 |
| `*` / `#` | 커서 단어를 아래 / 위로 검색 |
| `<Esc>` | 검색 하이라이트 끄기 (이 설정) |

이 설정은 **smartcase**: 소문자로만 검색하면 대소문자 무시, 대문자가 섞이면 구분.

치환 (`:` 명령):

```
:s/old/new/        현재 줄의 첫 old
:s/old/new/g       현재 줄의 모든 old
:%s/old/new/g      파일 전체
:%s/old/new/gc     파일 전체, 하나씩 확인 (y/n/a/q)
:'<,'>s/old/new/g  Visual 선택 영역만 (선택 후 : 누르면 '<,'> 자동 입력)
```

입력하는 동안 결과가 미리 보이고 아래 창에 바뀔 줄 목록이 뜬다 (이 설정의 `inccommand=split`).

## 9. 복사·붙여넣기와 클립보드

- 이 설정은 **시스템 클립보드를 공유**한다. `y`로 복사한 것을 다른 프로그램에서 `Ctrl+V`로, 반대로 밖에서 복사한 것을 `p`로 붙여넣을 수 있다.
- 주의: `d`, `x`, `c`로 지운 내용도 클립보드에 들어간다. 클립보드를 덮어쓰지 않고 지우려면 `"_` (블랙홀 레지스터)를 붙인다: `"_dd`, `"_diw`.
- `Y`는 줄 끝까지 복사 (`y$`와 같음).
- WSL: Windows 클립보드와 공유 (Windows Neovim에 들어 있는 `win32yank.exe`가 PATH에 보이면 자동).
- SSH 접속 중: `y`로 복사한 내용은 터미널(OSC 52)을 거쳐 **내 PC 클립보드**로 간다. `p`는 이 Neovim에서 마지막으로 복사한 내용만 붙여넣으므로, 내 PC에서 복사한 것은 터미널 붙여넣기(`Ctrl+Shift+V`)로 넣는다.

## 10. 파일, 버퍼, 창

**버퍼** = 열려 있는 파일, **창** = 화면 분할 영역.

| 명령 / 키 | 동작 |
|---|---|
| `:e 경로` | 파일 열기 (`<Tab>` 자동완성) |
| `:ls` | 열린 버퍼 목록 |
| `:b 번호` / `:b 이름일부` | 해당 버퍼로 전환 |
| `:bn` / `:bp` | 다음 / 이전 버퍼 |
| `<C-^>` | 직전 버퍼와 왕복 |
| `:bd` | 현재 버퍼 닫기 |
| `:sp` / `:vsp` | 가로 / 세로 분할 (이 설정: 새 창은 아래 / 오른쪽에) |
| `<C-w>h` `j` `k` `l` | 창 사이 이동 |
| `<C-w>q` / `<C-w>o` | 현재 창 닫기 / 현재 창만 남기기 |
| `<C-w>=` | 창 크기 균등하게 |

## 11. 반복 작업: 매크로와 마크

**매크로** — 키 입력을 녹화해서 재생:

```
qa      a 레지스터에 녹화 시작
...     원하는 편집
q       녹화 종료
@a      재생
10@a    10번 재생
@@      마지막 매크로 다시 재생
```

**마크** — 위치 기억:

```
ma      현재 위치를 a로 표시
'a      a 표시한 줄로 이동 (`a 는 정확한 위치로)
''      직전 점프 위치로
```

## 12. Undo

- 이 설정은 **undo 기록을 파일로 저장**한다. 파일을 닫았다 다시 열어도 `u`로 이전 변경을 되돌릴 수 있다.
- `:earlier 10m` / `:later 10m` — 10분 전 / 후 상태로.

## 13. 도움말과 진단

| 명령 | 용도 |
|---|---|
| `:Tutor` | 내장 실습 튜토리얼 |
| `:h 주제` | 도움말. 예: `:h ciw`, `:h :s`, `:h text-objects` |
| `:h i_CTRL-W` | 모드별 키 도움말 (`i_` Insert, `v_` Visual, `c_` Command) |
| `:checkhealth` | 환경 진단 (Plugin, clipboard, provider 등) |
| `:messages` | 지나간 메시지·에러 다시 보기 |

## 14. 익히는 순서 (추천)

1. **1주차:** `:Tutor` 완주. `hjkl`, `i`/`a`/`o`, `<Esc>`, `:w`/`:q`, `dd`/`yy`/`p`, `u`
2. **2주차:** `w`/`b`/`e`, `0`/`$`, `gg`/`G`, 상대 줄 번호로 `5j` 이동, `/` 검색
3. **3주차:** 동사+대상 (`dw`, `cw`, `ci"`, `dap`), `.` 반복 — 여기서부터 속도가 붙는다
4. **4주차:** Visual 블록, `:%s` 치환, 버퍼·창 이동, Part 2의 Surround
5. **이후:** 매크로, 마크, 반복되는 작업을 발견하면 `:h`로 찾아보기

마우스와 방향키도 동작하지만, 손을 홈 row에서 떼지 않는 것이 Vim을 쓰는 이유다. 의식적으로 `hjkl`과 단어 이동을 쓴다.

---

# Part 2 — sinbin_IDE 조작법

- Leader: `<Space>` / LocalLeader: `\`

## 설치 (Windows, setup.ps1)

새 PC에서 저장소를 받은 뒤 저장소 폴더에서 실행한다. 다시 실행해도 되고, 이미 있는 것은 버전만 확인하고 넘어간다.

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1              # 확인 + 없는 것 설치
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -With python,node   # Runtime도 설치
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly    # 확인만
```

| 단계 | 내용 |
|---|---|
| Core tools | Git(Git Bash 포함), Neovim 0.12+(낮으면 업그레이드), ripgrep, fd |
| Build & helper tools | tree-sitter CLI, C compiler(gcc / clang, 없으면 WinLibs gcc·gdb), lazygit, JetBrainsMono Nerd Font |
| Language runtimes | Python, Node.js, Java(JDK 21), Flutter/Dart: **강제 설치 안 함**. 없으면 번호로 고르거나(`-NoPrompt`면 묻지 않음) `-With`로 지정. Flutter는 수동 설치 안내만 |
| Config link | `%LOCALAPPDATA%\nvim` → 저장소 Junction. 다른 폴더가 있으면 `nvim.backup-<시각>`으로 옮긴 뒤 연결 |
| Neovim plugins | `vim.pack`이 lock 파일 revision으로 설치 (진행률 bar) |
| Treesitter parsers | parser 10개 병렬 설치 (tree-sitter CLI·C compiler 없으면 건너뜀) |
| LSP / Debug (Mason) | clangd 항상, vtsls·js-debug-adapter는 Node.js, basedpyright·ruff·debugpy는 Python, jdtls·java-debug-adapter는 Java가 있을 때만 |

- 화면: ✔ 설치됨 / 이미 설치됨, ─ 건너뜀(이유), ✖ 실패(단계 › 항목 › 작업, 종료 코드, 마지막 출력 몇 줄)
- 끝에 `SINBIN IDE READY`(실패 0) 또는 `SETUP INCOMPLETE`, 새로 설치·이미 있음·건너뜀·실패 수, 총 소요 시간. 실패가 있으면 종료 코드 1
- 전체 출력은 `%TEMP%\sinbin-setup-<시각>.log`
- winget은 진행률(%)을 주지 않으므로 winget 설치 줄은 spinner + winget이 출력한 마지막 줄 + 경과 시간만 보인다. Neovim·Git·Runtime 설치 중 관리자 권한(UAC) 창이 뜰 수 있다
- 설치 후 PATH는 새 터미널부터 적용된다 (스크립트 안에서는 바로 다시 읽어 사용)
- **Neovim 안에서:** `:Setup` 또는 시작 화면 `s` → 새 탭의 Terminal에서 같은 스크립트가 실행된다 (Runtime 번호 입력도 거기서). 끝나면 알림이 뜨고 `q`로 탭을 닫는다. 새로 설치된 Plugin은 Neovim을 다시 시작해야 적용된다
  - Plugin이 하나도 없어도(첫 실행 때 Git·네트워크 문제로 설치 실패) `:Setup`은 있다. 이때는 시작 화면이 안 뜨므로 빈 화면에서 `:Setup` 입력
  - Neovim·Git이 아예 없는 처음 설치는 PowerShell에서 `setup.ps1`

## 설치된 Plugin

| Plugin | 하는 일 | 설정 위치 |
|---|---|---|
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | 괄호·따옴표 자동 닫기 | `lua/sinbin/plugins/editing.lua` |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | 감싸는 문자 추가·삭제·교체 | `lua/sinbin/plugins/editing.lua` |
| [mini.pick](https://github.com/nvim-mini/mini.pick) | 파일·내용·버퍼·도움말 검색 창 | `lua/sinbin/plugins/search.lua` |
| [mini.extra](https://github.com/nvim-mini/mini.extra) | 추가 검색 창 (최근 파일) | `lua/sinbin/plugins/search.lua` |
| [mini.files](https://github.com/nvim-mini/mini.files) | 파일 탐색기 (폴더를 버퍼처럼 편집, Git 상태 색) | `lua/sinbin/plugins/sidebar.lua` |
| [aerial.nvim](https://github.com/stevearc/aerial.nvim) | Outline: 현재 파일의 클래스·함수·변수 트리 | `lua/sinbin/plugins/sidebar.lua` |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | 색 테마 (`moon`) | `lua/sinbin/plugins/ui.lua` |
| [mini.icons](https://github.com/nvim-mini/mini.icons) | 파일 아이콘 (Nerd Font 필요) | `lua/sinbin/plugins/ui.lua` |
| [mini.statusline](https://github.com/nvim-mini/mini.statusline) | 하단 상태바 (내용은 `lua/sinbin/statusline.lua`) | `lua/sinbin/plugins/ui.lua` |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | 위쪽 탭 바 (열린 파일) | `lua/sinbin/plugins/ui.lua` |
| [mini.clue](https://github.com/nvim-mini/mini.clue) | 키 힌트 창 | `lua/sinbin/plugins/ui.lua` |
| [mini.notify](https://github.com/nvim-mini/mini.notify) | 알림 창 (오른쪽 위) | `lua/sinbin/plugins/ui.lua` |
| [mini.starter](https://github.com/nvim-mini/mini.starter) | 시작 화면 (파일 없이 `nvim` 실행 시) | `lua/sinbin/starter.lua` |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | 언어 Server 설정 모음 | `lua/sinbin/plugins/lsp.lua` |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 언어 Server 설치 (`:Mason`) | `lua/sinbin/plugins/lsp.lua` |
| [mini.completion](https://github.com/nvim-mini/mini.completion) | 자동완성 목록, 문서 창, 인자 힌트 | `lua/sinbin/plugins/lsp.lua` |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 구문 분석기(parser) 설치·업데이트 | `lua/sinbin/plugins/treesitter.lua` |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | git 변경 표시, hunk, inline blame | `lua/sinbin/plugins/git.lua` |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | 디버거 연결 (DAP) | `lua/sinbin/plugins/debug.lua` |
| [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view) | 디버그 패널, 줄 끝 변수 값 | `lua/sinbin/plugins/debug.lua` |
| [diffview-plus.nvim](https://github.com/dlyongemallo/diffview-plus.nvim) | 여러 파일 변경 검토, 파일 이력 (diffview.nvim 유지보수 fork) | `lua/sinbin/plugins/git.lua` |

Plugin 관리는 Neovim 내장 `vim.pack` ([D-007](DECISIONS.md)). 아래 [Plugin 관리](#plugin-관리) 참조.

## 화면 배치 (VS Code식)

```
┌─────────┬──────────────────────────────┬────────────┐
│         │ a.lua  b.lua ×  c.lua        │            │ 탭 바 (열린 파일)
│ Outline ├──────────────┬───────────────┤            │
│ (필요할 │ lua > a.lua  │ lua > c.lua   │ Terminal | │ 창마다 파일 경로 / 오른쪽 영역 탭
│  때만)  │  코드 창 1    │  코드 창 2     │ Claude Code│
│         ├──────────────┴───────────────┤ (오른쪽 영역)│
│         │ Terminal 1 │ Terminal 2 │ Run│            │ 하단 패널
└─────────┴──────────────────────────────┴────────────┘
 NORMAL │ main +3 ~1 │ 에러 2 경고 1 │ 작업폴더    ▶ Run │ Claude │ python │ 12:5
```

- **코드 창 여러 개:** 내장 창 분할 `<C-w>v`(좌우) / `<C-w>s`(위아래). 탭 바는 모든 창이 같이 쓴다.
- **하단 패널:** Terminal·Run이 한 창을 같이 쓰고 위쪽 탭으로 전환(클릭 가능). 디버그 중에는 디버그 패널이 그 오른쪽 절반. 코드 아래에만 있고 Outline·Agent 아래로는 내려가지 않는다.
- **Terminal 영역에는 Terminal만:** 오른쪽 영역·하단 패널에 커서가 있을 때 파일을 열어도(탭 클릭, `<Space>ff`, 탐색기, `Ctrl+O`) 파일은 마지막에 쓰던 코드 창에 열리고 그 영역은 Terminal 그대로 (VS Code와 같음).
- **탭 페이지(오른쪽 위 `1 2 3`):** Neovim의 화면 전체 작업 공간. 이 배치는 탭 페이지 하나를 기준으로 하므로 평소에는 쓰지 않는다 (diffview `<Space>gv`는 자체 탭 페이지를 열고 `q`로 닫음). 생겼다면 `:tabonly`(현재 것만 남김) / `:tabclose`.
- **오른쪽 영역:** 창 하나에 Terminal·Claude Code·Codex가 탭으로 (위쪽 탭 클릭 또는 각 키로 전환). **시작하면 일반 Terminal이 열린다** (Agent는 자동 실행 안 함, 커서는 코드 창). 시작 화면에서는 열지 않고, 거기서 파일을 처음 열 때 그 파일의 프로젝트 폴더에서 열린다 (그 전에 `<Space>ac` 등으로 오른쪽 영역을 열었으면 그대로). git commit 메시지 편집·diff 모드·Neovim 안의 Neovim에서는 열지 않는다.
- **왼쪽 영역:** Files(`<Space>fe`)와 Outline(`<Space>co`)이 번갈아 쓴다. 아래 [Outline](#outline-현재-파일-구조) 참조.
- **상태바 (화면 전체 한 줄, VS Code 상태바 형식):**
  ```
   NORMAL    main*    0↓ 1↑    ⊗ 2  ⚠ 1    sinbin_IDE          ▶ Run   Claude Code    Ln 12, Col 5    python
  ```
  - 모드: 진한 배경 + 흰 굵은 글자 (`NORMAL` 파랑, `INSERT` 초록, `VISUAL` 보라, `REPLACE` 빨강, `COMMAND` 노랑, `TERMINAL` 청록)
  - 브랜치: 커밋 안 한 변경이 있으면 `*` (VS Code와 같음)
  - pull/push: `0↓ 1↑` = 받을 commit 0개 / 올릴 commit 1개. 원격 브랜치가 없으면 `publish`. 마지막 fetch/pull 기준 원격 상태와 비교 (자동 fetch 안 함). Terminal·lazygit·`:!` 명령 뒤, Neovim으로 돌아올 때 다시 읽는다
  - 에러 / 경고 개수: 항상 표시 (0도 표시), 빨강 / 노랑
  - 작업 폴더 이름
  - 오른쪽: 실행 중일 때만 색 배지 `▶ Run`(초록) · `Debug`(정지 중이면 `Debug 정지`) · `Claude Code`/`Codex`(보라) · `Ln 줄, Col 열` · 파일 타입
  - **디버그 중에는 상태바 전체가 주황색** (VS Code와 같음)
  - 변경 줄 수(`+3 ~1`)는 상태바에 없다 → 줄 번호 옆 표시와 `]h`/`<Space>gp`
- **종료:** `:q`는 창 하나를 닫는다. 마지막 코드 창에서 `:q`(`:wq`, `ZZ`)하면 Outline·하단 패널·오른쪽 영역도 함께 닫혀 Neovim이 종료된다 (탭 페이지가 여럿이면 그 탭 페이지만). 저장 안 된 파일이 있으면 종료되지 않고 `E37`/`E162`로 알려 준다 (`:w`/`:wa` 후 다시, 버리려면 `:qa!`). Terminal·패널 창에서 `:q`는 그 창만 닫는다. `:q`가 아닌 방법(`<C-w>c` 등)으로 마지막 코드 창을 닫으면 그 자리에 빈 코드 창이 남는다.
- **하단 패널 높이·양쪽 폭**은 직접 바꾼 크기가 유지된다. `:copen`·`:help` 창이 열려도 패널은 줄어들지 않는다.
- **한/영 자동 전환 (Windows):** 코드 창에 들어가면 한글 입력 상태일 때만 영어로 바꾼다 (Microsoft 한국어 IME 유지, 한/영 상태만). 이미 영어면 그대로, Agent·Terminal 창은 건드리지 않음. 창을 옮길 때만 동작 (계속 확인하지 않음). 처음 쓸 때 도우미 프로그램을 한 번 빌드한다 (`.NET Framework` `csc.exe`, Windows 기본 포함).

### 탭 (bufferline)

| 모드 | 키 | 동작 |
|---|---|---|
| N | `]b` / `[b` | 다음 / 이전 탭 |
| N | `<Space>bd` | 탭 닫기 (창은 그대로, 직전 파일로 바뀜. 저장 안 된 파일은 확인: `s` 저장 / `d` 버리기 / `c`·`<Esc>` 취소) |
| N | `<Space>bo` | 다른 탭 모두 닫기 |
| N | `<Space>bp` | 탭마다 글자 표시 → 글자로 바로 이동 |
| N | `<Space>bP` | 탭 고정 / 해제 (고정 탭은 왼쪽에) |
| N | `<Space>b]` / `<Space>b[` | 탭 순서 오른쪽 / 왼쪽으로 이동 |
| 마우스 | 클릭 / `×` 또는 가운데 클릭 | 전환 / 닫기 |

- 탭에 에러·경고 아이콘과 개수가 붙는다. 저장 안 된 파일은 `●`.
- 내장 `:bd`는 그 파일을 보던 창까지 닫으므로 `<Space>bd`를 쓴다.

### 창 이동

**규칙 (모든 영역 키 공통):** 숨겨져 있으면 열고 그 창으로 / 보이는데 다른 창에 있으면 그 창으로 이동 / 이미 그 창에 있으면 숨김.
적용: `<Space>tt`(Terminal), `<Space>tp`(하단 패널), `<Space>ac`/`ax`/`at`(오른쪽 영역), `<Space>co`(Outline), `<Space>du`(디버그 패널).

| 모드 | 키 | 동작 |
|---|---|---|
| N, T | `Alt+h` / `Alt+j` / `Alt+k` / `Alt+l` | 왼쪽 / 아래 / 위 / 오른쪽 창으로 (Terminal 입력 중에도 바로) |
| N, T | `Alt+a` | 코드 창 ↔ 오른쪽 영역 왕복 ([AI Agent](#ai-agent-claude-code-codex)) |
| N, T | `Alt+z` | 오른쪽 영역 전체 화면 ↔ 원래 배치 |
| N / N·T | `<Space>tp` / `` Alt+` `` | 하단 패널 전체 열기 / 이동 / 숨기기 (다시 열면 마지막에 보던 Terminal) |

- **Terminal 창에 들어가면 자동으로 입력 모드** (키·`<C-w>`·마우스 모두). 끝난 Run 결과 창만 Normal 모드로 남는다 (다음 키에 창이 닫히지 않게).
- Terminal 입력 중에는 `<Space>` 키가 프로그램에 입력되므로, 숨기려면 `<C-q>`(Normal 모드) → `<Space>tt`, 또는 `` Alt+` ``.
- Windows Terminal은 `Alt+화살표`를 자기 창 분할 이동에 쓰므로 `Alt+h/j/k/l`을 쓴다.

### VS Code 단축키

| 키 | 동작 | Leader 키 | Windows Terminal 전달 |
|---|---|---|---|
| `Ctrl+P` | 파일 찾기 (N) | `<Space>ff` | 됨 (일반 제어 문자) |
| `Ctrl+B` | 왼쪽 영역 열기 / 닫기 — 마지막에 쓴 Files 또는 Outline (N) | `<Space>fe` / `<Space>co` | 됨 (일반 제어 문자) |
| `` Alt+` `` | 하단 패널 열기 / 이동 / 숨기기 (N, T) — VS Code의 `` Ctrl+` `` 대신 | `<Space>tp` | 됨 (Alt 조합). `` Ctrl+` ``는 Windows Terminal이 아무것도 보내지 않아 채택 안 함 |
| `Ctrl+Shift+P` | — (채택 안 함) | `<Space>sc` 명령 팔레트 | 안 됨: Windows Terminal 자체 명령 팔레트 |
| `Ctrl+Shift+F` | — (채택 안 함) | `<Space>sg` 내용 검색 | 안 됨: Windows Terminal 찾기 (설정 파일에도 지정됨) |

- `Ctrl+P`는 내장 Normal `<C-p>`(위로 한 줄 = `k`), `Ctrl+B`는 내장 한 화면 위로 스크롤을 대체한다 (스크롤은 `<C-u>`).
- Terminal 안 프로그램에는 `Alt+h/j/k/l`·`Alt+a`·`` Alt+` ``·`<C-q>`가 전달되지 않는다 (Neovim이 먼저 씀). bash의 `Alt+l`(단어를 소문자로) 정도만 영향.
- 같은 기능의 두 키(별칭)는 의도된 것: `Ctrl+P` = `<Space>ff`, `Ctrl+B` ≈ `<Space>fe`/`<Space>co`, `` Alt+` `` = `<Space>tp`, `F5`/`F10`/`F11`/`F12` = `<Space>dc`/`dn`/`di`/`do`. 전체 Keymap은 `<Space>sk`로 검색.

## 편집

| 모드 | 키 | 동작 |
|---|---|---|
| N | `<Esc>` | 검색 하이라이트 끄기 |
| V | `J` / `K` | 선택한 줄을 아래 / 위로 이동 (들여쓰기 자동 정리) |
| V | `>` / `<` | 들여쓰기 / 내어쓰기, 선택 유지 (연속 입력 가능) |
| N | `gcc` | 현재 줄 주석 토글 (Neovim 내장) |
| N | `gc{motion}` | 범위 주석 토글. 예: `gcip` 문단, `gc3j` 아래 3줄 (내장) |
| V | `gc` | 선택 영역 주석 토글 (내장) |

- Visual `J`/`K`는 Vim 기본 동작(줄 합치기 / 도움말 조회)을 덮어쓴다. 줄 합치기는 Normal `J`로 가능.

## Surround (mini.surround, vim-surround 스타일 키)

`hello` 위에 커서가 있다고 가정.

| 모드 | 키 | 동작 | 예시 |
|---|---|---|---|
| N | `ys{motion}{문자}` | 감싸기 | `ysiw"` → `"hello"` |
| N | `yss{문자}` | 줄 전체 감싸기 | `yss)` → `(hello world)` |
| V | `S{문자}` | 선택 영역 감싸기 | `viwS]` → `[hello]` |
| N | `ds{문자}` | 감싼 문자 삭제 | `ds"` : `"hello"` → `hello` |
| N | `cs{기존}{새것}` | 감싼 문자 교체 | `cs"'` : `"hello"` → `'hello'` |

감싸는 문자 종류:

| 문자 | 의미 |
|---|---|
| `(` `[` `{` `<` | 여는 괄호 — 안쪽 공백 포함. `cs"(` → `( hello )` |
| `)` `]` `}` `>` | 닫는 괄호 — 공백 없음. `cs")` → `(hello)` |
| `t` | HTML 태그. 추가·교체 시 태그 이름 입력. `cstt` + `div` : `<p>hi</p>` → `<div>hi</div>` |
| `f` | 함수 호출. 추가 시 함수 이름 입력. `ysiwf` + `print` → `print(hello)` |
| `?` | 왼쪽·오른쪽 문자를 직접 입력 |
| 그 외 문자 | 양쪽에 같은 문자. 예: `*`, `_`, `` ` `` |

- `.`으로 반복 가능.
- 커서가 감싼 문자 안에 없으면 같은 줄의 다음 대상을 찾는다 (`cover_or_next`).
- `ys`/`ds`/`cs` 입력 후 잠깐 대기가 생길 수 있다 (`yss` 등 더 긴 키를 기다리는 것).

## 괄호 자동 닫기 (mini.pairs, Insert 모드)

| 입력 | 결과 (`|`는 커서) |
|---|---|
| `(` `[` `{` | `(|)` — 닫는 괄호 자동 입력 |
| `"` `'` `` ` `` | `"|"` — 단, `'`는 글자 바로 뒤에서는 하나만 입력 (`don't`) |
| 닫는 문자 바로 앞에서 `)` | 새로 입력하지 않고 건너뜀 |
| 빈 쌍 `(|)`에서 `<BS>` | 쌍을 함께 삭제 |
| 괄호 쌍 `{|}`에서 `<CR>` | 빈 줄을 만들고 그 안으로 이동 |
| `<C-v>` + 문자 | 자동 닫기 없이 그 문자만 입력 |

- `\` 바로 뒤에서는 자동 닫기를 하지 않는다.
- filetype이 없는 버퍼(`:enew` 등)에서 `{<CR>`은 들여쓰기가 한 단계 더 들어간다. 코드 파일(lua, c 등)에서는 정상.

## 검색과 파일 이동 (mini.pick, mini.files)

외부 도구: 내용 검색에 ripgrep(`rg`) 사용. Windows는 `winget install BurntSushi.ripgrep.MSVC`.
아이콘 표시에 Nerd Font 필요. Windows는 `winget install DEVCOM.JetBrainsMonoNerdFont` 후 Terminal 글꼴을 `JetBrainsMono NF`로 지정.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `<Space>ff` | 파일 이름 검색 |
| N | `<Space>fb` | 열린 버퍼 전환 |
| N | `<Space>fr` | 최근 파일 |
| N | `<Space>fe` | 파일 탐색기 열기 / 닫기 (현재 파일 위치에서 열림, Outline이 열려 있으면 바꿔서 엶) |
| N | `<Space>sg` | 프로젝트 내용 검색 (입력하는 대로 결과 갱신) |
| N | `<Space>sw` | 커서 아래 단어로 내용 검색 |
| N | `<Space>sh` | 도움말 검색 |
| N | `<Space>sr` | 마지막 검색 창 다시 열기 |
| N | `<Space>ss` | 프로젝트 전체 심볼 검색 (입력하는 대로 LSP에 질의, 현재 파일 구조는 Outline) |
| N | `<Space>sc` | 명령 팔레트: 명령 검색 → `<CR>` 실행 |
| N | `<Space>sk` | Keymap 검색 (키·설명으로) |

`<Space>`만 누르고 기다리면 가능한 키 목록이 아래에 뜬다 (mini.clue). `g`, `z`, `[`, `]`, `<C-w>`, `"`, `'`도 같다.

### 검색 창 안에서

| 키 | 동작 |
|---|---|
| 글자 입력 | 결과 좁히기 (fuzzy) |
| `<C-n>` / `<C-p>` | 아래 / 위 항목 |
| `<CR>` | 열기 |
| `<C-v>` / `<C-s>` | 세로 분할 / 가로 분할로 열기 (새 탭 페이지로 여는 `<C-t>`는 끔) |
| `<Tab>` | 미리보기 토글 |
| `<C-x>` → `<M-CR>` | 여러 개 표시 후 한꺼번에 열기 (quickfix) |
| `<C-Space>` | 현재 결과 안에서 다시 검색 (refine) |
| `<Esc>` | 닫기 |

### 파일 탐색기 안에서

| 키 | 동작 |
|---|---|
| `l` / `h` | 폴더 들어가기·파일 열기 / 상위 폴더 |
| `L` | 파일 열고 탐색기 닫기 |
| 글자 편집 | 이름 바꾸기, 새 줄에 이름 입력 = 새 파일 (`/`로 끝나면 폴더), `dd` = 삭제 |
| `=` | 편집 내용 실제 적용 (확인 창 표시) |
| `g.` | 커서의 폴더(파일이면 그 폴더)를 **작업 폴더**로 (`cd`). "여기(.)를 작업 폴더로". 탐색기 이동만으로는 작업 폴더가 바뀌지 않는다 |
| `<Tab>` | Outline으로 바꾸기 |
| `g?` | 도움말 |
| `q` | 닫기 |

- Git 상태: 파일·폴더 **이름 자체에 색** (수정·이름 바뀜 노랑, 추가·새 파일 초록, 충돌 빨강) + 오른쪽 끝에 `M` 수정 / `A` 추가 / `U` 새 파일(추적 안 함) / `R` 이름 바뀜 / `!` 충돌. 안에 변경이 있는 폴더는 그 색 + `•`. 탐색기를 열 때마다 새로 읽는다.
- 탐색기에서 편집만 하고 `=`를 누르지 않으면 디스크는 바뀌지 않는다.
- 기본 탐색기 netrw(`:Ex`)도 그대로 쓸 수 있다.

### Outline (현재 파일 구조)

현재 파일의 클래스·메서드·함수·변수를 계층으로 보여 주는 왼쪽 창 (aerial.nvim). LSP가 연결되면 LSP, 아니면 Treesitter(Markdown 제목 등) 기준. 다른 파일로 가면 따라 바뀐다. 커서가 들어 있는 심볼(가장 안쪽)이 강조되고 Outline 커서도 따라간다 (심볼 사이 빈 줄에서는 강조 없음). 심볼이 없는 파일은 `심볼 없음` (이유는 `:AerialInfo`).

| 키 | 동작 |
|---|---|
| `<Space>co` | Outline 열기 / 닫기 (Files가 열려 있으면 바꿔서 엶) |
| `j` / `k` | 아래 / 위 |
| `h` / `l` | 접기 / 펼치기 (`H` / `L`: 아래까지 전부) |
| `<CR>` | 그 코드 위치로 이동 |
| `{` / `}` | 이전 / 다음 심볼 |
| `<Tab>` | Files로 바꾸기 |
| `q` | 닫기 |
| `g?` | 전체 키 목록 |

## LSP와 자동완성 (TypeScript, Python, Java, Dart, C)

코드 파일을 열면 언어 Server가 자동으로 연결된다. 연결 상태는 `:checkhealth vim.lsp`.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `K` | 설명(hover) 보기 (내장) |
| N | `gd` | 정의로 이동 (`<C-o>`로 복귀) |
| N | `grr` | 참조 찾기 (내장) |
| N | `gri` | 구현으로 이동 (내장) |
| N | `grn` | 이름 바꾸기 (내장) |
| N | `gra` | Code Action (import 추가 등, 내장) |
| N | `gO` | 문서 심볼 목록 (내장) |
| N, V | `<Space>cf` | 포맷 (파일 전체 / 선택 범위) |
| I | `<C-s>` | 함수 인자 힌트 (내장) |

### 자동완성 (mini.completion)

입력하면 잠시 후 목록이 자동으로 뜬다.

| 키 | 동작 |
|---|---|
| `<Tab>` / `<S-Tab>` | 다음 / 이전 항목 |
| `<CR>` | 선택한 항목 입력 (선택 없으면 줄바꿈) |
| `<C-e>` | 목록 닫기 (내장) |

- 항목을 고르면 옆에 문서 창이 뜬다. 함수 괄호 안에서는 인자 힌트가 뜬다.
- snippet 항목(`S` 표시)은 입력 후 `<Tab>` / `<S-Tab>`으로 다음 칸 이동 (내장 `vim.snippet`). 완성 목록이 떠 있으면 목록 이동이 먼저, 둘 다 아니면 보통 Tab.

### 언어 Server 설치 (mason.nvim)

| 작업 | 방법 |
|---|---|
| 목록·설치 화면 | `:Mason` (`i` 설치, `X` 제거, `U` 업데이트, `g?` 도움말) |
| 명령으로 설치 | `:MasonInstall vtsls basedpyright ruff clangd jdtls` (새 장비에서 1회) |

| 언어 | Server | 비고 |
|---|---|---|
| TypeScript / JavaScript | vtsls | `package.json` 또는 `tsconfig.json`이 있는 폴더 기준 |
| Python | basedpyright + ruff | ruff가 lint·포맷 담당 |
| Java | jdtls | JDK 21 이상 필요. 첫 실행은 수십 초 걸림 |
| Dart / Flutter | dart language-server | Flutter SDK에 포함, 설치 불필요 |
| C | clangd | |

- 새 언어를 추가하려면 `:MasonInstall <이름>` 후 `lua/sinbin/plugins/lsp.lua`의 `vim.lsp.enable({ ... })`에 이름 추가.

## 구문 강조 (Treesitter)

코드 구조를 분석해 색을 입힌다. 아래 언어는 파일을 열면 자동으로 적용된다.

- TypeScript (`.ts`, `.tsx`), JavaScript, Python, Java, Dart, C, JSON, YAML, TOML (C도 nvim-treesitter로 설치: 디버그 변수 표시에 필요)
- 목록에 없는 언어는 기존 방식(Vim syntax)으로 강조된다.

| 작업 | 방법 |
|---|---|
| 언어 추가 | `lua/sinbin/plugins/treesitter.lua`의 `parsers` 목록에 이름 추가 후 재시작 (또는 `:TSInstall <이름>`) |
| 업데이트 | `:TSUpdate` (Plugin 업데이트 시 자동 실행) |
| 상태 확인 | `:checkhealth nvim-treesitter` |
| 현재 위치 구조 보기 | `:InspectTree` (내장) |

- parser 설치에는 `tree-sitter` CLI와 C compiler(gcc)가 필요하다. Windows는 `winget install tree-sitter.tree-sitter-cli`. Linux는 [GitHub release](https://github.com/tree-sitter/tree-sitter/releases)의 `tree-sitter-linux-x64.gz`를 풀어 PATH에 둔다.
- `tree-sitter` CLI가 없으면 시작할 때 "tree-sitter CLI 없음" 경고만 한 번 뜨고 parser 설치는 건너뛴다 (구문 강조는 Neovim 기본 parser가 있는 언어만).

## 에러·경고 (Diagnostics)

LSP가 찾은 에러·경고는 줄 끝에 `● 메시지`로, 줄 번호 옆에 아이콘으로 표시된다 (심각한 것 우선).
메시지는 Insert 모드를 벗어날 때 갱신된다. 상태바에 개수가 표시된다.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `]d` / `[d` | 다음 / 이전 에러로 이동 + 전체 메시지 창 (내장) |
| N | `]D` / `[D` | 마지막 / 처음 에러로 이동 (내장) |
| N | `<Space>ee` | 커서 위치 에러 메시지 창 (내장 `<C-w>d`와 같음) |
| N | `<Space>ed` | 현재 파일 에러 목록 (검색 창) |
| N | `<Space>eD` | 열린 파일 전체 에러 목록 (검색 창) |
| N | `<Space>et` | 에러 표시 켜기 / 끄기 |

- 메시지 창은 커서를 움직이면 닫힌다.
- 줄 끝 메시지가 길어 잘리면 `]d`나 `<Space>ee`로 전체를 본다.

### 메시지 혼합 번역

자주 나오는 메시지는 "쉬운 용어는 영어, 어려운 말은 한국어"로 바꿔 보여 준다.

```
원문: Type 'string' is not assignable to type 'number'.
표시: 'string' type을 'number' type에 할당할 수 없음
```

| 위치 | 보이는 내용 |
|---|---|
| 줄 끝 | 번역만 |
| 메시지 창 (`]d`, `<Space>ee`) | 번역 + 아래에 영어 원문 (검색용) |
| 목록 (`<Space>ed`, `<Space>eD`) | 영어 원문 |

- 규칙에 없는 메시지는 영어 원문 그대로 나온다.
- 규칙 추가: `lua/sinbin/diagnostics/rules_ko.lua`에 `{ "원문 Lua pattern", "치환문" }` 한 줄 추가. 메시지 창의 영어 원문을 복사해 패턴으로 만들면 된다 (`.`, `(`, `)`, `-`, `?` 앞에는 `%`). 구체적인 패턴을 일반 패턴보다 위에 둔다.

## Git (gitsigns, diffview, lazygit)

git 저장소의 파일을 열면 줄 번호 옆에 변경 표시(`┃` 추가·변경, `_` 삭제)가 나오고,
커서 줄 끝에 `작성자, 언제 - 커밋 메시지`가 흐리게 표시된다. 상태바에 브랜치와 변경 수가 보인다.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `]h` / `[h` | 다음 / 이전 변경 묶음(hunk) |
| N | `<Space>gp` | hunk 미리보기 창 (바뀌기 전 / 후) |
| N, V | `<Space>gs` | hunk stage (V는 선택한 줄만). stage된 hunk에서 누르면 unstage |
| N, V | `<Space>gr` | hunk 되돌리기 (V는 선택한 줄만) |
| N | `<Space>gS` / `<Space>gR` | 파일 전체 stage / 되돌리기 |
| N | `<Space>gb` | 커서 줄 blame 자세히 (커밋 전체 메시지) |
| N | `<Space>gd` | 파일 diff 화면 (좌우 비교, 다시 누르면 닫기) |
| N | `<Space>gv` | **전체 변경 검토** (변경된 파일 목록 + 좌우 비교, 다시 누르거나 `q`로 닫기) |
| N | `<Space>gl` | **현재 파일 변경 이력** (커밋 목록 + 커밋별 diff, `q`로 닫기) |
| N | `<Space>gh` | 변경된 hunk 목록 (검색 창) |
| N | `<Space>gc` / `<Space>gB` | 커밋 / 브랜치 목록 (검색 창) |
| N | `<Space>gg` | lazygit (commit, push, 브랜치 등 전체 Git 작업) |

### 전체 변경 검토 화면 (`<Space>gv`) 안에서

| 키 | 동작 |
|---|---|
| `<Tab>` / `<S-Tab>` | 다음 / 이전 파일 diff |
| `j` / `k`, `<CR>` | 파일 목록에서 이동, 선택한 파일 diff 열기 |
| `-` 또는 `s` / `S` | 파일 stage·unstage / 전체 stage |
| `X` | 파일 변경 되돌리기 |
| `g?` | 도움말 |
| `q` | 닫기 |

### lazygit 기본 조작

| 키 | 동작 |
|---|---|
| `?` | 현재 화면에서 쓸 수 있는 키 목록 |
| `1`~`5` 또는 마우스 | 패널 이동 (Status, Files, Branches, Commits, Stash) |
| `space` | 파일 stage / unstage |
| `c` | commit (메시지 입력) |
| `P` / `p` | push / pull |
| `enter` | 파일·커밋 상세 (diff) |
| `q` | 종료 (Neovim으로 돌아옴) |

- `<Space>gv` / `<Space>gl` / `<Space>gh` / `<Space>gc` / `<Space>gB`를 쓸 수 없는 상황이면 이유를 알려 준다: `git 저장소 아님`, `파일 버퍼 아님`, `커밋 이력 없음 (아직 commit 안 된 파일)`.
- 외부 도구: lazygit. Windows는 `winget install JesseDuffield.lazygit`.
- lazygit을 닫으면 열린 파일이 자동으로 다시 읽힌다 (checkout, reset 등 반영).

## Terminal

Neovim 안에서 Shell을 연다 (Windows는 Git Bash). 숨겨도 실행 중인 명령(dev server 등)은 계속 돈다.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `<Space>tt` | 하단 패널에 Terminal 열기 / 이동 / 숨기기 ([창 규칙](#창-이동), 다른 Terminal이 보이는 중이면 그 자리에서 전환) |
| N | `<Space>tp` / N·T `` Alt+` `` | 하단 패널 전체 열기 / 이동 / 숨기기 |
| N | `2<Space>tt`, `3<Space>tt` … | 2번, 3번 Terminal (따로 동작) |
| N | `<Space>tf` | floating Terminal 열기 / 숨기기 (잠깐 명령 하나 실행할 때) |
| 마우스 | 하단 패널 위쪽 탭 클릭 | 그 Terminal / Run으로 전환 |
| T | `<C-q>` | Terminal 입력 → Normal 모드 (스크롤, 복사). 창 이동은 입력 중에도 `Alt+h/j/k/l` |
| N (Terminal 창) | `i` 또는 `a` | 다시 Terminal 입력 (다른 창에서 들어오면 자동) |

- 하단 Terminal과 Run 결과는 하단 패널 창 하나를 같이 쓰고, 패널 위쪽 탭(`Terminal 1  Terminal 2  run: ...`)으로 보인다.
- Shell에서 `exit`하면 그 Terminal이 닫힌다 (패널에 다른 Terminal이 있으면 그것을 보여 줌).
- `<Esc>`는 Terminal 안 프로그램(Claude Code, lazygit 등)에 그대로 전달된다.
- Windows Shell은 Git Bash. nvim을 PowerShell에서 실행해도 같다. Neovim의 `:!` 명령은 어디서 실행하든 `cmd.exe`.
- Linux / macOS / WSL Shell은 `$SHELL` (보통 bash / zsh).

## Run / Test

**소문자 = 현재 파일, 대문자 = 프로젝트.** 결과는 하단 "run" Terminal에 나온다.
- 파일 명령(`rr`/`rb`/`xf`): 커서가 run Terminal로 가서 바로 입력할 수 있다 (`input()` 같은 입력 받는 코드). 끝나면 Normal 모드가 되어 출력을 그대로 볼 수 있고, `<C-w>k`로 코드 창에 돌아간다.
- 프로젝트 명령(`rR`/`rB`/`xx`): 커서는 편집하던 창에 남는다 (dev server를 띄워 두고 계속 편집).
실행할 때마다 알림에 `▶ 명령  (폴더/)`가 떠서 무엇이 어디서 도는지 보인다.

| 대상 | 키 | 동작 |
|---|---|---|
| 현재 파일 | `<Space>rr` | 이 파일 실행 |
| 현재 파일 | `<Space>rb` | 이 파일 빌드(컴파일) |
| 현재 파일 | `<Space>xf` | 이 파일 테스트 |
| 프로젝트 | `<Space>rR` | 프로젝트 실행 (dev server, 앱) |
| 프로젝트 | `<Space>rB` | 프로젝트 빌드 |
| 프로젝트 | `<Space>xx` | 프로젝트 전체 테스트 |
| | `<Space>rl` | 마지막 명령 다시 실행 |
| | `<Space>rs` | 실행 중인 명령 중지 |
| | `<Space>rt` | 쓸 수 있는 명령 목록 (`[파일]` / `[프로젝트]`) → 골라 실행 |

### 현재 파일 명령

| 파일 | `rr` 실행 | `rb` 빌드 | `xf` 테스트 |
|---|---|---|---|
| Python | `python 파일` | 없음 (컴파일 언어 아님) | `python -m pytest 파일` |
| C | gcc 컴파일 후 실행 | `gcc` 컴파일 (실행 파일은 소스 옆) | 없음 |
| JavaScript | `node 파일` | 없음 | `test -- 파일` (package.json에 test script 있을 때) |
| TypeScript | `node --experimental-transform-types 파일` (Node 22) | 없음 (타입 검사는 LSP) | 위와 같음 |
| TSX / JSX | 단독 실행 안 됨 → `<Space>rR` | 없음 | 위와 같음 |
| Dart | `dart run 파일` | `dart compile exe 파일` | `dart test 파일` |
| Dart (Flutter 프로젝트) | `flutter run -t 파일` | 없음 | `flutter test 파일` |
| Java (Maven 프로젝트) | 이 클래스의 `main` 실행 (`mvn exec:java`) | 없음 | `mvn test -Dtest=클래스` |
| Java (단일 파일) | `java 파일` | 없음 | 없음 |

- TypeScript 파일 실행은 단일 파일용. 확장자 없이 다른 `.ts`를 import하는 코드는 프로젝트 script(`<Space>rR`)로 실행.
- 첫 Maven 실행은 plugin 다운로드로 오래 걸릴 수 있다.

### 프로젝트 명령

현재 파일에서 가장 가까운 프로젝트 파일 기준. front/back처럼 프로젝트가 여러 개면 열려 있는 파일이 속한 쪽.

| 프로젝트 (가장 가까운 파일) | `rR` 실행 | `rB` 빌드 | `xx` 테스트 |
|---|---|---|---|
| `package.json` (도구 선택은 아래) | `dev`, 없으면 `start` script | `build` script | `test` script |
| `pubspec.yaml` (Flutter) | `flutter run` (기기 선택) | `<Space>rt`에서 대상 선택 | `flutter test` |
| `pubspec.yaml` (Dart) | `dart run` | 없음 | `dart test` |
| `pom.xml` | Spring Boot면 `mvn spring-boot:run` | `mvn package` | `mvn test` |
| `pyproject.toml` / `requirements.txt` / `setup.py` | 루트의 `main.py` / `app.py` / `manage.py runserver` | 없음 | `python -m pytest` |
| `Makefile` / `CMakeLists.txt` | 없음 | `make` / `cmake --build` (make, cmake 설치 필요) | `make test` |

- Node 도구 선택: package.json의 `packageManager` → lock 파일(pnpm → yarn → bun → npm 순) 중 **설치된 도구**만 → 없으면 npm. 건너뛴 이유는 표시된다 (예: `node (npm; yarn.lock 있지만 도구 미설치)`).
- 파일이 아닌 화면(`nvim .`의 탐색기, 시작 화면, Terminal 창)에서는 **현재 작업 폴더** 기준. 작업 폴더에 프로젝트 파일이 없으면 한 단계 아래 폴더들에서 찾아 **어느 프로젝트를 실행할지 고르는 목록**을 띄운다 (예: front / back).
- 작업 폴더는 탐색기에서 `g.`로 바꿀 수 있다 (탐색기 표). 지금 작업 폴더는 `:pwd`.
- 명령이 없으면 이유를 알려 준다 (예: `Python은 빌드 없음`, `프로젝트 감지 안 됨 (파일 실행: <Space>rr)`).
- "run" Terminal은 하단 패널의 `Run` 탭으로 다시 볼 수 있다 (`<Space>tp`).

### 프로젝트별로 명령 바꾸기 (`.sinbin/run.json`)

프로젝트 루트에 `.sinbin/run.json`을 두면 적은 항목만 이 명령으로 바뀐다. 명령은 Shell 명령 한 줄 (Windows는 Git Bash).
`run` / `build` / `test`는 프로젝트, `run_file` / `build_file` / `test_file`은 현재 파일용 (`{file}`은 현재 파일 경로).

```json
{
  "run": "pnpm run dev -- --port 3001",
  "build": "pnpm run build",
  "test": "pnpm vitest run",
  "test_file": "pnpm vitest run {file}"
}
```

- 키를 누르면 이 파일의 명령이 그대로 실행되므로, 믿을 수 있는 저장소에서만 쓴다.

## Debug (nvim-dap)

breakpoint를 걸고 시작하면 하단에 디버그 패널이 열리고(하단 패널이 열려 있으면 그 오른쪽 절반, 끝나면 자동으로 닫힘), 멈춘 동안 코드 줄 끝에 변수 값(`total = 3`)이 보인다.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `<Space>db` | breakpoint 켜기 / 끄기 (줄 번호 옆 빨간 점) |
| N | `<Space>dB` | 조건부 breakpoint (예: `i == 2`) |
| N | `<Space>dc` 또는 `F5` | 디버그 시작 (방식이 여러 개면 목록에서 선택) / 멈춘 상태면 계속 |
| N | `<Space>dn` 또는 `F10` | 다음 줄 (함수 안으로 안 들어감) |
| N | `<Space>di` 또는 `F11` | 함수 안으로 들어가기 |
| N | `<Space>do` 또는 `F12` | 함수 밖으로 나가기 |
| N | `<Space>dq` | 디버그 종료 |
| N | `<Space>du` | 디버그 패널 열기 / 이동 / 닫기 ([창 규칙](#창-이동)) |
| N, V | `<Space>de` | 커서 아래(또는 선택한) 식의 값 보기 |

- Windows Terminal은 `F11`을 전체 화면 전환에 쓰므로 Neovim에 전달되지 않을 수 있다 → `<Space>di` 사용.
- 디버그 패널 위쪽 탭: Scopes(변수, `S`), Watches(`W`), Breakpoints(`B`), Threads(`T`), Exceptions(`E`), REPL(`R`), Console(`C`, 프로그램 출력·입력). 패널 안에서 `<CR>`로 펼치기.

| 언어 | 디버그 방식 (`F5` 목록) | 필요한 것 |
|---|---|---|
| C | 현재 파일 (`gcc -g`로 컴파일 후 gdb) / 실행 파일 지정 | MSYS2 gdb (설치됨) |
| Python | 현재 파일 / pytest 현재 파일 | `:MasonInstall debugpy` |
| JavaScript / TypeScript | 현재 파일 (Node, TS는 Node 22 TS 실행) / 실행 중인 node 프로세스에 attach | `:MasonInstall js-debug-adapter` |
| Dart | 현재 파일 | Dart/Flutter SDK |
| Flutter | Flutter 앱 (Windows) / Flutter 앱 (Chrome) — `lib/` 안 파일이면 그 파일, 아니면 `lib/main.dart` | Flutter SDK. 첫 실행은 빌드로 오래 걸림 |
| Java | 현재 클래스 (`main` 메서드) | `:MasonInstall java-debug-adapter` 후 nvim 재시작. jdtls가 프로젝트를 다 불러온 뒤 시작 |

- 프로젝트에 `.vscode/launch.json`이 있으면 그 설정도 `F5` 목록에 나온다.
- 필요한 것이 없으면 이유를 알려 준다 (예: `lua 디버그 설정 없음`).

## AI Agent (Claude Code, Codex)

Agent는 Neovim과 별개 프로그램(CLI) 그대로 오른쪽 영역에서 돈다. 오른쪽 영역은 창 하나에 Terminal·Claude Code·Codex가 탭으로 있고(시작 시 Terminal), Agent를 켜면 같은 창의 새 탭으로 열린다. 숨겨도 대화는 이어진다.

| 모드 | 키 | 동작 |
|---|---|---|
| N, T | `Alt+a` | **코드 창 ↔ 오른쪽 영역 왕복.** 코드에서 누르면 오른쪽 영역에 보이는 것(Terminal / Agent)으로 가서 바로 입력. 숨겨져 있으면 실행 중인 Agent → 오른쪽 Terminal 순으로 다시 열고, 아무것도 없으면 마지막 Agent(처음엔 Claude) 실행. 오른쪽 영역에서 누르면 원래 코드 창으로 |
| N | `<Space>ac` | Claude Code 열기 / 이동 / 숨기기 ([창 규칙](#창-이동)) |
| N | `<Space>ax` | Codex 열기 / 이동 / 숨기기 |
| N | `<Space>at` | 오른쪽 영역 Terminal 열기 / 이동 / 숨기기 |
| N, T / N | `Alt+z` / `<Space>az` | **오른쪽 영역 전체 화면** ↔ 원래 배치 (위쪽 탭 바·상태바는 보임, 오른쪽 영역 탭 그대로, 폭은 원래대로 돌아옴). 전체 화면에서 `Alt+a`는 전체 화면을 끝내고 코드 창으로 |
| N | `<Space>af` | 현재 파일을 Agent 입력창에 넣기 (`@경로 `) |
| V | `<Space>as` | 선택한 줄 범위를 Agent 입력창에 넣기 (`@경로#L10-20 `) |

- `<Space>af` / `<Space>as`는 입력만 하고 Enter는 누르지 않는다. 커서가 Agent로 옮겨 가니 이어서 질문을 쓰면 된다. 예: `@src/user.ts#L10-20 이 함수 리팩터링해줘`
- Agent 창 안: `<Esc>`는 Agent에 전달된다. 코드 창으로는 `Alt+a` 또는 `Alt+h`. 쓰던 입력은 Agent 창에 그대로 남는다.
- Agent는 현재 파일의 git 저장소 루트에서 시작한다 (없으면 작업 폴더).
- Agent가 파일을 고치면 열린 버퍼가 자동으로 다시 읽힌다. 바뀐 내용은 `<Space>gv`(전체 변경 검토), `]h` / `<Space>gp`(변경 묶음)로 본다.
- Codex는 폴더를 처음 열 때 "Trust this folder?" 확인이 나온다.

## 설정 패널

`<Space>,` / `:Settings` / 시작 화면 `c`로 연다. 화면 가운데 창에 항목과 현재 값이 보이고, 바꾸면 바로 적용·저장된다.

| 키 (패널 안) | 동작 |
|---|---|
| `j` / `k` (화살표) | 항목 이동 |
| `<CR>` / `Space` | 켜기·끄기, 다음 값, 고급 항목 실행 |
| `l` / `h` (화살표) | 다음 / 이전 값 |
| `q` / `<Esc>` | 닫기 |

| 분류 | 항목 |
|---|---|
| 화면 | 색 테마 moon / storm / night, 배경 투명(터미널이 반투명일 때 비침), 상대 줄 번호, 현재 줄 강조, 공백 문자 표시, 긴 줄 줄바꿈 |
| 편집 | 들여쓰기 폭 2 / 4 / 8, 들여쓰기 문자 Spaces / Tab (둘 다 새로 여는 파일부터), 검색 대소문자, 커서 위아래 여백, 자동 저장 |
| IDE | 시작 시 Terminal / 시작 시 Agent (재시작 후), 줄 끝 Git blame, 에러·경고 표시, 한/영 자동 전환, Outline에서 움직이면 코드도 이동 (Outline 다시 열 때) |
| 시작 화면 | 시작 화면 사용 (재시작 후), 로고 gradient, Tip 표시, 최근 프로젝트 개수 0~5 |
| Agent | 기본 Agent Claude Code / Codex (`Alt+a`·시작 시 Agent), 패널 폭 30 / 40 / 50%, 이전 대화 이어서 시작 (`claude --continue` / `codex resume --last`, 다음 Agent 시작부터) |
| 고급 | 설정 파일 열기, Plugin / LSP / Treesitter 상태 (`:checkhealth`, 새 탭 페이지, `q`로 닫기), 설정 초기화 (확인 후) |

- 저장 위치: `stdpath('data')/sinbin/settings.json` (Windows `%LOCALAPPDATA%\nvim-data\sinbin\settings.json`), 기본값과 다른 값만. 저장소 밖이라 장비마다 따로.
- 파일을 직접 고쳐 저장(`:w`)해도 바로 다시 읽는다. 잘못된 값은 무시하고 기본값, JSON이 깨지면 알림 후 전부 기본값.
- 자동 저장: Insert 모드를 벗어날 때, 다른 버퍼로 갈 때, Neovim이 포커스를 잃을 때 바뀐 파일을 저장.
- 시작 시 Agent를 켜면 오른쪽 영역에 기본 Agent가 실행된다 (커서는 코드 창). "이전 대화 이어서"는 그 폴더에 이전 대화가 없으면 Agent CLI가 알려 준다.
- `<Space>et`(에러 표시 토글)는 저장하지 않는 일시 전환. 다음 실행에는 설정 패널 값.

## 명령

| 명령 | 동작 |
|---|---|
| `:Settings` | 설정 패널 열기 (`<Space>,`) |
| `:Setup` | 설치 / 점검 스크립트(`setup.ps1`)를 새 탭 Terminal에서 실행 (시작 화면 `s`). Plugin이 없어도 동작 |
| `:TrimWhitespace` | 버퍼 전체의 줄 끝 공백 삭제 (커서 위치 유지) |
| `:'<,'>TrimWhitespace` | 선택 범위만 삭제 (Visual에서 `:` 입력 후) |

- 저장할 때 자동으로 지우지 않는다. 남의 파일을 열어 저장해도 diff가 생기지 않게 하려는 것.

## 자동으로 동작하는 것

| 기능 | 내용 |
|---|---|
| Yank 하이라이트 | 복사한 영역이 잠깐 강조됨 |
| 커서 위치 복원 | 파일을 다시 열면 마지막 편집 위치로 이동 (git commit/rebase 메시지 제외) |
| 공백 표시 | 탭 `»`, 줄 끝 공백 `·`, non-breaking space `␣` |
| 현재 줄 강조 | 커서가 있는 줄 배경 강조 |
| 긴 줄 | 단어 단위로 화면 줄바꿈, 줄바꿈된 부분도 들여쓰기 유지 (파일 내용은 그대로) |
| 치환 미리보기 | `:s` / `:%s` 입력 중 결과를 미리 보여주고 아래 창에 변경 줄 목록 표시 |
| 클립보드 | `y` / `p`가 시스템 클립보드와 공유 |
| Undo 유지 | 파일을 닫았다 열어도 `u`로 이전 변경 되돌리기 가능 |
| 검색 | 소문자로만 검색하면 대소문자 무시, 대문자가 섞이면 구분 |
| 색 테마 | tokyonight `moon` (네온 계열 다크). [설정 패널](#설정-패널)에서 `storm`/`night`, 배경 투명 |
| 시작 화면 | 파일 없이 `nvim` 실행 시 SINBIN 로고·메뉴·최근 프로젝트 표시. 키 한 글자로 바로 실행: `f` 파일 찾기 / `g` 내용 검색 / `e` 파일 탐색기 / `c` 설정 패널 / `s` 설치 / 점검(`:Setup`) / `q` 종료, `1`~`5` 최근 프로젝트로 작업 폴더 변경. 위아래 화살표 + `<CR>`도 됨. 아래에 Plugin 수·시작 시간·Tip 하나 (창이 좁으면 로고 대신 `SinBin IDE` 한 줄) |
| 최근 프로젝트 | 작업 폴더가 바뀔 때마다(시작 폴더, 탐색기 `g.`, `:cd`) 기록. 홈 폴더 제외, 최근 10개를 `stdpath('data')/sinbin/projects.txt`에 저장 |
| 외부 수정 반영 | Agent·git 등이 파일을 바꾸면 Neovim으로 돌아올 때 자동으로 다시 읽음 (수정 중인 버퍼는 확인 메시지) |
| 알림 | 메시지가 오른쪽 위 창에 잠깐 표시. LSP 진행 상황(로딩·분석 중)은 표시하지 않음. 지난 알림은 `:lua MiniNotify.show_history()` |

## Plugin 관리

| 작업 | 방법 |
|---|---|
| 추가 | `lua/sinbin/plugins/init.lua`의 `vim.pack.add({ ... })`에 항목 추가 후 Neovim 재시작 (설치 확인 prompt 표시) |
| 업데이트 | `:lua vim.pack.update()` → 확인 buffer에서 `:write`로 적용 |
| 제거 | 목록에서 지운 뒤 `:lua vim.pack.del({ "이름" })` |
| 상태 확인 | `:checkhealth vim.pack` |

- 버전은 `nvim-pack-lock.json`에 기록되며 git으로 관리한다 (직접 수정 금지).
- 설치 위치는 Repository 밖 (`stdpath('data')/site/pack/core/opt`).
