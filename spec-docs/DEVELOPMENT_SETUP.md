# OKR Best Desktop 개발 환경 설정 가이드

> Windows 11 WSL 및 macOS에서의 개발 환경 설정 방법

---

## 목차

1. [시스템 요구사항](#1-시스템-요구사항)
2. [Windows 11 WSL 환경 설정](#2-windows-11-wsl-환경-설정)
3. [macOS 환경 설정](#3-macos-환경-설정)
4. [공통 프로젝트 설정](#4-공통-프로젝트-설정)
5. [개발 명령어](#5-개발-명령어)
6. [문제 해결](#6-문제-해결)

---

## 1. 시스템 요구사항

### 1.1 공통 요구사항

| 항목 | 요구사항 |
|------|----------|
| **Node.js** | >= 18.0.0 (권장: **v20.15.0**) |
| **npm** | Node.js에 포함 |
| **Git** | 최신 버전 |
| **Electron** | 38.7.2 (npm install 시 자동 설치) |

### 1.2 플랫폼별 요구사항

| 플랫폼 | 요구사항 |
|--------|----------|
| **Windows 11 WSL** | WSL2 + Ubuntu 22.04+, WSLg (기본 포함) |
| **macOS** | macOS 11 (Big Sur) 이상, Xcode Command Line Tools |

---

## 2. Windows 11 WSL 환경 설정

### 2.1 WSL2 설치 및 설정

Windows 11에서는 WSLg가 기본 포함되어 GUI 앱 실행이 가능합니다.

```powershell
# PowerShell (관리자 권한)

# WSL 설치 (Ubuntu 기본)
wsl --install

# 또는 특정 배포판 설치
wsl --install -d Ubuntu-22.04

# WSL 버전 확인
wsl --version

# WSLg 지원 확인 (Windows 11 Build 22000+)
wsl --status
```

설치 후 **컴퓨터 재시작** 필요

### 2.2 Ubuntu 초기 설정

```bash
# Ubuntu 터미널에서 실행

# 패키지 업데이트
sudo apt update && sudo apt upgrade -y

# 기본 빌드 도구 설치
sudo apt install -y build-essential git curl wget
```

### 2.3 Node.js 설치 (nvm 사용)

```bash
# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 터미널 재시작 또는 설정 로드
source ~/.bashrc

# nvm 설치 확인
nvm --version

# Node.js 설치 (프로젝트 권장 버전)
nvm install 20.15.0
nvm use 20.15.0
nvm alias default 20.15.0

# 설치 확인
node -v  # v20.15.0
npm -v
```

### 2.4 Electron 실행을 위한 시스템 라이브러리

```bash
# Electron GUI 실행에 필요한 라이브러리
sudo apt install -y \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libdrm2 \
    libgbm1 \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libnotify4 \
    libsecret-1-0

# 패키징 도구 (선택, Linux 패키지 빌드 시)
sudo apt install -y rpm fakeroot dpkg
```

### 2.5 GUI 환경 확인

Windows 11의 WSLg는 자동으로 GUI를 지원합니다.

```bash
# DISPLAY 환경 변수 확인
echo $DISPLAY
# 출력 예: :0 또는 유사한 값

# WSLg 디렉터리 확인
ls /mnt/wslg/
# runtime-dir, distro, .X11-unix 등이 보이면 정상

# 간단한 GUI 테스트 (선택)
sudo apt install -y x11-apps
xclock  # 시계 창이 뜨면 성공
```

### 2.6 프로젝트 클론 및 설정

```bash
# 프로젝트 디렉터리로 이동
cd ~/projects  # 또는 원하는 경로
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

# Node.js 버전 자동 설정 (.nvmrc 사용)
nvm use

# 의존성 설치
npm install
```

---

## 3. macOS 환경 설정

### 3.1 Xcode Command Line Tools

```bash
# Xcode CLI 도구 설치
xcode-select --install

# 설치 확인
xcode-select -p
# 출력: /Library/Developer/CommandLineTools
```

### 3.2 Homebrew 설치 (선택사항이지만 권장)

```bash
# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PATH 설정 (Apple Silicon Mac인 경우)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 설치 확인
brew --version
```

### 3.3 Node.js 설치 (nvm 사용)

```bash
# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 터미널 재시작 또는 설정 로드
source ~/.zshrc  # zsh 사용 시
# 또는
source ~/.bash_profile  # bash 사용 시

# nvm 설치 확인
nvm --version

# Node.js 설치
nvm install 20.15.0
nvm use 20.15.0
nvm alias default 20.15.0

# 설치 확인
node -v  # v20.15.0
npm -v
```

### 3.4 추가 도구 설치 (선택)

```bash
# Git (최신 버전으로 업그레이드)
brew install git

# Python (네이티브 모듈 빌드용, 보통 기본 포함)
# 필요 시 설치
brew install python

# 패키지 서명용 (배포 시 필요)
# Xcode에서 Apple Developer 계정 설정 필요
```

### 3.5 프로젝트 클론 및 설정

```bash
# 프로젝트 디렉터리로 이동
cd ~/Projects  # 또는 원하는 경로
git clone <repository-url> okrbest-desktop
cd okrbest-desktop

# Node.js 버전 자동 설정 (.nvmrc 사용)
nvm use

# 의존성 설치
npm install
```

---

## 4. 공통 프로젝트 설정

### 4.1 의존성 설치

```bash
cd okrbest-desktop

# Node.js 버전 확인 (.nvmrc 기준)
nvm use
node -v  # v20.15.0 확인

# 의존성 설치
npm install

# 설치 과정에서 자동 실행되는 작업:
# 1. patch-package: 패치 파일 적용
# 2. electron-builder install-app-deps: 네이티브 모듈 빌드
```

### 4.2 환경 확인

```bash
# 빌드 테스트
npm run build

# 타입 체크
npm run check-types

# 린트 체크
npm run lint:js-quiet

# 유닛 테스트
npm run test:unit
```

### 4.3 IDE 설정

#### VSCode / Cursor 권장 확장

```
필수:
- ESLint
- TypeScript and JavaScript Language Features

권장:
- GitLens
- Prettier - Code formatter
- Path Intellisense
```

#### 권장 설정 (`.vscode/settings.json`)

```json
{
  "editor.formatOnSave": false,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "eslint.workingDirectories": ["."]
}
```

---

## 5. 개발 명령어

### 5.1 빌드 및 실행

```bash
# 개발 빌드
npm run build

# 앱 실행
npm run start

# 빌드 + 실행
npm run restart

# 파일 변경 감시 모드 (Hot Reload) - 권장
npm run watch
```

### 5.2 테스트

```bash
# 전체 검사 (lint + type check + unit test)
npm run check

# 개별 실행
npm run lint:js        # ESLint
npm run check-types    # TypeScript 타입 체크
npm run test:unit      # Jest 유닛 테스트

# 테스트 커버리지
npm run test:unit-coverage

# E2E 테스트
npm run e2e
```

### 5.3 패키징

```bash
# === Windows (WSL에서는 제한적) ===
# Windows 패키징은 Windows 환경에서 실행 권장

# === macOS ===
npm run package:mac              # DMG, ZIP
npm run package:mac-with-universal  # Universal (Intel + Apple Silicon)
npm run package:mas              # Mac App Store

# === Linux (WSL에서 가능) ===
npm run package:linux-tar        # tar.gz
npm run package:linux-pkg        # deb, rpm
npm run package:linux-appImage   # AppImage
```

### 5.4 정리

```bash
# 빌드 산출물 정리
npm run clean-dist

# 전체 정리 (node_modules 포함)
npm run clean

# 완전 재설치
npm run clean-install
```

---

## 6. 문제 해결

### 6.1 공통 문제

#### `npm install` 실패 - 네이티브 모듈 빌드 에러

```bash
# Python 확인
python --version  # 또는 python3 --version

# node-gyp 전역 설치
npm install -g node-gyp

# 캐시 정리 후 재설치
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

#### 타입 에러 발생

```bash
# TypeScript 버전 확인
npx tsc --version

# 타입 체크
npm run check-types

# node_modules 재설치
rm -rf node_modules
npm install
```

### 6.2 Windows 11 WSL 문제

#### Electron 실행 시 "cannot open display" 에러

```bash
# DISPLAY 환경 변수 확인
echo $DISPLAY

# 비어있다면 설정
export DISPLAY=:0

# ~/.bashrc에 영구 추가
echo 'export DISPLAY=:0' >> ~/.bashrc
```

#### GPU 관련 에러

```bash
# GPU 비활성화 실행
npm run start -- --disable-gpu

# 또는 환경 변수로
export ELECTRON_DISABLE_GPU=1
npm run start
```

#### WSLg가 동작하지 않음

```powershell
# PowerShell (관리자)에서 WSL 업데이트
wsl --update

# WSL 재시작
wsl --shutdown
# 그 후 Ubuntu 다시 실행
```

#### 파일 시스템 성능 저하

```bash
# Windows 파일시스템(/mnt/c/) 대신 Linux 파일시스템 사용
# 프로젝트를 ~/projects/ 같은 Linux 경로에 배치

# 잘못된 예 (느림)
cd /mnt/c/Users/username/projects/okrbest-desktop

# 올바른 예 (빠름)
cd ~/projects/okrbest-desktop
```

### 6.3 macOS 문제

#### "App is damaged" 에러 (빌드된 앱 실행 시)

```bash
# 쿼런틴 속성 제거
xattr -cr /path/to/OKRBest.app

# 또는 시스템 환경설정 > 보안 및 개인정보에서 허용
```

#### 코드 서명 에러 (패키징 시)

```bash
# 개발 중에는 서명 없이 빌드
npm run build-prod
electron-builder --mac --publish=never

# 서명 필요 시 Xcode에서 Apple Developer 계정 설정 필요
```

#### Apple Silicon (M1/M2) 호환성

```bash
# arm64 네이티브 빌드 확인
node -p "process.arch"  # arm64 출력되어야 함

# Rosetta로 실행 중이라면 터미널 설정 확인
# Terminal.app > 정보 가져오기 > "Rosetta를 사용하여 열기" 해제
```

#### node-gyp 빌드 실패

```bash
# Xcode Command Line Tools 재설치
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# Python 경로 확인
which python3

# node-gyp에 Python 경로 설정
npm config set python /usr/bin/python3
```

---

## 7. 개발 팁

### 7.1 효율적인 개발 워크플로우

```bash
# 터미널 1: 파일 감시 및 자동 빌드
npm run watch

# 터미널 2: 필요 시 테스트 실행
npm run test:unit

# 코드 수정 → 자동 빌드 → 앱에서 Cmd/Ctrl+R로 새로고침
```

### 7.2 디버깅

```bash
# 개발자 도구 열기
# 앱 실행 후: View > Toggle Developer Tools
# 또는 Cmd/Ctrl + Shift + I

# 메인 프로세스 디버깅
# VSCode에서 "Attach to Main Process" 디버그 설정 사용
```

### 7.3 로그 확인

```bash
# 앱 로그 위치
# Windows: %APPDATA%/Mattermost/logs/
# macOS: ~/Library/Application Support/Mattermost/logs/
# Linux: ~/.config/Mattermost/logs/
```

---

## 8. 빠른 시작 요약

### Windows 11 WSL

```bash
# 1. WSL Ubuntu에서 실행
sudo apt update && sudo apt install -y build-essential libgtk-3-0 libnss3 libasound2

# 2. nvm 및 Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20.15.0

# 3. 프로젝트 설정
cd ~/projects/okrbest-desktop
nvm use
npm install

# 4. 개발 시작
npm run watch
```

### macOS

```bash
# 1. Xcode CLI
xcode-select --install

# 2. nvm 및 Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install 20.15.0

# 3. 프로젝트 설정
cd ~/Projects/okrbest-desktop
nvm use
npm install

# 4. 개발 시작
npm run watch
```

---

## 9. 프로덕션 빌드 및 패키징

### 9.1 프로덕션 빌드

```bash
# 기본 프로덕션 빌드
npm run build-prod

# 자동 업데이트 지원 포함
npm run build-prod-upgrade

# Mac App Store용 빌드
npm run build-prod-mas

# 빌드 설정 검증
npm run check-build-config
```

### 9.2 플랫폼별 패키징

```bash
# === Windows ===
npm run package:windows           # 전체 (ZIP, NSIS, MSI)
npm run package:windows-zip       # ZIP만
npm run package:windows-installers # NSIS + MSI

# === macOS ===
npm run package:mac               # DMG, ZIP
npm run package:mac-with-universal # Universal (Intel + Apple Silicon) 포함
npm run package:mas               # Mac App Store

# === Linux ===
npm run package:linux             # 전체
npm run package:linux-tar         # tar.gz
npm run package:linux-pkg         # deb, rpm
npm run package:linux-appImage    # AppImage
```

### 9.3 출력 파일

모든 패키지는 `release/{version}/` 디렉터리에 생성됩니다:

```
release/{version}/
├── okrbest-desktop-{version}-win-x64.zip
├── okrbest-desktop-{version}-win-x64.msi
├── okrbest-desktop-setup-{version}-win.exe    (NSIS)
├── okrbest-desktop-{version}-mac-x64.dmg
├── okrbest-desktop-{version}-mac-arm64.dmg
├── okrbest-desktop-{version}-mac-universal.dmg
├── okrbest-desktop-{version}-linux-x64.tar.gz
├── okrbest-desktop_{version}-1_amd64.deb
├── okrbest-desktop-{version}-linux-x86_64.rpm
└── okrbest-desktop-{version}-linux-x86_64.AppImage
```

### 9.4 코드 서명 (배포 시)

```bash
# Windows - 현재 비활성화 (Certum 인증서 구매 후 설정)
#   구매처: https://shop.certum.eu/code-signing.html
#   Open Source Code Signing in the Cloud (€49/년) 권장
# macOS - Apple Developer 인증서 필요
# Linux - GPG 서명 (선택)

# 서명 없이 빌드 (개발/테스트용)
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm run package:mac
```

### 9.5 릴리스 배포

```bash
# Git 태그 생성 → GitHub Actions 자동 빌드/배포
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 수동 릴리스 (GitHub CLI)
gh release create v1.0.0 release/**/* --title "v1.0.0" --draft
```

자세한 CI/CD 배포 프로세스는 [CI_CD.md](./CI_CD.md) 참조.

---

*문서 작성일: 2026-01-04*
*패키징/배포 섹션 추가: 2026-02-14*
