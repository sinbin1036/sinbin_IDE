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
nvim .             현재 디렉터리 목록 열기 (내장 파일 탐색기 netrw)
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

## 설치된 Plugin

| Plugin | 하는 일 | 설정 위치 |
|---|---|---|
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | 괄호·따옴표 자동 닫기 | `lua/sinbin/plugins/editing.lua` |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | 감싸는 문자 추가·삭제·교체 | `lua/sinbin/plugins/editing.lua` |
| [mini.pick](https://github.com/nvim-mini/mini.pick) | 파일·내용·버퍼·도움말 검색 창 | `lua/sinbin/plugins/search.lua` |
| [mini.extra](https://github.com/nvim-mini/mini.extra) | 추가 검색 창 (최근 파일) | `lua/sinbin/plugins/search.lua` |
| [mini.files](https://github.com/nvim-mini/mini.files) | 파일 탐색기 (폴더를 버퍼처럼 편집) | `lua/sinbin/plugins/search.lua` |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | 색 테마 (`moon`) | `lua/sinbin/plugins/ui.lua` |
| [mini.icons](https://github.com/nvim-mini/mini.icons) | 파일 아이콘 (Nerd Font 필요) | `lua/sinbin/plugins/ui.lua` |
| [mini.statusline](https://github.com/nvim-mini/mini.statusline) | 하단 상태바 | `lua/sinbin/plugins/ui.lua` |
| [mini.clue](https://github.com/nvim-mini/mini.clue) | 키 힌트 창 | `lua/sinbin/plugins/ui.lua` |
| [mini.notify](https://github.com/nvim-mini/mini.notify) | 알림 창 (오른쪽 위) | `lua/sinbin/plugins/ui.lua` |
| [mini.starter](https://github.com/nvim-mini/mini.starter) | 시작 화면 (파일 없이 `nvim` 실행 시) | `lua/sinbin/plugins/ui.lua` |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | 언어 Server 설정 모음 | `lua/sinbin/plugins/lsp.lua` |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | 언어 Server 설치 (`:Mason`) | `lua/sinbin/plugins/lsp.lua` |
| [mini.completion](https://github.com/nvim-mini/mini.completion) | 자동완성 목록, 문서 창, 인자 힌트 | `lua/sinbin/plugins/lsp.lua` |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 구문 분석기(parser) 설치·업데이트 | `lua/sinbin/plugins/treesitter.lua` |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | git 변경 표시, hunk, inline blame | `lua/sinbin/plugins/git.lua` |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | 디버거 연결 (DAP) | `lua/sinbin/plugins/debug.lua` |
| [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view) | 디버그 패널, 줄 끝 변수 값 | `lua/sinbin/plugins/debug.lua` |
| [diffview-plus.nvim](https://github.com/dlyongemallo/diffview-plus.nvim) | 여러 파일 변경 검토, 파일 이력 (diffview.nvim 유지보수 fork) | `lua/sinbin/plugins/git.lua` |

Plugin 관리는 Neovim 내장 `vim.pack` ([D-007](DECISIONS.md)). 아래 [Plugin 관리](#plugin-관리) 참조.

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
| N | `<Space>fe` | 파일 탐색기 열기 / 닫기 (현재 파일 위치에서 열림) |
| N | `<Space>sg` | 프로젝트 내용 검색 (입력하는 대로 결과 갱신) |
| N | `<Space>sw` | 커서 아래 단어로 내용 검색 |
| N | `<Space>sh` | 도움말 검색 |
| N | `<Space>sr` | 마지막 검색 창 다시 열기 |

`<Space>`만 누르고 기다리면 가능한 키 목록이 아래에 뜬다 (mini.clue). `g`, `z`, `[`, `]`, `<C-w>`, `"`, `'`도 같다.

### 검색 창 안에서

| 키 | 동작 |
|---|---|
| 글자 입력 | 결과 좁히기 (fuzzy) |
| `<C-n>` / `<C-p>` | 아래 / 위 항목 |
| `<CR>` | 열기 |
| `<C-v>` / `<C-s>` / `<C-t>` | 세로 분할 / 가로 분할 / 새 탭으로 열기 |
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
| `g?` | 도움말 |
| `q` | 닫기 |

- 탐색기에서 편집만 하고 `=`를 누르지 않으면 디스크는 바뀌지 않는다.
- 기본 탐색기 netrw(`:Ex`)도 그대로 쓸 수 있다.

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
- snippet 항목(`S` 표시)은 입력 후 `<Tab>` / `<S-Tab>`으로 다음 칸 이동 (내장 `vim.snippet`).

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

- parser 설치에는 `tree-sitter` CLI와 C compiler(gcc)가 필요하다. Windows는 `winget install tree-sitter.tree-sitter-cli`.

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
| N | `<Space>eq` | 에러를 quickfix 목록으로 → `]q` / `[q`로 이동, `:copen`으로 목록 창 |
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
| 목록 (`<Space>ed`, `<Space>eq`) | 영어 원문 |

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
| N | `<Space>tt` | 하단 Terminal 열기 / 숨기기 |
| N | `2<Space>tt`, `3<Space>tt` … | 2번, 3번 Terminal (따로 동작) |
| N | `<Space>tf` | floating Terminal 열기 / 숨기기 (잠깐 명령 하나 실행할 때) |
| N | `<Space>tl` | 열린 Terminal 목록 → 골라서 하단에 표시 |
| T | `<C-q>` | Terminal 입력 → Normal 모드 (스크롤, 복사, `<C-w>`로 창 이동) |
| N (Terminal 창) | `i` 또는 `a` | 다시 Terminal 입력 |

- Shell에서 `exit`하면 그 Terminal 창과 버퍼가 닫힌다.
- `<Esc>`는 Terminal 안 프로그램(Claude Code, lazygit 등)에 그대로 전달된다.
- Windows Shell은 Git Bash. nvim을 PowerShell에서 실행해도 같다 (Neovim의 `:!` 명령은 기존 'shell' 그대로).

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
- "run" Terminal은 `<Space>tl` 목록에서 다시 볼 수 있다.

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

breakpoint를 걸고 시작하면 하단에 디버그 패널이 열리고(끝나면 자동으로 닫힘), 멈춘 동안 코드 줄 끝에 변수 값(`total = 3`)이 보인다.

| 모드 | 키 | 동작 |
|---|---|---|
| N | `<Space>db` | breakpoint 켜기 / 끄기 (줄 번호 옆 빨간 점) |
| N | `<Space>dB` | 조건부 breakpoint (예: `i == 2`) |
| N | `<Space>dc` 또는 `F5` | 디버그 시작 (방식이 여러 개면 목록에서 선택) / 멈춘 상태면 계속 |
| N | `<Space>dn` 또는 `F10` | 다음 줄 (함수 안으로 안 들어감) |
| N | `<Space>di` 또는 `F11` | 함수 안으로 들어가기 |
| N | `<Space>do` 또는 `F12` | 함수 밖으로 나가기 |
| N | `<Space>dq` | 디버그 종료 |
| N | `<Space>du` | 디버그 패널 열기 / 닫기 |
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

## 명령

| 명령 | 동작 |
|---|---|
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
| 색 테마 | tokyonight `moon` (네온 계열 다크). 바꾸려면 `ui.lua`의 `style`을 `storm`/`night`로 |
| 시작 화면 | 파일 없이 `nvim` 실행 시 최근 파일·메뉴 표시. 글자 입력으로 좁히고 `<CR>` |
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
