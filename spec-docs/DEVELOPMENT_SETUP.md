# OKRBEST Desktop 개발 환경 설정 가이드

> Windows 11(네이티브 / WSL Ubuntu) 및 macOS에서의 개발 환경 설정 방법

---

## 목차

1. [시스템 요구사항](#1-시스템-요구사항)
2. [환경 선택 가이드](#2-환경-선택-가이드)
3. [Windows 11 네이티브 환경 설정](#3-windows-11-네이티브-환경-설정)
4. [Windows 11 + WSL Ubuntu 환경 설정](#4-windows-11--wsl-ubuntu-환경-설정)
5. [macOS 환경 설정](#5-macos-환경-설정)
   - [Python 버전 관리 (uv)](#python-버전-관리-uv) — 모든 플랫폼 공통
   - [E2E 테스트 환경](#e2e-테스트-환경) — Playwright 기반
6. [공통 프로젝트 설정](#6-공통-프로젝트-설정)
7. [개발 명령어](#7-개발-명령어)
8. [문제 해결](#8-문제-해결)
9. [개발 팁](#9-개발-팁)
10. [빠른 시작 요약](#10-빠른-시작-요약)
11. [프로덕션 빌드 및 패키징](#11-프로덕션-빌드-및-패키징)

---

## 1. 시스템 요구사항

### 1.1 공통 요구사항

| 항목 | 요구사항 |
|------|----------|
| **Node.js** | >= 18.0.0 (권장: **v20.15.0**, 프로젝트 [.nvmrc](../.nvmrc)) |
| **npm** | Node.js에 포함 (≥ 10.x) |
| **Git** | 최신 안정 버전 |
| **Electron** | [package.json](../package.json) `devDependencies.electron` (npm install 시 자동) |

### 1.2 플랫폼별 요구사항

| 플랫폼 | 요구사항 |
|--------|----------|
| **Windows 11 네이티브** | PowerShell 7+ (또는 5.1), nvm-windows, Visual Studio Build Tools 2022 (C++ 워크로드) |
| **Windows 11 + WSL2** | Ubuntu 22.04+, WSLg(기본 포함), 빌드 도구 |
| **macOS** | macOS 11(Big Sur) 이상, Xcode Command Line Tools |

---

## 2. 환경 선택 가이드

이 프로젝트는 **OS별로 다른 코드 경로**가 존재합니다 (Windows: Focus Assist·AppUserModelId·MSI/NSIS, macOS: tccutil·entitlements·MAS, Linux: AppImage·deb·rpm). dev 사이클 속도와 검증 가능 영역의 트레이드오프가 있어, 작업 성격에 맞게 환경을 고르는 것이 효율적입니다.

| 옵션 | 환경 | dev 사이클 | 검증 가능 | 비고 |
|---|---|---|---|---|
| **A. WSL Ubuntu** | WSLg + `npm run watch` | 빠름 | OS-중립 영역, Linux 분기 | Windows/Mac 전용 기능 동작 불가 |
| **B. Windows 네이티브** | PowerShell + `npm run watch` | 빠름 | Windows 전용 기능 + OS-중립 | 별도 Node·node_modules 필요 |
| **C. macOS 네이티브** | Terminal + `npm run watch` | 빠름 | macOS 전용 기능 + OS-중립 | macOS 호스트 필수 |
| **D. WSL → Windows 패키지 빌드 → Windows 실행** | `npm run package:windows-zip` | 느림 (1~3분) | NSIS/MSI 설치, 코드 사이닝 | dev tools/HMR 없음 |

### 2.1 권장 워크플로우

- **일상 개발 (UI/로직/테스트)**: WSL Ubuntu 또는 macOS에서 `npm run watch`. 빠른 반복.
- **Windows 전용 코드 변경**: [src/main/notifications/dnd-windows.ts](../src/main/notifications/dnd-windows.ts), [src/main/AutoLauncher.ts](../src/main/AutoLauncher.ts) 의 Windows 분기, AppUserModelId, 트레이/점프리스트 등을 만지면 → Windows 네이티브 환경으로 전환해 실행.
- **macOS 전용 코드 변경**: [src/main/utils.ts](../src/main/utils.ts) 의 `tccutil`, MAS entitlements, dock badge 등 → macOS 호스트 필수.
- **릴리스 직전 검증**: 각 OS별 패키지를 빌드해 설치/서명/실행 동작 확인.

---

## 3. Windows 11 네이티브 환경 설정

WSL이 아닌 **Windows 호스트에서 직접 개발/빌드**할 때의 절차. Windows 전용 기능(Focus Assist, AppUserModelId, MSI/NSIS 등)을 검증하려면 이 환경이 필요합니다.

> **WSL과의 핵심 차이**: WSL Ubuntu에서는 `windows-focus-assist`·`registry-js`·`cf-prefs` 같은 Windows 전용 네이티브 모듈이 stub/no-op로 우회되어 컴파일이 사실상 생략됩니다. 반면 Windows 네이티브에서는 이 모듈들이 **실제 Win32 API 코드를 직접 컴파일**해야 하므로 Python + Visual Studio C++ 빌드 도구가 *모두* 필요합니다. 이 차이 때문에 같은 Node 20.15.0이라도 WSL에서는 통과한 `npm install`이 Windows에서 실패하는 경우가 흔합니다 — 거의 모두 [§3.5](#35-네이티브-모듈-빌드-도구-python--visual-studio-build-tools) 와 [§8.2](#82-windows-11-네이티브) 의 문제로 귀결됩니다.

### 3.1 기존 Node.js 제거

기존에 Node를 직접 설치했다면 nvm-windows와 충돌합니다. 먼저 깨끗이 정리:

```powershell
# PowerShell 관리자 권한
# 1) 설정 → 앱 → 설치된 앱 → "Node.js" 제거

# 2) 잔여 폴더/캐시 정리
Remove-Item -Recurse -Force "C:\Program Files\nodejs" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\npm" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:APPDATA\npm-cache" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache" -ErrorAction SilentlyContinue

# 3) PATH 정리 — Win+Pause → 고급 시스템 설정 → 환경 변수
#    시스템·사용자 PATH에서 다음 항목이 있으면 제거:
#    - C:\Program Files\nodejs\
#    - %APPDATA%\npm
```

확인 (새 PowerShell 세션):
```powershell
Get-Command node    # 'not recognized' 나오면 정상
```

### 3.2 nvm-windows 설치

> Linux/Mac의 `nvm`과 다른 프로젝트(`coreybutler/nvm-windows`). 명령어는 거의 호환되나 `.nvmrc` 자동 인식 등 일부 기능이 다름.

```powershell
# winget으로 설치 (권장)
winget install CoreyButler.NVMforWindows

# 또는 인스톨러: https://github.com/coreybutler/nvm-windows/releases 에서 nvm-setup.exe
```

설치 검증 (새 PowerShell 세션):
```powershell
nvm version    # 1.1.x 출력
```

### 3.3 Node.js 설치 및 기본 버전 설정

PowerShell **관리자 권한** 필수 (`nvm use`가 `C:\Program Files\nodejs` 심링크를 갱신):

```powershell
nvm install 20.15.0    # 프로젝트 .nvmrc와 일치
nvm use 20.15.0
node --version         # v20.15.0
npm --version
```

`nvm use`로 설정한 버전은 새 셸에서도 유지됩니다 (별도 default 명령 없음).

### 3.4 `.nvmrc` 자동 적용 (선택)

여러 프로젝트를 오갈 때 cd 시 `.nvmrc`를 읽어 자동 전환하려면 PowerShell 프로필에 후크를 추가:

```powershell
# 프로필 파일 열기 (없으면 생성)
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
notepad $PROFILE
```

다음 함수를 프로필에 붙여넣고 저장:

```powershell
# nvm-windows: .nvmrc 자동 적용
function Use-NvmRcIfPresent {
    $dir = Get-Location
    while ($dir -and -not (Test-Path (Join-Path $dir '.nvmrc'))) {
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { return }
        $dir = $parent
    }
    $nvmrc = Join-Path $dir '.nvmrc'
    if (-not (Test-Path $nvmrc)) { return }

    $version = (Get-Content $nvmrc -Raw).Trim().TrimStart('v')
    $current = (& node --version 2>$null) -replace '^v',''
    if ($current -eq $version) { return }

    Write-Host "[nvm] $current -> $version (.nvmrc)" -ForegroundColor Cyan
    & nvm use $version | Out-Null
}

function Set-LocationWithNvm {
    param([Parameter(ValueFromRemainingArguments=$true)] $args)
    Microsoft.PowerShell.Management\Set-Location @args
    Use-NvmRcIfPresent
}
Set-Alias -Name cd -Value Set-LocationWithNvm -Option AllScope -Force
Use-NvmRcIfPresent
```

적용:
```powershell
. $PROFILE       # 또는 새 PowerShell 세션
cd <okrbest-desktop 경로>
# [nvm] 22.x.x -> 20.15.0 (.nvmrc) 출력
```

### 3.5 네이티브 모듈 빌드 도구 (Python + Visual Studio Build Tools)

이 프로젝트는 Windows 전용 네이티브 모듈(`windows-focus-assist`, `registry-js`, `cf-prefs`)을 **소스에서 직접 컴파일**합니다. 따라서 Python과 C++ 빌드 도구가 *모두* 필수입니다. 둘 중 하나라도 빠지면 `npm install` 끝부분에서 `node-gyp rebuild`가 실패합니다.

#### 3.5.1 Python 설치 (uv 권장)

**[uv](https://docs.astral.sh/uv/)** (Astral, Rust 기반)를 통한 설치를 권장합니다. uv가 받은 Python은 `%LOCALAPPDATA%\uv\python\...` 같은 자체 경로에 두므로 **Microsoft Store 앱 실행 별칭에 가로채이지 않고**, Windows·WSL·macOS에서 동일한 워크플로우로 관리됩니다. 자세한 사용법은 [§Python 버전 관리 (uv)](#python-버전-관리-uv) 참조.

```powershell
# uv 설치
winget install astral-sh.uv
# 또는: powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Python 설치 (시스템 PATH에 노출되도록 --default --preview)
uv python install 3.12 --default --preview
```

설치 후 **새 PowerShell 세션**에서 검증:
```powershell
uv python find         # uv가 관리하는 Python 경로 출력
python --version       # 'Python 3.12.x' 출력 (uv-managed)
where.exe python       # %LOCALAPPDATA%\uv\python\... 경로 (Store stub 아님)
```

> **⚠️ 앱 실행 별칭(App Execution Aliases) 비활성화 — uv 사용 여부와 무관하게 권장**
>
> Windows는 `python.exe` 호출을 Microsoft Store 스텁으로 가로채는 기본 설정이 켜져 있습니다. uv가 PATH 우선순위로 자체 Python을 노출시키긴 하지만, 셸 첫 검색 결과가 Store 스텁이 되는 경우가 있어 한 번 꺼두는 게 안전합니다.
>
> **해제**: 설정 → 앱 → 앱 실행 별칭에서 다음 두 항목 **OFF**:
> - `python.exe` (App Installer)
> - `python3.exe` (App Installer)
>
> 끄지 않으면 node-gyp가 다음 오류를 낼 수 있습니다:
> ```
> gyp ERR! find Python - "" could not be run
> gyp ERR! find Python - version is ''
> gyp ERR! find Python - THIS VERSION OF PYTHON IS NOT SUPPORTED
> ```

node-gyp에 uv 관리 Python 경로 명시 등록 (방어용 권장):
```powershell
npm config set python (uv python find)
npm config get python    # 등록된 경로 확인
```

**대안 (uv를 쓰지 않을 경우)**: `winget install Python.Python.3.12` — 단 이 경우 앱 실행 별칭 비활성화가 사실상 필수.

#### 3.5.2 Visual Studio Build Tools

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

설치 마법사에서 **"C++을 사용한 데스크톱 개발"** 워크로드를 선택. (이미 Visual Studio 2022가 설치돼 있으면 같은 워크로드만 추가하면 됨.)

설치 후 검증:
```powershell
# Visual Studio Installer 또는 다음으로 MSBuild 인식 여부 확인
where.exe MSBuild.exe 2>$null
# 출력이 없으면 "Developer PowerShell for VS 2022"를 시작 메뉴에서 실행하거나 시스템 PATH 추가
```

### 3.6 Git for Windows

```powershell
winget install Git.Git
git --version
```

### 3.7 프로젝트 클론 및 설정

> WSL 파일시스템(`\\wsl$\Ubuntu\...`)을 Windows에서 마운트해 쓰면 I/O가 매우 느리고 fsevents·심링크 이슈가 납니다. **반드시 Windows의 NTFS에 별도 클론**하세요.
>
> 또한 **OneDrive 동기화 폴더(예: `Documents\`) 안에 두지 말 것**. OneDrive가 `node_modules` 파일을 잠가서 `npm install` 도중 `EPERM rmdir` 에러를 유발합니다 ([§8.2](#82-windows-11-네이티브) 참조). `D:\projects\` 또는 `C:\dev\` 같이 동기화 대상이 아닌 경로를 사용하세요.

```powershell
# 동기화 대상이 아닌 경로 권장
mkdir D:\projects -ErrorAction SilentlyContinue
cd D:\projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

# Node 버전 적용 (.nvmrc 자동 후크가 없다면 수동)
nvm use 20.15.0

# 의존성 설치 (네이티브 모듈을 Windows용으로 새로 컴파일)
npm install
```

`npm install`이 끝부분에 `node-gyp rebuild`를 호출하며 `windows-focus-assist`·`registry-js`·`cf-prefs`를 컴파일합니다. 이 과정에서 흔히 마주치는 오류는 [§8.2 Windows 11 네이티브](#82-windows-11-네이티브) 의 항목들로 정리되어 있습니다.

### 3.8 개발 실행

```powershell
# 빠른 dev 사이클: webpack watch + electron 자동 재시작
npm run watch

# 또는 1회 빌드 후 실행
npm run build
npm run start
```

OKRBEST 창이 뜨고 main/preload/renderer 코드 수정 시 자동 재시작/HMR.

### 3.9 PowerShell 사용 팁

**공백이 포함된 경로**:
```powershell
cd "C:\Program Files\nodejs"           # 큰따옴표 (가장 일반적)
cd $env:ProgramFiles                   # 자주 쓰는 경로는 환경 변수
cd ${env:ProgramFiles(x86)}            # 괄호 포함은 ${}
```

**Tab 자동완성**으로 따옴표가 자동 추가됩니다. `cd C:\Prog<Tab>` → `cd 'C:\Program Files\'`.

---

## 4. Windows 11 + WSL Ubuntu 환경 설정

WSL Ubuntu에서 **Linux 빌드**를 돌리는 환경. WSLg가 GUI를 자동 표시하므로 Linux용 OKRBEST를 Windows 데스크톱 위에서 바로 실행할 수 있어 dev 사이클이 가장 빠릅니다. 단, Windows 전용 기능 검증은 불가.

### 4.1 WSL2 설치

```powershell
# PowerShell 관리자 권한
wsl --install                  # Ubuntu 기본 설치
# 또는 특정 배포판
wsl --install -d Ubuntu-22.04

wsl --version                  # 버전 확인
wsl --status                   # WSLg 지원 확인 (Windows 11 Build 22000+)
```

설치 후 **컴퓨터 재시작** 필요.

### 4.2 Ubuntu 초기 설정

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget
```

> **Python**: WSL Ubuntu에는 `python3`가 기본 포함되어 node-gyp 빌드에 보통 충분합니다. 그러나 **Windows 클론과 동일한 Python 버전을 유지**하려면 [§Python 버전 관리 (uv)](#python-버전-관리-uv) 절차를 따르세요. uv는 Linux에서도 동일하게 동작합니다.

### 4.3 nvm + Node.js 설치

```bash
# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm --version

# Node.js (.nvmrc 일치)
nvm install 20.15.0
nvm use 20.15.0
nvm alias default 20.15.0      # nvm.sh는 alias 명령으로 default 설정

node -v                        # v20.15.0
```

> WSL의 `nvm.sh`는 빈 인자의 `nvm use`로 `.nvmrc`를 자동 인식합니다 (nvm-windows와의 차이).

### 4.4 Electron 실행을 위한 시스템 라이브러리

```bash
sudo apt install -y \
    libx11-xcb1 libxcb-dri3-0 libdrm2 libgbm1 \
    libasound2 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libgtk-3-0 libnss3 libxss1 libxtst6 \
    xdg-utils libnotify4 libsecret-1-0

# Linux 패키지 빌드용 (선택)
sudo apt install -y rpm fakeroot dpkg
```

### 4.5 GUI 환경 확인

WSLg가 자동으로 GUI를 처리합니다.

```bash
echo $DISPLAY                   # :0 등
ls /mnt/wslg/                   # runtime-dir, .X11-unix 등이 보이면 정상

# 간단 테스트 (선택)
sudo apt install -y x11-apps && xclock
```

### 4.6 프로젝트 클론 및 설정

> Windows 파일시스템(`/mnt/c/...`)이 아닌 **Linux 파일시스템(`~/projects/`)**에 클론하세요. 후자가 I/O가 압도적으로 빠릅니다.

```bash
cd ~/projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

nvm use                         # .nvmrc 자동 적용
npm install
npm run watch
```

### 4.7 Windows 측 클론과 분리

같은 저장소를 Windows 네이티브와 WSL 양쪽에서 개발한다면 **두 개의 독립적인 클론**을 두세요. 한쪽 `node_modules`는 OS별 ABI에 맞게 컴파일되어 다른 쪽에서 require 시 충돌합니다. 코드 동기화는 git push/pull 또는 동일 브랜치를 양쪽에서 fetch 하는 방식.

---

## 5. macOS 환경 설정

### 5.1 Xcode Command Line Tools

```bash
xcode-select --install
xcode-select -p                 # /Library/Developer/CommandLineTools
```

### 5.2 Homebrew 설치 (권장)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon 경로
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew --version
```

### 5.3 nvm + Node.js

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc                 # 또는 ~/.bash_profile

nvm install 20.15.0
nvm use 20.15.0
nvm alias default 20.15.0

node -v
```

### 5.4 추가 도구 (선택)

```bash
brew install git                # 최신 git
```

> **Python**: macOS에는 시스템 `python3`가 포함되어 있으나, **Windows·WSL과 동일한 Python 버전 일관성**을 위해 uv 사용을 권장합니다. [§Python 버전 관리 (uv)](#python-버전-관리-uv) 참조. uv는 Homebrew 없이도 단독 설치됩니다.
>
> Homebrew Python을 선호한다면: `brew install python@3.12`

배포용 코드 사이닝은 Apple Developer 계정이 필요. 설정 절차는 [APPLE_DEVELOPER_ACCOUNT_SETUP.md](./APPLE_DEVELOPER_ACCOUNT_SETUP.md) 참조.

### 5.5 프로젝트 클론 및 설정

```bash
cd ~/Projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

nvm use
npm install
npm run watch
```

### 5.6 Apple Silicon 호환성

```bash
node -p "process.arch"          # arm64 출력되어야 함

# Rosetta로 실행 중이라면 터미널 정보에서
# "Rosetta를 사용하여 열기" 체크 해제
```

---

## Python 버전 관리 (uv)

이 프로젝트는 **Python 소스 코드를 포함하지 않으나**, `npm install` 시 `node-gyp`가 네이티브 모듈(`windows-focus-assist`, `registry-js`, `cf-prefs`, `cf-prefs`)을 컴파일하기 위해 Python 3.6+를 필요로 합니다. 또한 i18n 도구 `mmjstool`이 일부 Python 의존을 가질 수 있습니다.

### 왜 uv인가

| 도구 | 비고 |
|---|---|
| **uv** (권장) | Astral, Rust 기반. 단일 바이너리로 Windows·WSL·macOS 일관. Python 설치+venv+의존성 통합. **Microsoft Store 앱 별칭 함정 자체 회피**. |
| pyenv + pyenv-win | nvm과 같은 멘탈 모델. 성숙. OS별로 다른 구현이라 동기화 부담. venv는 별도. |
| 시스템 Python | Linux/macOS 기본 제공. Windows는 별도 설치 필요. 버전 통일·격리 어려움. |
| conda/miniconda | 데이터 사이언스 표준. 본 프로젝트엔 과함. |

### uv 설치

**Windows (PowerShell)**:
```powershell
winget install astral-sh.uv
# 또는: powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**WSL Ubuntu / macOS**:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# 셸 재시작 또는: source ~/.bashrc / ~/.zshrc
```

검증:
```bash
uv --version          # 0.5.x 이상
```

### Python 설치

```bash
uv python list                              # 사용 가능 버전 목록
uv python install 3.12 --default --preview  # 시스템 PATH에 노출되도록
```

검증 (새 셸 세션):
```bash
uv python find        # uv가 관리하는 Python 경로
python --version      # Python 3.12.x
```

### 프로젝트별 버전 고정 (`.python-version`)

`.nvmrc`와 같은 개념. 프로젝트 루트에서:
```bash
cd okrbest-desktop
uv python pin 3.12
```

`.python-version` 파일이 생성되며, 이 디렉토리에서는 셸 진입 시 uv가 해당 버전을 자동 활성화합니다.

> 본 저장소에는 아직 `.python-version`이 커밋되지 않았습니다. 팀 표준으로 합의되면 추가 권장.

### node-gyp 연결 (필수)

uv 관리 Python을 npm/node-gyp가 사용하도록 명시:

**Windows (PowerShell)**:
```powershell
npm config set python (uv python find)
npm config get python
```

**WSL / macOS**:
```bash
npm config set python "$(uv python find)"
npm config get python
```

이후 `npm install` → `node-gyp rebuild`가 위 경로의 Python을 사용. 시스템 Python 충돌·앱 별칭 가로채기·경로 불일치 모두 사라집니다.

### (옵션) 가상환경·의존성 관리

이 프로젝트엔 venv가 필요 없지만, 다른 Python 작업에 적용한다면 같은 uv 한 가지로 처리:

```bash
uv venv                     # .venv/ 생성
uv pip install <pkg>        # venv에 설치
uv add <pkg>                # pyproject.toml에 의존성 추가
uv sync                     # lockfile 기반 동기화
uv run python script.py     # venv 활성화 없이 실행
uv run pytest
```

---

## E2E 테스트 환경

이 프로젝트는 [Playwright](https://playwright.dev/) 기반 E2E 테스트 스위트를 [e2e/](../e2e/) 서브 패키지로 운영합니다. 단위 테스트(`npm run test:unit`)와 별도이며 별도의 의존성·런타임 요구사항을 가집니다.

### 디렉토리 구조

```
e2e/
├── package.json                # 별도 npm 패키지 (desktop-e2e), Playwright 의존성
├── playwright.config.ts        # 워커 수, 타임아웃, 리포터, 플랫폼별 grep
├── merge.playwright.config.ts  # CI에서 blob 리포트 병합용
├── global-setup.ts             # macOS 윈도우 복원 차단 등 글로벌 hook
├── global-teardown.ts          # 잔여 electron 프로세스 정리
├── tsconfig.json
├── babel.config.js
├── fixtures/                   # Playwright fixture (test, expect 재export 포함)
├── helpers/                    # login, serverMap, exclusiveLock 등 재사용 helper
├── modules/                    # environment·utils 등 보조 모듈
├── specs/                      # 실제 테스트 (specs/**/*.test.ts)
└── utils/                      # CI 보조 스크립트
```

테스트 작성 가이드는 [e2e/AGENTS.md](../e2e/AGENTS.md) 참조 (windows architecture, fixtures, anti-patterns 등).

### 사전 요구사항

1. **루트 의존성 설치 완료** ([§6.1](#61-의존성-설치))
2. **빌드 산출물 (e2e 전용)**: E2E는 `NODE_ENV=test`로 빌드된 `e2e/dist/`를 Electron의 `args[0]`로 띄웁니다. 일반 `npm run build`(→ `dist/`)와 별개. `npm run e2e`가 자동으로 `npm run build-test`를 선행 호출합니다.
3. **Mattermost 호환 서버 1대**: 테스트는 실제 서버에 로그인합니다. 다음 중 하나:
   - 로컬 Docker로 Mattermost preview 실행 (포트 8065 기본)
   - 사내 dev 서버 URL 사용
   - GitHub Actions에서는 `OKRBEST_DESKTOP_E2E_USER_*` 시크릿과 매트릭스 URL 사용 ([REBRAND_STATUS §3.1](./REBRAND_STATUS.md#31-github-secrets--variables-등록-상태))
4. **테스트 계정**: 로그인 helper(`loginToMattermost`)가 `MM_TEST_USER_NAME` / `MM_TEST_PASSWORD` 환경 변수를 요구

### E2E 의존성 설치

`npm run e2e`는 내부적으로 `npm --prefix e2e test`를 호출. `e2e/`는 별도 npm 패키지이므로 의존성도 별도 설치 필요:

```bash
# 루트에서
npm --prefix e2e install
```

또는 `e2e/` 디렉토리에서 직접:
```bash
cd e2e
npm install
```

설치되는 핵심 의존성:
- `@playwright/test` (Playwright runner)
- `chai` (assertion 보조)
- `cross-env` (스크립트의 환경 변수 설정)
- `fast-xml-parser`, `ps-node` (helper 도구)

> Playwright는 Electron 앱을 직접 launch하므로 별도 브라우저(`npx playwright install chromium`)는 필요 없습니다.

### 환경 변수

| 변수 | 용도 | 기본값 |
|---|---|---|
| `MM_TEST_SERVER_URL` | E2E가 접속할 Mattermost 서버 | `http://localhost:8065/` |
| `MM_TEST_USER_NAME` | 로그인 helper용 사용자명 | (필수, 미설정 시 throw) |
| `MM_TEST_PASSWORD` | 로그인 helper용 비밀번호 | (필수, 미설정 시 throw) |
| `E2E_WORKERS` | Playwright 워커 수 | CI=2, 로컬=`min(4, ⌊CPU/2⌋)` |
| `RUN_POLICY_E2E` | `true`면 GPO/policy spec 실행 (Windows) | `false` |
| `CI` | CI 모드 (재시도·리포터·워커 수 변경) | unset |
| `CI_ENVIRONMENT_NAME` | Playwright tag 필터 | unset |
| `DEBUG_E2E` | 디버그 로그 강화 | unset |

로컬 .env 파일을 따로 두려면 (Playwright는 자체 dotenv 지원 없음) 셸에서 export 하거나 `cross-env`로 명령에 직접 주입:

```bash
# Linux/macOS/WSL
export MM_TEST_SERVER_URL=http://localhost:8065/
export MM_TEST_USER_NAME=alice
export MM_TEST_PASSWORD=secret
npm run e2e

# Windows PowerShell
$env:MM_TEST_SERVER_URL = "http://localhost:8065/"
$env:MM_TEST_USER_NAME  = "alice"
$env:MM_TEST_PASSWORD   = "secret"
npm run e2e
```

### 로컬 Mattermost 서버 (Docker preview)

가장 간단한 방법은 Mattermost preview 이미지:

```bash
docker run --name mattermost-preview -d --publish 8065:8065 mattermost/mattermost-preview
# 첫 실행은 1~2분 소요. http://localhost:8065/ 접속해 admin 계정 생성
# 이후 그 계정을 MM_TEST_USER_NAME / MM_TEST_PASSWORD로 사용
```

종료/정리:
```bash
docker stop mattermost-preview
docker rm mattermost-preview
```

> Mattermost 서버 자체의 운영 옵션(SSO, plugins, calls 등)이 일부 spec에 영향을 줄 수 있어, 사내 표준 dev 서버가 있다면 그쪽을 권장.

### 실행

```bash
# 전체 E2E (build-test → playwright test, 플랫폼별 spec 자동 필터)
npm run e2e

# 단일 spec만 (e2e 디렉토리에서)
cd e2e
npx playwright test specs/server_management/add_server_modal.test.ts

# 특정 워커 수
E2E_WORKERS=1 npm run e2e

# Windows GPO/policy spec (Windows 호스트만)
cd e2e
npm run run:policy

# headed 모드 / 디버그 (electron 앱은 headless가 의미 없으나 trace에 유용)
npx playwright test --debug
```

플랫폼 태그 필터는 `playwright.config.ts`가 자동 처리:
- macOS: `@all` 또는 `@darwin` 태그가 붙은 spec만
- Windows: `@all` 또는 `@win32`
- Linux: `@all` 또는 `@linux`

### 리포트

| 위치 | 용도 |
|---|---|
| `e2e/playwright-report/` | 로컬 HTML 리포트 (`npx playwright show-report`로 열람) |
| `e2e/test-results/` | 실패 시 trace, screenshot, video |
| `e2e/blob-report/` | CI에서 워커별 blob 리포트 (병합 후 HTML 생성) |
| `e2e/test-results/e2e-junit.xml` | CI JUnit 리포트 |

> trace는 실패 시에만 저장 (`trace: 'retain-on-failure'`). 디버깅 시 `npx playwright show-trace test-results/.../trace.zip`로 타임라인 확인.

### WSL에서 E2E 가능한가

가능. WSLg가 GUI를 표시하므로 Linux 빌드의 Electron이 정상 launch됩니다. 단:
- macOS·Windows 전용 spec(`@darwin`, `@win32` 태그)은 자동으로 스킵
- 일부 native API 의존 spec(트레이, Focus Assist, MAS 권한 등)은 해당 OS에서만 검증 가능

### 트러블슈팅

#### `loginToMattermost: MM_TEST_USER_NAME and MM_TEST_PASSWORD must be set`
환경 변수 미설정. 위 "환경 변수" 절 참고해 export 또는 cross-env로 주입.

#### `connect ECONNREFUSED 127.0.0.1:8065`
로컬 Mattermost 서버가 떠 있지 않음. Docker preview 실행 또는 `MM_TEST_SERVER_URL`을 외부 dev 서버로 변경.

#### `Error: timeout 60000ms exceeded` (테스트 타임아웃)
- 시스템 부하: `E2E_WORKERS=1`로 워커 줄이기
- electron 앱 시동이 느림: `npm run build-test`가 최신인지 확인 (clean dist 후 재빌드)
- macOS "Resume" 다이얼로그가 떠서 막힘 → `global-setup.ts`가 차단하지만 안 되면 한 번 수동 dismiss

#### Windows에서 `EBUSY` / `EPERM` 락 파일 에러
[§8.2 EPERM rmdir](#82-windows-11-네이티브) 참고. `e2e/testUserData/`·`e2e/dist/` 폴더를 다른 프로세스가 잡고 있을 가능성. `npm --prefix e2e run clean` 후 재시도.

---

## 6. 공통 프로젝트 설정

### 6.1 의존성 설치

```bash
cd okrbest-desktop
nvm use                         # 또는 nvm use 20.15.0 (Windows)
node -v                         # v20.15.0
npm install
```

`postinstall` 훅에서 자동 실행:
1. `patch-package`: `patches/` 디렉토리의 패치 파일 적용
2. `electron-builder install-app-deps`: 네이티브 모듈을 현재 OS/Electron ABI에 맞춰 빌드

### 6.2 환경 검증

```bash
npm run build                   # webpack 전체 빌드
npm run check-types             # tsc 타입 체크
npm run lint:js-quiet           # ESLint (errors only)
npm run test:unit               # Jest 유닛 테스트
npm run check                   # 위 4가지를 병렬 실행
```

### 6.3 IDE 설정

VSCode/Cursor 사용 시 권장 설정과 확장은 [VSCODE_SETUP.md](./VSCODE_SETUP.md) 참조.

> **저장소에 .vscode/ 파일이 이미 커밋되어 있습니다** — 클론 후 별도 설정 없이 바로 사용 가능:
> | 파일 | 용도 |
> |---|---|
> | [.vscode/settings.json](../.vscode/settings.json) | 워크스페이스 공통 설정 (ESLint·TypeScript·포맷) |
> | [.vscode/launch.json](../.vscode/launch.json) | Electron main/renderer 디버그 launch 구성 |
> | [.vscode/tasks.json](../.vscode/tasks.json) | build·watch·test 태스크 (F1 → Run Task) |
> | [.vscode/extensions.json](../.vscode/extensions.json) | 권장 확장 (ESLint 등) — VS Code가 자동 제안 |

추가 권장 확장:
- **필수**: ESLint, TypeScript and JavaScript Language Features
- **권장**: GitLens, Path Intellisense, EditorConfig

기본 settings.json 핵심 설정 (저장소 값 기준):
```json
{
  "editor.formatOnSave": false,
  "editor.codeActionsOnSave": { "source.fixAll.eslint": "explicit" },
  "typescript.tsdk": "node_modules/typescript/lib",
  "eslint.workingDirectories": ["."]
}
```

---

## 7. 개발 명령어

### 7.1 빌드 및 실행

```bash
npm run build                   # 1회 빌드 (main/preload/renderer)
npm run start                   # dist 실행
npm run restart                 # build → start
npm run watch                   # webpack watch + electron 자동 재시작 (권장)
```

### 7.2 테스트

```bash
npm run check                   # lint + types + unit (병렬)
npm run lint:js                 # ESLint
npm run check-types             # TypeScript
npm run test:unit               # Jest 유닛 테스트
npm run test:unit-coverage      # 유닛 커버리지
npm run e2e                     # E2E (Playwright) — 사전 설정 필요, [§E2E 테스트 환경](#e2e-테스트-환경) 참조
```

### 7.3 정리

```bash
npm run clean-dist              # dist/ 만 제거
npm run clean                   # node_modules + release + dist 전부 제거
npm run clean-install           # clean → npm install
```

---

## 8. 문제 해결

### 8.1 공통

#### `npm install` 실패 — 네이티브 모듈 빌드 에러

```bash
# 빌드 도구 확인
# - Windows: Visual Studio Build Tools "C++ 데스크톱 개발" 워크로드
# - macOS: xcode-select --install
# - Linux: build-essential

python --version || python3 --version

npm cache clean --force
rm -rf node_modules package-lock.json   # PowerShell: Remove-Item -Recurse -Force
npm install
```

#### 타입 에러

```bash
npx tsc --version
npm run check-types
rm -rf node_modules && npm install
```

### 8.2 Windows 11 네이티브

#### `npm install` 실패 — `gyp ERR! find Python` (Python을 찾을 수 없음)

증상 (로그 발췌, 16개 후보 경로를 순회하며 모두 같은 패턴):
```
npm error gyp ERR! find Python checking if "python" can be used
npm error gyp ERR! find Python - executable path is ""
npm error gyp ERR! find Python - "" could not be run
...
npm error gyp ERR! find Python - version is ''
npm error gyp ERR! find Python - THIS VERSION OF PYTHON IS NOT SUPPORTED
npm error gyp ERR! stack Error: Could not find any Python installation to use
npm error gyp ERR! cwd ...\node_modules\windows-focus-assist
```

**원인**: Windows의 **앱 실행 별칭(App Execution Aliases)** 가 `python.exe` 호출을 Microsoft Store 스텁으로 리디렉션해 빈 응답을 반환. 진짜 Python이 설치돼 있어도 이 별칭이 우선합니다. 디스크의 python.exe 파일은 발견하지만 실행 시 stdout이 비어 node-gyp가 `version is ''`로 인식.

**해결 (권장: uv 도입으로 구조적 회피)**:

1. **uv 설치 + uv 관리 Python 사용** — uv는 Python을 `%LOCALAPPDATA%\uv\python\...` 자체 경로에 두므로 Store stub과 충돌하지 않음. [§Python 버전 관리 (uv)](#python-버전-관리-uv) 참조:
   ```powershell
   winget install astral-sh.uv
   uv python install 3.12 --default --preview
   npm config set python (uv python find)
   ```
2. **앱 실행 별칭 해제** (uv 사용 여부와 무관하게 권장) — 설정 → 앱 → 앱 실행 별칭에서 `python.exe`, `python3.exe` 둘 다 OFF
3. **새 PowerShell 세션 열기** (별칭/PATH 변경은 새 세션부터 적용)
4. **검증**:
   ```powershell
   python --version          # Python 3.12.x
   where.exe python          # uv 경로 또는 진짜 python.exe 경로 (Store stub 아님)
   npm config get python
   ```
5. **clean 재시도**:
   ```powershell
   Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
   Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
   npm cache clean --force
   npm install
   ```

**대안 (uv 미사용)**: `winget install Python.Python.3.12` 후 2단계와 `npm config set python (Get-Command python).Source` 적용. 단 앱 실행 별칭 해제는 사실상 필수.

자세한 배경은 [§3.5.1 Python 설치 (uv 권장)](#351-python-설치-uv-권장) 와 [§Python 버전 관리 (uv)](#python-버전-관리-uv) 참조.

#### `npm install` 실패 — `EPERM: operation not permitted, rmdir node_modules\@sentry\...`

증상:
```
npm warn cleanup Failed to remove some directories [
npm warn cleanup   [Error: EPERM: operation not permitted, rmdir
npm warn cleanup     'D:\...\node_modules\@sentry\browser\build\npm\cjs']
```

**원인**: `node_modules` 하위 파일을 다른 프로세스가 잠그고 있어 npm이 정리를 못함. 흔한 가해자:
- **OneDrive 동기화** (프로젝트가 `Documents\` 또는 OneDrive 폴더 안에 있을 때 가장 흔함)
- VS Code · Cursor · JetBrains IDE의 인덱서 / 언어 서버
- 백신 실시간 스캔 (특히 Windows Defender, McAfee, 카스퍼스키)
- 다른 PowerShell 세션의 `npm run watch` / electron 프로세스

**해결**:

1. **프로젝트를 OneDrive 동기화 폴더 *밖*으로 이동** (가장 근본적). 권장 경로: `D:\projects\` 또는 `C:\dev\`
2. VS Code · IDE에서 해당 디렉토리 닫기
3. 다른 셸의 watch / electron 프로세스 종료
4. 백신 실시간 보호 일시 중지 후 재시도
5. 그래도 안 풀리면 PowerShell 관리자 권한:
   ```powershell
   Remove-Item -Recurse -Force node_modules -ErrorAction Continue
   npm install
   ```
6. 정 안 되면 재부팅 후 1~5를 다시

#### `npm install` 경고 — `EBADENGINE Unsupported engine`

증상:
```
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@electron/rebuild@4.0.3',
npm warn EBADENGINE   required: { node: '>=22.12.0' },
npm warn EBADENGINE   current: { node: 'v20.15.0', npm: '10.7.0' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'node-abi@4.26.0',
npm warn EBADENGINE   required: { node: '>=22.12.0' },
npm warn EBADENGINE   current: { node: 'v20.15.0' }
npm warn EBADENGINE }
```

**무시해도 됩니다.** 프로젝트 [.nvmrc](../.nvmrc) 는 `v20.15.0`이며, 위 두 패키지는 `engines` 필드가 보수적으로 잡혀 있을 뿐 Node 20에서 정상 동작합니다 (실제 빌드/install 결과에 영향 없음). Node 22로 올리는 것은 [.nvmrc](../.nvmrc) 정책 변경을 동반하므로 별도 결정 사항.

#### `npm install` 경고 — `mattermost-utilities` integrity check skip

증상: `npm warn skipping integrity check for git dependency ssh://git@github.com/mattermost/mattermost-utilities.git`

**무시해도 됩니다.** [package.json](../package.json) 의 `mmjstool` 항목이 git url로 지정된 i18n 도구 의존성이며, npm은 git deps에 대해 integrity 검증을 건너뜁니다 (lockfile에 hash가 있어도 마찬가지). 보안 영향 없음.

#### `nvm use` 시 `access denied`

PowerShell이 관리자 권한이 아닙니다. PowerShell 단축아이콘 → 속성 → 고급 → "관리자 권한으로 실행" 체크.

#### `node-gyp` 빌드 실패 (`MSBuild.exe not found` 등)

Python은 잡히는데 C++ 컴파일러를 못 찾는 경우. [§3.5.2 Visual Studio Build Tools](#352-visual-studio-build-tools) 가 설치 마법사에서 **"C++을 사용한 데스크톱 개발"** 워크로드와 함께 설치됐는지 확인.

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
where.exe MSBuild.exe 2>$null    # 출력이 있어야 정상
```

PATH에 등록 안 됐다면 시작 메뉴에서 **"Developer PowerShell for VS 2022"** 를 열어 거기에서 `npm install` 시도.

#### WSL 클론과 같은 폴더의 `node_modules`를 사용하다 ABI 에러

OS별로 별도 클론·`node_modules`를 두세요 ([§3.7](#37-프로젝트-클론-및-설정), [§4.7](#47-windows-측-클론과-분리) 참조).

#### `.nvmrc` 자동 전환이 동작 안 함

nvm-windows는 기본적으로 `.nvmrc`를 인식하지 않습니다. [§3.4](#34-nvmrc-자동-적용-선택) 의 PowerShell 후크를 추가해야 합니다.

### 8.3 WSL Ubuntu

#### Electron 실행 시 `cannot open display`

```bash
echo $DISPLAY                   # 비어 있으면
export DISPLAY=:0
echo 'export DISPLAY=:0' >> ~/.bashrc
```

#### GPU 관련 에러

```bash
npm run start -- --disable-gpu
# 또는
export ELECTRON_DISABLE_GPU=1 && npm run start
```

#### WSLg 미동작

```powershell
wsl --update
wsl --shutdown
# 그 후 Ubuntu 다시 실행
```

#### Windows 파일시스템 경로 사용 시 I/O 저하

```bash
# 잘못된 예 (느림)
cd /mnt/c/Users/<user>/projects/okrbest-desktop

# 올바른 예 (빠름)
cd ~/projects/okrbest-desktop
```

### 8.4 macOS

#### `App is damaged` (서명 안 된 빌드 실행 시)

```bash
xattr -cr /path/to/OKRBEST.app
# 또는 시스템 환경설정 → 보안 및 개인정보에서 허용
```

#### 코드 사이닝 에러 (개발 중)

```bash
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm run package:mac
```

배포용 사이닝은 [APPLE_DEVELOPER_ACCOUNT_SETUP.md](./APPLE_DEVELOPER_ACCOUNT_SETUP.md) 참조.

#### `node-gyp` 빌드 실패

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
which python3
npm config set python /usr/bin/python3
```

---

## 9. 개발 팁

### 9.1 효율적인 워크플로우

```bash
# 터미널 1: watch
npm run watch

# 터미널 2: 필요 시 테스트
npm run test:unit -- --watch

# 코드 수정 → 자동 재빌드 → renderer는 Cmd/Ctrl+R로 새로고침
```

### 9.2 디버깅

- **Renderer DevTools**: 앱 실행 후 `View → Toggle Developer Tools` 또는 `Cmd/Ctrl+Shift+I`
- **Main process**: VSCode "Attach to Main Process" 디버그 설정 사용
- **Verbose log**: 환경 변수로 로그 레벨 제어
  ```bash
  ELECTRON_ENABLE_LOGGING=1 npm run start
  ```

### 9.3 로그 위치

`productName`이 `OKRBEST`이므로 `app.getPath('userData')`가 다음 경로를 반환:

| OS | 로그 경로 |
|---|---|
| Windows | `%APPDATA%\OKRBEST\logs\` |
| macOS | `~/Library/Application Support/OKRBEST/logs/` |
| Linux | `~/.config/OKRBEST/logs/` |

이전 Mattermost 빌드를 사용하던 사용자에게는 `%APPDATA%\Mattermost\` 등 옛 경로의 데이터가 그대로 남아 있습니다 (clean break 정책 — [REBRAND_STATUS.md](./REBRAND_STATUS.md) 참조).

### 9.4 npm script 알아두기

| 스크립트 | 용도 |
|---|---|
| `npm run check` | lint + check-types + check-build-config + test:unit 병렬 |
| `npm run fix:js` | ESLint --fix |
| `npm run i18n-extract` | i18n 키 재추출 (`mmjstool` 필요, 자동 설치됨) |
| `npm run prune` | 사용되지 않는 export 탐지 (`ts-prune`) |
| `npm run build-test` | E2E용 빌드 (NODE_ENV=test → `e2e/dist/`) |

### 9.5 개발자 모드 환경 변수

[src/main/developerMode.ts](../src/main/developerMode.ts) 가 다음 조건 중 하나면 dev-only 기능을 활성화합니다:
- `MM_DESKTOP_DEVELOPER_MODE=true`
- `electron-is-dev` 가 true (dev 빌드)
- `__IS_NIGHTLY_BUILD__` (nightly 빌드)

프로덕션 빌드에서 일시적으로 dev 기능을 켜고 싶다면:
```bash
# Linux/macOS
MM_DESKTOP_DEVELOPER_MODE=true npm run start

# Windows PowerShell
$env:MM_DESKTOP_DEVELOPER_MODE = "true"; npm run start
```

대표 dev-only 기능: dev 도구 자동 열기, 디버그 로그, dev 메뉴 항목, 진단(diagnostics) 강화 등.

### 9.6 관련 루트 문서

| 파일 | 용도 |
|---|---|
| [README.md](../README.md) | 프로젝트 개요·다운로드 |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | 기여 가이드라인 |
| [TESTING.md](../TESTING.md) | 릴리스 전 수동 테스트 절차 |
| [SECURITY.md](../SECURITY.md) | 보안 취약점 보고 |
| [AGENTS.md](../AGENTS.md) | AI 에이전트 / Claude Code 가이드 (루트) |
| [e2e/AGENTS.md](../e2e/AGENTS.md) | E2E 테스트 작성 가이드 |
| [CHANGELOG.md](../CHANGELOG.md) | 변경 이력 |

---

## 10. 빠른 시작 요약

### 10.1 Windows 11 네이티브

```powershell
# 1. 기존 Node 제거 후 nvm-windows 설치
winget install CoreyButler.NVMforWindows

# 2. 빌드 도구
winget install Microsoft.VisualStudio.2022.BuildTools
#   설치 마법사에서 "C++을 사용한 데스크톱 개발" 워크로드 선택

# 3. Node 설치 (관리자 권한 PowerShell)
nvm install 20.15.0
nvm use 20.15.0

# 4. 프로젝트
cd $env:USERPROFILE\projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop
npm install

# 5. 개발 시작
npm run watch
```

### 10.2 Windows 11 + WSL Ubuntu

```bash
# 1. Ubuntu 초기 + 라이브러리
sudo apt update && sudo apt install -y build-essential libgtk-3-0 libnss3 libasound2 libnotify4

# 2. nvm + Node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20.15.0

# 3. 프로젝트
cd ~/projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop
nvm use
npm install

# 4. 개발 시작
npm run watch
```

### 10.3 macOS

```bash
# 1. Xcode CLI
xcode-select --install

# 2. nvm + Node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install 20.15.0

# 3. 프로젝트
cd ~/Projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop
nvm use
npm install

# 4. 개발 시작
npm run watch
```

---

## 11. 프로덕션 빌드 및 패키징

### 11.1 프로덕션 빌드

```bash
npm run build-prod              # NODE_ENV=production
npm run build-prod-mas          # Mac App Store용
npm run check-build-config      # buildConfig.ts 검증
```

### 11.2 플랫폼별 패키징

```bash
# === Windows (Windows 호스트에서 실행 권장) ===
npm run package:windows         # 전체 (zip + msi)
npm run package:windows-zip
npm run package:windows-msi

# === macOS (macOS 호스트 필수) ===
npm run package:mac
npm run package:mac-with-universal   # Universal (Intel + Apple Silicon)
npm run package:mas                  # Mac App Store

# === Linux ===
npm run package:linux
```

> WSL에서 Windows 패키지를 빌드할 수도 있지만 (`electron-builder`가 cross-build 지원), 코드 사이닝·MSI 검증·NSIS UI 테스트는 Windows 호스트에서 수행해야 합니다.

### 11.3 출력 파일

[electron-builder.ts:24,69](../electron-builder.ts#L24) 의 `artifactName: '${version}/${name}-${version}-${os}-${arch}.${ext}'` 패턴을 따릅니다. `${name}`은 [package.json](../package.json) 의 `name` 필드(현재 `mattermost-desktop` — 자동업데이트 인프라와 결합되어 있어 의도적으로 유지, [REBRAND_STATUS.md](./REBRAND_STATUS.md) 참조).

```
release/{version}/
├── mattermost-desktop-{version}-win-x64.zip
├── mattermost-desktop-{version}-win-x64.msi
├── mattermost-desktop-{version}-mac-x64.dmg
├── mattermost-desktop-{version}-mac-arm64.dmg
├── mattermost-desktop-{version}-mac-universal.dmg
├── mattermost-desktop-{version}-linux-x64.tar.gz
├── mattermost-desktop_{version}-1_amd64.deb
├── mattermost-desktop-{version}-linux-x86_64.rpm
└── mattermost-desktop-{version}-linux-x86_64.AppImage
```

> 사용자가 OS에서 보는 앱 이름은 `productName` = `OKRBEST` (창 타이틀, 메뉴, About 다이얼로그). 산출물 *파일명*만 npm `name`을 따릅니다.

### 11.4 코드 사이닝

| OS | 방식 | 가이드 |
|---|---|---|
| Windows | Certum SimplySign (현재 정책) | [Certum-SimplySign.md](./Certum-SimplySign.md) |
| macOS | Apple Developer ID + notarization | [APPLE_DEVELOPER_ACCOUNT_SETUP.md](./APPLE_DEVELOPER_ACCOUNT_SETUP.md) |
| Linux | GPG 서명 (선택) | — |

서명 없이 빌드 (개발/테스트용):
```bash
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm run package:mac
```

### 11.5 릴리스 배포

```bash
# Git 태그 → GitHub Actions 자동 빌드/배포
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

CI/CD 전체 파이프라인은 [CI_CD.md](./CI_CD.md), 자동 업데이트 인프라는 [S3_AUTO_UPDATE_SETUP.md](./S3_AUTO_UPDATE_SETUP.md) 참조.

---

*문서 작성일: 2026-01-04*
*패키징/배포 섹션 추가: 2026-02-14*
*Windows 네이티브 환경 + 리브랜드 반영: 2026-05-10*
*Windows npm install 실패 사례(앱 실행 별칭·EPERM·EBADENGINE) 보강: 2026-05-11*
*Python 버전 관리 (uv) 섹션 추가 및 Windows/WSL/macOS 통합 워크플로우 적용: 2026-05-11*
*E2E 테스트 환경 섹션 신설(Playwright·Mattermost 서버·환경변수·리포트), .vscode/ 자산 안내, 개발자 모드/루트 문서 참조 추가: 2026-05-11*
