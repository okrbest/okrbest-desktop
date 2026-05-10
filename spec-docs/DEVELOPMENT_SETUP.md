# OKRBEST Desktop 개발 환경 설정 가이드

> Windows 11(네이티브 / WSL Ubuntu) 및 macOS에서의 개발 환경 설정 방법

---

## 목차

1. [시스템 요구사항](#1-시스템-요구사항)
2. [환경 선택 가이드](#2-환경-선택-가이드)
3. [Windows 11 네이티브 환경 설정](#3-windows-11-네이티브-환경-설정)
4. [Windows 11 + WSL Ubuntu 환경 설정](#4-windows-11--wsl-ubuntu-환경-설정)
5. [macOS 환경 설정](#5-macos-환경-설정)
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

### 3.5 Visual Studio Build Tools 설치

이 프로젝트는 Windows 전용 네이티브 모듈(`windows-focus-assist`, `registry-js`, `cf-prefs`)을 빌드하므로 C++ 빌드 도구가 필수:

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

설치 마법사에서 **"C++을 사용한 데스크톱 개발"** 워크로드를 선택. (이미 Visual Studio 2022가 설치돼 있으면 같은 워크로드만 추가하면 됨.)

### 3.6 Git for Windows

```powershell
winget install Git.Git
git --version
```

### 3.7 프로젝트 클론 및 설정

> WSL 파일시스템(`\\wsl$\Ubuntu\...`)을 Windows에서 마운트해 쓰면 I/O가 매우 느리고 fsevents·심링크 이슈가 납니다. **반드시 Windows의 NTFS에 별도 클론**하세요.

```powershell
# 임의의 작업 폴더에서
cd $env:USERPROFILE\projects
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

# Node 버전 적용 (.nvmrc 자동 후크가 없다면 수동)
nvm use 20.15.0

# 의존성 설치 (네이티브 모듈을 Windows용으로 새로 컴파일)
npm install
```

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
brew install python             # 네이티브 모듈 빌드용 (보통 기본 포함)
```

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

기본 권장:
- **확장**: ESLint, TypeScript, GitLens
- **`.vscode/settings.json`** 핵심:
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
npm run test:unit               # Jest
npm run test:unit-coverage      # 커버리지
npm run e2e                     # E2E (Playwright)
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

#### `nvm use` 시 `access denied`

PowerShell이 관리자 권한이 아닙니다. PowerShell 단축아이콘 → 속성 → 고급 → "관리자 권한으로 실행" 체크.

#### `node-gyp` 빌드 실패 (`MSBuild.exe not found` 등)

```powershell
# Build Tools 재설치 시 "C++ 데스크톱 개발" 워크로드 선택 확인
winget install Microsoft.VisualStudio.2022.BuildTools

# Python 경로 등록
npm config set python (Get-Command python).Source
```

#### WSL 클론과 같은 폴더의 `node_modules`를 사용하다 ABI 에러

OS별로 별도 클론·`node_modules`를 두세요 (3.7, 4.7 참조).

#### `.nvmrc` 자동 전환이 동작 안 함

nvm-windows는 기본적으로 `.nvmrc`를 인식하지 않습니다. [3.4](#34-nvmrc-자동-적용-선택)의 PowerShell 후크를 추가해야 합니다.

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
| `npm run i18n-extract` | i18n 키 재추출 (`mmjstool` 필요) |
| `npm run prune` | 사용되지 않는 export 탐지 (`ts-prune`) |

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
