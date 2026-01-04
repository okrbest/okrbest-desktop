# OKR Best Desktop 구현 계획서

> Mattermost Desktop 기반 OKR Best Desktop 프로젝트의 전체 구현, 배포, 운영 계획

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [리브랜딩 구현 계획](#2-리브랜딩-구현-계획)
3. [기능 확장 계획](#3-기능-확장-계획)
4. [빌드/패키징 전략](#4-빌드패키징-전략)
5. [배포 전략](#5-배포-전략)
6. [인프라 구축 계획](#6-인프라-구축-계획)
7. [테스트 및 품질 관리](#7-테스트-및-품질-관리)
8. [운영 및 유지보수](#8-운영-및-유지보수)
9. [일정 및 마일스톤](#9-일정-및-마일스톤)

---

## 1. 프로젝트 개요

### 1.1 프로젝트 목표

OKR Best Desktop은 Mattermost Desktop을 기반으로 한 크로스 플랫폼 데스크톱 애플리케이션으로, 다음 목표를 달성합니다:

1. **브랜드 독립성**: Mattermost에서 OKR Best로 완전한 리브랜딩
2. **OKR 기능 통합**: OKR(Objectives and Key Results) 관리 기능 확장
3. **엔터프라이즈 배포**: 기업 환경을 위한 다양한 배포 옵션 제공
4. **자체 인프라**: 독립적인 업데이트 및 지원 체계 구축

### 1.2 프로젝트 범위

| 범위 | 포함 | 제외 |
|------|------|------|
| 플랫폼 | Windows, macOS, Linux | 모바일 |
| 기능 | 채팅, OKR 통합 | 서버 개발 |
| 배포 | 설치 패키지, 자동 업데이트 | 웹 버전 |
| 인프라 | 업데이트 서버, 문서 사이트 | 채팅 서버 |

### 1.3 기술 스택

```
┌─────────────────────────────────────────────────────┐
│                    OKR Best Desktop                  │
├─────────────────────────────────────────────────────┤
│  Frontend        │ React 17, TypeScript 5.3         │
│  Framework       │ Electron 38                       │
│  Build           │ Webpack 5, electron-builder       │
│  Test            │ Jest, Playwright                  │
│  Monitoring      │ Sentry, electron-log              │
└─────────────────────────────────────────────────────┘
```

### 1.4 관련 문서

| 문서 | 설명 |
|------|------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 프로젝트 아키텍처 상세 |
| [REBRAND.md](./REBRAND.md) | 리브랜딩 체크리스트 및 가이드 |

---

## 2. 리브랜딩 구현 계획

### 2.1 실행 단계 및 우선순위

```
┌─────────────────────────────────────────────────────────────┐
│                    리브랜딩 실행 순서                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: 기반 작업 (Critical)                              │
│  ├── 라이선스/저작권 업데이트                                │
│  ├── 아이콘/이미지 리소스 교체                               │
│  └── package.json 메타데이터 변경                           │
│           │                                                 │
│           ▼                                                 │
│  Phase 2: 핵심 설정 (High)                                  │
│  ├── electron-builder.json 수정                            │
│  ├── 프로토콜 핸들러 변경 (mattermost → okrbest)            │
│  └── 앱 ID, User Model ID 변경                             │
│           │                                                 │
│           ▼                                                 │
│  Phase 3: 소스 코드 (High)                                  │
│  ├── 상수/링크 업데이트                                     │
│  ├── 레지스트리 경로 변경                                   │
│  └── 브랜드명 전체 치환                                     │
│           │                                                 │
│           ▼                                                 │
│  Phase 4: 리소스 (Medium)                                   │
│  ├── Windows GPO 파일 수정                                  │
│  ├── Linux desktop 파일 수정                               │
│  └── macOS 리소스 업데이트                                  │
│           │                                                 │
│           ▼                                                 │
│  Phase 5: 다국어/문서 (Medium)                              │
│  ├── i18n 파일 업데이트 (60개+)                            │
│  └── README, CHANGELOG 등 문서                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 의존성 관계

```
라이선스 업데이트 ─────┐
                      ├──► 패키지 메타데이터 ──► 빌드 설정
아이콘 리소스 준비 ────┘
                                    │
                                    ▼
                              소스 코드 수정
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              GPO 파일        Linux desktop      i18n 파일
                    │               │               │
                    └───────────────┴───────────────┘
                                    │
                                    ▼
                              빌드 테스트
```

### 2.3 리소스 요구사항

| 리소스 | 필요 항목 | 담당 |
|--------|----------|------|
| 디자인 | 앱 아이콘 세트 (ICO, ICNS, PNG) | 디자인팀 |
| 디자인 | 트레이 아이콘 (라이트/다크, 상태별) | 디자인팀 |
| 디자인 | DMG 배경 이미지 | 디자인팀 |
| 인프라 | 업데이트 서버 URL | 인프라팀 |
| 인프라 | 도움말/문서 사이트 URL | 인프라팀 |
| 법무 | 라이선스 검토 | 법무팀 |
| 번역 | i18n 파일 검토 (선택) | 번역팀 |

### 2.4 상세 작업 항목

#### Phase 1: 기반 작업 (1-2일)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 1.1 | LICENSE.txt에 OKR Best 저작권 추가 | `LICENSE.txt` | ☐ |
| 1.2 | NOTICE.txt 업데이트 | `NOTICE.txt` | ☐ |
| 1.3 | 메인 앱 아이콘 교체 | `src/assets/icon.*` | ☐ |
| 1.4 | 트레이 아이콘 교체 (Windows) | `src/assets/windows/` | ☐ |
| 1.5 | 트레이 아이콘 교체 (Linux) | `src/assets/linux/` | ☐ |
| 1.6 | macOS 리소스 교체 | `src/assets/osx/` | ☐ |
| 1.7 | package.json 수정 | `package.json` | ☐ |
| 1.8 | api-types/package.json 수정 | `api-types/package.json` | ☐ |
| 1.9 | e2e/package.json 수정 | `e2e/package.json` | ☐ |

#### Phase 2: 핵심 설정 (1일)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 2.1 | electron-builder.json 전체 수정 | `electron-builder.json` | ☐ |
| 2.2 | setAppUserModelId 변경 | `src/main/app/initialize.ts` | ☐ |
| 2.3 | 프로토콜 스키마 변경 | 여러 파일 | ☐ |

#### Phase 3: 소스 코드 (2-3일)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 3.1 | 상수 파일 업데이트 | `src/common/constants.ts` | ☐ |
| 3.2 | 빌드 설정 업데이트 | `src/common/config/buildConfig.ts` | ☐ |
| 3.3 | 레지스트리 경로 변경 | `src/common/config/RegistryConfig.ts` | ☐ |
| 3.4 | 나머지 소스 파일 브랜드명 치환 | `src/**/*.ts` | ☐ |

#### Phase 4: 리소스 (1일)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 4.1 | GPO ADMX 파일 수정 및 이름 변경 | `resources/windows/gpo/` | ☐ |
| 4.2 | GPO ADML 파일 수정 및 이름 변경 | `resources/windows/gpo/en-US/` | ☐ |
| 4.3 | Linux desktop 파일 생성 스크립트 수정 | `src/assets/linux/create_desktop_file.sh` | ☐ |

#### Phase 5: 다국어/문서 (1-2일)

| # | 작업 | 파일 | 상태 |
|---|------|------|------|
| 5.1 | 영어 번역 파일 수정 | `i18n/en.json` | ☐ |
| 5.2 | 한국어 번역 파일 수정 | `i18n/ko.json` | ☐ |
| 5.3 | 기타 언어 파일 일괄 수정 | `i18n/*.json` | ☐ |
| 5.4 | README.md 재작성 | `README.md` | ☐ |
| 5.5 | CHANGELOG.md 초기화 | `CHANGELOG.md` | ☐ |

---

## 3. 기능 확장 계획

### 3.1 OKR 기능 확장 영역

Desktop App은 웹앱의 래퍼 역할을 하므로, OKR 기능 확장은 주로 다음 영역에서 이루어집니다:

```
┌─────────────────────────────────────────────────────────────┐
│                    기능 확장 레이어                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐     ┌─────────────────┐               │
│  │  Desktop API    │◄───►│   OKR 웹앱      │               │
│  │  (externalAPI)  │     │   (BrowserView)  │               │
│  └────────┬────────┘     └─────────────────┘               │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────────────────────────────┐               │
│  │           확장 가능 기능                  │               │
│  ├─────────────────────────────────────────┤               │
│  │ • 데스크톱 알림 (OKR 마감일, 진행률)      │               │
│  │ • 시스템 트레이 상태 표시                 │               │
│  │ • 키보드 단축키                          │               │
│  │ • 딥링크 (okrbest://okr/...)            │               │
│  │ • 오프라인 캐싱 (선택)                   │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Desktop API 확장 포인트

현재 Desktop API (`src/app/preload/externalAPI.ts`)를 확장하여 OKR 기능 지원:

```typescript
// 확장 가능한 API 예시
window.desktop = {
  // 기존 API
  getAppInfo: () => {...},
  
  // OKR 확장 API (예시)
  okr: {
    showOKRNotification: (objective, keyResult, progress) => {...},
    updateTrayBadge: (pendingItems) => {...},
    registerOKRShortcuts: () => {...},
  }
};
```

### 3.3 웹앱 연동 전략

```
┌────────────────┐          IPC           ┌────────────────┐
│                │◄────────────────────►│                │
│  OKR Best      │    postMessage        │  OKR Best      │
│  Desktop       │◄────────────────────►│  Web App       │
│  (Electron)    │                       │  (React)       │
│                │    Desktop API        │                │
│                │◄────────────────────►│                │
└────────────────┘                       └────────────────┘
         │
         │ 제공 기능
         ├── 네이티브 알림
         ├── 시스템 트레이 연동
         ├── 파일 시스템 접근
         ├── 클립보드 통합
         └── 딥링크 처리
```

### 3.4 OKR 기능 확장 로드맵

| 우선순위 | 기능 | 설명 | 복잡도 |
|----------|------|------|--------|
| P1 | OKR 딥링크 | `okrbest://okr/{id}` 형태 링크 처리 | 낮음 |
| P1 | OKR 알림 | 마감일, 체크인 알림 | 낮음 |
| P2 | 트레이 배지 | 미완료 OKR 개수 표시 | 중간 |
| P2 | 키보드 단축키 | OKR 빠른 접근 단축키 | 중간 |
| P3 | 위젯 윈도우 | OKR 요약 미니 윈도우 | 높음 |
| P3 | 오프라인 모드 | OKR 데이터 로컬 캐싱 | 높음 |

---

## 4. 빌드/패키징 전략

### 4.1 빌드 프로세스 개요

```
┌─────────────────────────────────────────────────────────────┐
│                      빌드 파이프라인                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Source Code                                                │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐              │
│  │ Webpack │────►│  dist/  │────►│electron-│              │
│  │  Build  │     │ bundle  │     │ builder │              │
│  └─────────┘     └─────────┘     └────┬────┘              │
│                                       │                    │
│       ┌───────────────────────────────┼────────────────┐   │
│       ▼                   ▼           ▼                │   │
│  ┌─────────┐     ┌─────────────┐  ┌─────────┐         │   │
│  │ Windows │     │   macOS     │  │  Linux  │         │   │
│  │ x64/arm │     │ x64/arm/uni │  │ x64/arm │         │   │
│  └────┬────┘     └──────┬──────┘  └────┬────┘         │   │
│       │                 │              │               │   │
│  ┌────┴────┐     ┌──────┴──────┐  ┌────┴────┐        │   │
│  │NSIS MSI │     │ DMG  ZIP    │  │deb rpm  │        │   │
│  │   ZIP   │     │    MAS      │  │AppImage │        │   │
│  └─────────┘     └─────────────┘  └─────────┘        │   │
│                                                       │   │
└───────────────────────────────────────────────────────────┘
```

### 4.2 플랫폼별 빌드 명령

```bash
# 전체 플랫폼 빌드
npm run build-prod

# 플랫폼별 패키징
npm run package:windows      # NSIS, MSI, ZIP
npm run package:mac          # DMG, ZIP
npm run package:mas          # Mac App Store
npm run package:linux        # deb, rpm, tar.gz, AppImage
```

### 4.3 CI/CD 파이프라인 설계

```yaml
# GitHub Actions 워크플로우 예시
name: Build and Release

on:
  push:
    tags: ['v*']

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run package:windows
      - name: Sign Executables
        run: # 코드 서명 로직
      - uses: actions/upload-artifact@v4
        with:
          name: windows-artifacts
          path: release/*.exe

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run package:mac
      - name: Sign and Notarize
        run: # Apple 공증 로직
      - uses: actions/upload-artifact@v4

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run package:linux
      - name: Sign Packages
        run: make sign-linux-deb
      - uses: actions/upload-artifact@v4

  release:
    needs: [build-windows, build-macos, build-linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
      - name: Create Release
        uses: softprops/action-gh-release@v1
      - name: Upload to Update Server
        run: # 업데이트 서버 배포
```

### 4.4 코드 서명

#### Windows
```
필요 사항:
- EV Code Signing Certificate
- SignTool.exe
- 타임스탬프 서버 URL

electron-builder 설정:
{
  "win": {
    "signingHashAlgorithms": ["sha256"],
    "signDlls": true
  }
}
```

#### macOS
```
필요 사항:
- Apple Developer ID Certificate
- Apple Developer Account (공증용)
- App-specific password

electron-builder 설정:
{
  "mac": {
    "hardenedRuntime": true,
    "gatekeeperAssess": true,
    "entitlements": "./resources/mac/entitlements.mac.plist"
  },
  "afterSign": "scripts/notarize.js"
}
```

#### Linux
```bash
# GPG 서명 (deb 패키지)
make sign-linux-deb

필요 사항:
- GPG Key
- dpkg-sig 도구
```

---

## 5. 배포 전략

### 5.1 Windows 배포

#### 5.1.1 배포 형태

| 형태 | 용도 | 특징 |
|------|------|------|
| **NSIS Installer** | 일반 사용자 | 자동 업데이트 지원, 설치 마법사 |
| **MSI Installer** | 기업 배포 | GPO 배포, SCCM 지원 |
| **ZIP** | 포터블 | 설치 불필요, 권한 제한 환경 |

#### 5.1.2 GPO(그룹 정책) 배포

```
1. GPO 템플릿 배포
   └── okrbest.admx → C:\Windows\PolicyDefinitions\
   └── okrbest.adml → C:\Windows\PolicyDefinitions\en-US\

2. 그룹 정책 설정
   └── Computer Configuration
       └── Administrative Templates
           └── OKR Best
               ├── DefaultServerList (기본 서버)
               ├── EnableServerManagement (서버 관리 허용)
               └── EnableAutoUpdater (자동 업데이트)

3. MSI 배포
   └── SCCM 또는 Intune을 통한 자동 배포
```

#### 5.1.3 자동 업데이트 (Windows)

```
지원: NSIS, AppImage만 (MSI 제외)

업데이트 서버 구조:
https://releases.okrbest.com/desktop/
├── latest.yml           # 버전 정보
├── {version}/
│   └── okrbest-desktop-setup-{version}-win.exe
```

### 5.2 macOS 배포

#### 5.2.1 배포 형태

| 형태 | 용도 | 특징 |
|------|------|------|
| **DMG** | 일반 배포 | 드래그 앤 드롭 설치 |
| **ZIP** | 자동 업데이트 | Sparkle 호환 |
| **Mac App Store** | 앱스토어 배포 | 샌드박스 제한 |

#### 5.2.2 코드 서명 및 공증

```bash
# 서명 확인
codesign --verify --deep --strict /Applications/OKRBest.app

# 공증 상태 확인
spctl -a -v /Applications/OKRBest.app
```

#### 5.2.3 MDM 배포

```
지원 MDM:
- Jamf Pro
- Kandji
- Mosyle

배포 방법:
1. 서명된 PKG 패키지 생성
2. MDM에 앱 업로드
3. 정책 설정 및 배포
```

### 5.3 Linux 배포

#### 5.3.1 배포 형태

| 형태 | 대상 배포판 | 특징 |
|------|------------|------|
| **deb** | Debian, Ubuntu | apt 저장소 지원 |
| **rpm** | RHEL, Fedora | yum/dnf 저장소 지원 |
| **AppImage** | 모든 배포판 | 자동 업데이트 지원 |
| **tar.gz** | 모든 배포판 | 수동 설치 |

#### 5.3.2 패키지 저장소 설정 (예시)

```bash
# APT 저장소 (deb)
# /etc/apt/sources.list.d/okrbest.list
deb https://packages.okrbest.com/apt stable main

# YUM 저장소 (rpm)
# /etc/yum.repos.d/okrbest.repo
[okrbest]
name=OKR Best Desktop
baseurl=https://packages.okrbest.com/yum
enabled=1
gpgcheck=1
```

### 5.4 자동 업데이트 인프라

```
┌─────────────────────────────────────────────────────────────┐
│                    자동 업데이트 플로우                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  OKR Best Desktop                                          │
│       │                                                     │
│       │ 1. 버전 확인 요청                                   │
│       ▼                                                     │
│  ┌─────────────────────────────────┐                       │
│  │  https://releases.okrbest.com/  │                       │
│  │          desktop/               │                       │
│  │  ┌───────────────────────────┐  │                       │
│  │  │ latest.yml                │  │ 2. 버전 정보 응답     │
│  │  │ latest-mac.yml            │◄─┼───────────────────    │
│  │  │ latest-linux.yml          │  │                       │
│  │  └───────────────────────────┘  │                       │
│  │                                 │                       │
│  │  ┌───────────────────────────┐  │                       │
│  │  │ 1.0.0/                    │  │ 3. 패키지 다운로드    │
│  │  │  ├─ okrbest-setup.exe     │◄─┼───────────────────    │
│  │  │  ├─ okrbest.dmg           │  │                       │
│  │  │  └─ okrbest.AppImage      │  │                       │
│  │  └───────────────────────────┘  │                       │
│  └─────────────────────────────────┘                       │
│       │                                                     │
│       │ 4. 설치 및 재시작                                   │
│       ▼                                                     │
│  업데이트 완료                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. 인프라 구축 계획

### 6.1 필수 인프라

| 인프라 | 용도 | 우선순위 |
|--------|------|----------|
| **업데이트 서버** | 자동 업데이트 배포 | P0 (필수) |
| **다운로드 페이지** | 설치 파일 배포 | P0 (필수) |
| **문서 사이트** | 사용자 가이드, API 문서 | P1 |
| **Sentry** | 에러 추적 | P1 |
| **패키지 저장소** | Linux apt/yum 저장소 | P2 |

### 6.2 업데이트 서버 구축

#### 요구사항
```
- HTTPS 지원
- 정적 파일 호스팅
- CDN 연동 (선택)
- 높은 가용성
```

#### 구조
```
releases.okrbest.com/
├── desktop/
│   ├── latest.yml
│   ├── latest-mac.yml
│   ├── latest-linux.yml
│   └── {version}/
│       ├── okrbest-desktop-setup-{version}-win.exe
│       ├── okrbest-desktop-{version}-mac.dmg
│       ├── okrbest-desktop-{version}-mac.zip
│       ├── okrbest-desktop-{version}-linux.AppImage
│       ├── okrbest-desktop_{version}_amd64.deb
│       └── okrbest-desktop-{version}.x86_64.rpm
```

#### latest.yml 예시
```yaml
version: 1.0.0
releaseDate: '2024-01-15T00:00:00.000Z'
path: 1.0.0/okrbest-desktop-setup-1.0.0-win.exe
sha512: <base64-encoded-sha512-hash>
```

### 6.3 문서 사이트 구축

#### 필요 문서
```
docs.okrbest.com/
├── desktop/
│   ├── install/          # 설치 가이드
│   │   ├── windows.md
│   │   ├── macos.md
│   │   └── linux.md
│   ├── user-guide/       # 사용자 가이드
│   ├── admin-guide/      # 관리자 가이드
│   │   └── deployment/   # 배포 가이드
│   ├── changelog.md      # 변경 이력
│   └── troubleshooting/  # 문제 해결
```

### 6.4 Sentry 설정

```typescript
// src/main/sentryHandler.ts 설정
Sentry.init({
  dsn: 'https://xxx@sentry.okrbest.com/project',
  environment: process.env.NODE_ENV,
  release: app.getVersion(),
});
```

#### 필요 설정
- Sentry 프로젝트 생성
- DSN 발급
- 소스맵 업로드 설정
- 알림 규칙 설정

---

## 7. 테스트 및 품질 관리

### 7.1 테스트 전략

```
┌─────────────────────────────────────────────────────────────┐
│                      테스트 피라미드                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        ┌────────┐                          │
│                       /  Manual  \                         │
│                      /   Testing  \                        │
│                     ┌──────────────┐                       │
│                    /                \                      │
│                   /    E2E Tests     \                     │
│                  /    (Playwright)    \                    │
│                 ┌──────────────────────┐                   │
│                /                        \                  │
│               /    Integration Tests     \                 │
│              /         (Jest)             \                │
│             ┌──────────────────────────────┐               │
│            /                                \              │
│           /         Unit Tests               \             │
│          /           (Jest)                   \            │
│         └──────────────────────────────────────┘           │
│                                                             │
│         볼륨: 높음 ◄─────────────────────► 낮음            │
│         속도: 빠름 ◄─────────────────────► 느림            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 유닛 테스트

#### 대상 범위
```
src/common/**/*.ts    # 공유 로직
src/main/**/*.ts      # Main Process 로직
```

#### 실행 명령
```bash
npm run test:unit           # 테스트 실행
npm run test:unit-coverage  # 커버리지 포함
```

#### 커버리지 목표
| 영역 | 목표 커버리지 |
|------|--------------|
| common/ | 80% 이상 |
| main/ | 70% 이상 |
| 전체 | 75% 이상 |

### 7.3 E2E 테스트

#### 대상 시나리오
```
e2e/specs/
├── server_management/   # 서버 추가/편집/삭제
├── settings/           # 설정 변경
├── downloads/          # 파일 다운로드
├── deep_linking/       # 딥링크 처리
├── startup/            # 앱 시작/종료
└── menu_bar/           # 메뉴 기능
```

#### 실행 명령
```bash
npm run e2e
```

### 7.4 품질 게이트

#### CI 체크 항목
```bash
npm run check
# 포함 항목:
# - lint:js-quiet (ESLint)
# - check-build-config (빌드 설정 검증)
# - check-types (TypeScript 타입 체크)
# - test:unit (유닛 테스트)
```

#### PR 머지 조건
- [ ] 모든 CI 체크 통과
- [ ] 코드 리뷰 승인 (1명 이상)
- [ ] 커버리지 감소 없음
- [ ] 린트 에러 없음

### 7.5 수동 테스트 체크리스트

#### 릴리스 전 체크리스트
| 카테고리 | 항목 | Windows | macOS | Linux |
|----------|------|---------|-------|-------|
| 설치 | 신규 설치 | ☐ | ☐ | ☐ |
| 설치 | 업그레이드 설치 | ☐ | ☐ | ☐ |
| 기본 | 앱 시작/종료 | ☐ | ☐ | ☐ |
| 기본 | 서버 추가 | ☐ | ☐ | ☐ |
| 기본 | 로그인/로그아웃 | ☐ | ☐ | ☐ |
| 알림 | 데스크톱 알림 | ☐ | ☐ | ☐ |
| 알림 | 트레이 배지 | ☐ | ☐ | ☐ |
| 업데이트 | 자동 업데이트 | ☐ | ☐ | ☐ |

---

## 8. 운영 및 유지보수

### 8.1 버전 관리 정책

#### 버전 체계 (Semantic Versioning)
```
MAJOR.MINOR.PATCH[-PRERELEASE]

예시:
- 1.0.0       : 정식 릴리스
- 1.1.0       : 새 기능 추가
- 1.1.1       : 버그 수정
- 2.0.0-beta.1: 베타 버전
```

#### 버전 변경 기준
| 변경 | 트리거 |
|------|--------|
| MAJOR | 호환성 깨지는 변경, 대규모 UI 변경 |
| MINOR | 새 기능 추가, 하위 호환 유지 |
| PATCH | 버그 수정, 보안 패치 |

### 8.2 릴리스 프로세스

```
┌─────────────────────────────────────────────────────────────┐
│                      릴리스 워크플로우                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 코드 프리즈                                             │
│       │                                                     │
│       ▼                                                     │
│  2. Release Branch 생성 (release/v1.x.x)                   │
│       │                                                     │
│       ▼                                                     │
│  3. QA 테스트                                               │
│       │                                                     │
│       ├── 버그 발견 → 수정 후 재테스트                      │
│       │                                                     │
│       ▼                                                     │
│  4. 릴리스 노트 작성                                        │
│       │                                                     │
│       ▼                                                     │
│  5. 태그 생성 (v1.x.x)                                      │
│       │                                                     │
│       ▼                                                     │
│  6. CI/CD 자동 빌드 및 서명                                 │
│       │                                                     │
│       ▼                                                     │
│  7. 업데이트 서버 배포                                      │
│       │                                                     │
│       ▼                                                     │
│  8. 공지 및 문서 업데이트                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 8.3 이슈 대응 프로세스

#### 이슈 분류
| 심각도 | 설명 | 대응 시간 |
|--------|------|-----------|
| **Critical** | 앱 크래시, 데이터 손실 | 24시간 내 |
| **High** | 주요 기능 장애 | 72시간 내 |
| **Medium** | 일반 버그 | 다음 릴리스 |
| **Low** | 개선 사항 | 백로그 |

#### 핫픽스 프로세스
```
1. 이슈 접수 및 재현
2. 영향도 분석
3. 핫픽스 브랜치 생성 (hotfix/issue-xxx)
4. 수정 및 테스트
5. 긴급 릴리스 (x.x.x+1)
```

### 8.4 업데이트 배포 주기

| 유형 | 주기 | 내용 |
|------|------|------|
| **정기 릴리스** | 월 1회 | 새 기능, 개선사항 |
| **패치 릴리스** | 필요시 | 버그 수정 |
| **보안 패치** | 즉시 | 보안 취약점 수정 |

### 8.5 지원 정책

#### 버전 지원 기간
```
현재 버전 (v1.2.x)     : 전체 지원
이전 버전 (v1.1.x)     : 보안 업데이트만 (6개월)
구버전 (v1.0.x 이하)   : 지원 종료
```

#### 지원 채널
- GitHub Issues (버그 리포트)
- 문서 사이트 (사용자 가이드)
- 이메일 지원 (기업 고객)

---

## 9. 일정 및 마일스톤

### 9.1 전체 일정 개요

```
┌─────────────────────────────────────────────────────────────┐
│                      프로젝트 타임라인                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: 리브랜딩 (2주)                                    │
│  ════════════════════                                       │
│  Week 1: 기반 작업 + 핵심 설정                              │
│  Week 2: 소스 코드 + 리소스 + 다국어                        │
│                                                             │
│  Phase 2: 인프라 구축 (2주)                                 │
│  ════════════════════════                                   │
│  Week 3: 업데이트 서버 + CI/CD 파이프라인                   │
│  Week 4: 문서 사이트 + Sentry 설정                          │
│                                                             │
│  Phase 3: 테스트 및 QA (1주)                                │
│  ═══════════════════════════                                │
│  Week 5: 전체 테스트 + 버그 수정                            │
│                                                             │
│  Phase 4: 베타 릴리스 (2주)                                 │
│  ═════════════════════════                                  │
│  Week 6-7: 베타 배포 + 피드백 수집                          │
│                                                             │
│  Phase 5: 정식 릴리스 (1주)                                 │
│  ═══════════════════════════                                │
│  Week 8: v1.0.0 릴리스                                      │
│                                                             │
│  총 기간: 약 8주                                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Phase별 상세 일정

#### Phase 1: 리브랜딩 (Week 1-2)

| 주차 | 일 | 작업 항목 | 담당 |
|------|-----|----------|------|
| W1 | D1-2 | 라이선스/저작권 업데이트, 아이콘 준비 | 법무/디자인 |
| W1 | D3-4 | package.json, electron-builder.json 수정 | 개발 |
| W1 | D5 | 빌드 테스트 | 개발 |
| W2 | D1-2 | 소스 코드 브랜드명 변경 | 개발 |
| W2 | D3 | GPO, Linux desktop 파일 수정 | 개발 |
| W2 | D4-5 | i18n 파일 업데이트, 문서 작성 | 개발 |

#### Phase 2: 인프라 구축 (Week 3-4)

| 주차 | 일 | 작업 항목 | 담당 |
|------|-----|----------|------|
| W3 | D1-3 | 업데이트 서버 구축 | 인프라 |
| W3 | D4-5 | CI/CD 파이프라인 설정 | DevOps |
| W4 | D1-2 | 문서 사이트 구축 | 개발 |
| W4 | D3-4 | Sentry 프로젝트 설정 | 개발 |
| W4 | D5 | 인프라 통합 테스트 | 전체 |

#### Phase 3: 테스트 및 QA (Week 5)

| 일 | 작업 항목 | 담당 |
|-----|----------|------|
| D1-2 | 유닛 테스트 보완 | 개발 |
| D3 | E2E 테스트 실행 | QA |
| D4 | 수동 테스트 (Windows, macOS, Linux) | QA |
| D5 | 버그 수정 | 개발 |

#### Phase 4: 베타 릴리스 (Week 6-7)

| 주차 | 일 | 작업 항목 | 담당 |
|------|-----|----------|------|
| W6 | D1-2 | 베타 빌드 및 서명 | DevOps |
| W6 | D3-5 | 내부 베타 배포 | 전체 |
| W7 | D1-3 | 피드백 수집 및 분석 | PM |
| W7 | D4-5 | 주요 이슈 수정 | 개발 |

#### Phase 5: 정식 릴리스 (Week 8)

| 일 | 작업 항목 | 담당 |
|-----|----------|------|
| D1-2 | 최종 빌드 및 서명 | DevOps |
| D3 | 릴리스 노트 작성 | PM |
| D4 | 업데이트 서버 배포 | 인프라 |
| D5 | 공지 및 문서 공개 | 마케팅 |

### 9.3 마일스톤

| 마일스톤 | 목표일 | 산출물 |
|----------|--------|--------|
| **M1: 리브랜딩 완료** | Week 2 | 브랜딩 변경된 빌드 |
| **M2: 인프라 구축** | Week 4 | 업데이트 서버, CI/CD |
| **M3: QA 완료** | Week 5 | 테스트 리포트 |
| **M4: 베타 릴리스** | Week 6 | v1.0.0-beta.1 |
| **M5: 정식 릴리스** | Week 8 | v1.0.0 |

### 9.4 리스크 관리

| 리스크 | 영향 | 대응 방안 |
|--------|------|-----------|
| 아이콘 디자인 지연 | 높음 | 임시 아이콘으로 개발 진행 |
| 코드 서명 인증서 발급 지연 | 높음 | 사전에 발급 프로세스 시작 |
| 인프라 구축 지연 | 중간 | 클라우드 서비스 활용 검토 |
| 베타 테스트 중 크리티컬 버그 | 중간 | 릴리스 일정 조정 버퍼 확보 |

---

## 부록

### A. 체크리스트 요약

#### 릴리스 전 체크리스트
- [ ] 모든 리브랜딩 작업 완료
- [ ] 라이선스/저작권 검토 완료
- [ ] 코드 서명 인증서 준비
- [ ] 업데이트 서버 가동 확인
- [ ] 모든 플랫폼 빌드 성공
- [ ] QA 테스트 통과
- [ ] 릴리스 노트 작성
- [ ] 문서 사이트 업데이트

#### 인프라 체크리스트
- [ ] 업데이트 서버 URL 확정
- [ ] SSL 인증서 설정
- [ ] CDN 연동 (선택)
- [ ] Sentry DSN 발급
- [ ] 문서 사이트 도메인 설정

### B. 참고 자료

| 자료 | URL |
|------|-----|
| Mattermost Desktop 배포 가이드 | https://docs.mattermost.com/deployment/desktop-app-deployment.html |
| electron-builder 문서 | https://www.electron.build/ |
| electron-updater 문서 | https://www.electron.build/auto-update |
| Apple 공증 가이드 | https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution |

---

*문서 작성일: 2026-01-04*
*최종 업데이트: 2026-01-04*

