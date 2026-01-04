# Mattermost Desktop 아키텍처 문서

> 이 문서는 OKRBest Desktop (Mattermost Desktop 기반) 프로젝트의 전체 아키텍처를 설명합니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [저장소/빌드/실행 정보](#2-저장소빌드실행-정보)
3. [디렉터리 구조 맵](#3-디렉터리-구조-맵)
4. [실행 흐름 (런타임 플로우)](#4-실행-흐름-런타임-플로우)
5. [핵심 모듈/컴포넌트 설명](#5-핵심-모듈컴포넌트-설명)
6. [데이터 모델/저장소 접근](#6-데이터-모델저장소-접근)
7. [외부 연동/인터페이스](#7-외부-연동인터페이스)
8. [설정/구성 (Configurability)](#8-설정구성-configurability)
9. [에러 처리/로깅/관측성 (Observability)](#9-에러-처리로깅관측성-observability)
10. [테스트 구조와 품질 게이트](#10-테스트-구조와-품질-게이트)
11. [변경 포인트 가이드](#11-변경-포인트-가이드)
12. [보안 아키텍처](#12-보안-아키텍처)
13. [성능 모니터링](#13-성능-모니터링)
14. [국제화 (i18n)](#14-국제화-i18n)

---

## 1. 프로젝트 개요

### 1.1 소개

Mattermost Desktop은 [Electron](https://www.electronjs.org/) 기반의 크로스 플랫폼 데스크톱 애플리케이션입니다. Mattermost 서버와 연동하여 실시간 팀 커뮤니케이션을 제공합니다.

### 1.2 기술 스택

| 분류 | 기술 |
|------|------|
| **프레임워크** | Electron 38.x |
| **언어** | TypeScript 5.3 |
| **UI 라이브러리** | React 17.x |
| **빌드 도구** | Webpack 5.x |
| **패키징** | electron-builder 24.x |
| **테스트** | Jest (Unit), Playwright (E2E) |
| **에러 추적** | Sentry |
| **로깅** | electron-log |

### 1.3 지원 플랫폼

- **Windows**: x64, arm64 (NSIS, MSI, ZIP)
- **macOS**: x64, arm64, Universal (DMG, ZIP, Mac App Store)
- **Linux**: x64, arm64 (deb, rpm, tar.gz, AppImage)

---

## 2. 저장소/빌드/실행 정보

### 2.1 필수 요구사항

```bash
Node.js >= 18.0.0
npm (Node.js에 포함)
```

### 2.2 설치 및 빌드

```bash
# 의존성 설치
npm install

# 개발 빌드
npm run build

# 프로덕션 빌드
npm run build-prod

# 개발 모드 실행
npm run start

# 파일 변경 감시 모드 (Hot Reload)
npm run watch
```

### 2.3 패키징 명령어

```bash
# 전체 플랫폼 패키징
npm run package

# 플랫폼별 패키징
npm run package:windows    # Windows (zip, nsis, msi)
npm run package:mac        # macOS (dmg, zip)
npm run package:mas        # Mac App Store
npm run package:linux      # Linux (deb, rpm, tar.gz, appimage)
```

### 2.4 주요 npm 스크립트

| 스크립트 | 설명 |
|----------|------|
| `npm run check` | 린트 + 타입체크 + 유닛테스트 |
| `npm run lint:js` | ESLint 실행 |
| `npm run fix:js` | ESLint 자동 수정 |
| `npm run test:unit` | Jest 유닛 테스트 |
| `npm run e2e` | E2E 테스트 실행 |
| `npm run clean` | 빌드 산출물 정리 |

### 2.5 빌드 출력 경로

| 출력물 | 경로 |
|--------|------|
| 컴파일된 소스 | `dist/` |
| 패키지 산출물 | `release/` |

---

## 3. 디렉터리 구조 맵

```
okrbest-desktop/
├── src/                          # 소스 코드 루트
│   ├── main/                     # [Main Process] Electron 메인 프로세스
│   │   ├── app/                  # 앱 초기화 및 라이프사이클
│   │   │   ├── index.ts          # 진입점
│   │   │   ├── initialize.ts     # 초기화 로직
│   │   │   ├── app.ts            # 앱 이벤트 핸들러
│   │   │   ├── config.ts         # 설정 핸들러
│   │   │   ├── intercom.ts       # IPC 통신 핸들러
│   │   │   └── windows.ts        # 윈도우 관리
│   │   ├── autoUpdater.ts        # 자동 업데이트 관리
│   │   ├── downloadsManager.ts   # 다운로드 관리
│   │   ├── i18nManager.ts        # 다국어 관리
│   │   ├── notifications/        # 알림 시스템
│   │   ├── security/             # 보안 관련 모듈
│   │   └── server/               # 서버 연동 로직
│   │
│   ├── renderer/                 # [Renderer Process] UI 렌더링
│   │   ├── components/           # React 컴포넌트
│   │   │   ├── MainPage.tsx      # 메인 페이지
│   │   │   ├── SettingsModal/    # 설정 모달
│   │   │   ├── ServerDropdownButton/ # 서버 선택 드롭다운
│   │   │   ├── TabBar/           # 탭 바
│   │   │   └── ...
│   │   ├── css/                  # 스타일시트 (SCSS)
│   │   ├── hooks/                # React 커스텀 훅
│   │   ├── modals/               # 모달 컴포넌트
│   │   └── index.tsx             # Renderer 진입점
│   │
│   ├── common/                   # [공유 코드] Main/Renderer 공유
│   │   ├── config/               # 설정 관리 시스템
│   │   │   ├── index.ts          # Config 클래스
│   │   │   ├── buildConfig.ts    # 빌드 설정
│   │   │   ├── defaultPreferences.ts # 기본 설정값
│   │   │   └── RegistryConfig.ts # Windows 레지스트리 설정
│   │   ├── servers/              # 서버 관리
│   │   │   ├── serverManager.ts  # 서버 매니저 싱글톤
│   │   │   └── MattermostServer.ts # 서버 모델
│   │   ├── communication.ts      # IPC 채널 상수 정의
│   │   ├── log.ts                # 로깅 유틸리티
│   │   └── Validator.ts          # 설정 검증
│   │
│   ├── app/                      # [애플리케이션 계층]
│   │   ├── mainWindow/           # 메인 윈도우 관리
│   │   ├── views/                # BrowserView 관리
│   │   ├── menus/                # 메뉴 바 관리
│   │   ├── preload/              # Preload 스크립트
│   │   │   ├── externalAPI.ts    # 웹앱과의 API 연동
│   │   │   └── internalAPI.js    # 내부 API
│   │   ├── system/               # 시스템 연동 (트레이, 배지)
│   │   └── tabs/                 # 탭 관리
│   │
│   ├── types/                    # TypeScript 타입 정의
│   ├── assets/                   # 정적 리소스 (아이콘, 이미지)
│   └── jest/                     # Jest 테스트 설정
│
├── e2e/                          # E2E 테스트
│   ├── specs/                    # 테스트 스펙
│   ├── modules/                  # 테스트 모듈
│   └── utils/                    # 테스트 유틸리티
│
├── i18n/                         # 다국어 번역 파일 (JSON)
├── scripts/                      # 빌드/배포 스크립트
├── resources/                    # 플랫폼별 리소스
├── patches/                      # npm 패키지 패치
├── api-types/                    # Desktop API 타입 정의
│
├── webpack.config.*.js           # Webpack 설정 파일들
├── electron-builder.json         # electron-builder 설정
├── tsconfig.json                 # TypeScript 설정
└── package.json                  # 프로젝트 메타데이터
```

---

## 4. 실행 흐름 (런타임 플로우)

### 4.1 앱 시작 시퀀스

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Application Startup Flow                          │
└─────────────────────────────────────────────────────────────────────────┘

[진입점: src/main/app/index.ts]
           │
           ▼
    ┌──────────────┐
    │ initialize() │
    └──────┬───────┘
           │
           ├─────► initializeArgs()        ─► 커맨드라인 인자 파싱
           │
           ├─────► initializeConfig()      ─► 설정 파일 로드 (config.json)
           │                                   └► 이벤트 리스너 등록
           │                                   └► 하드웨어 가속 설정
           │                                   └► Sentry 초기화
           │
           ├─────► initializeAppEventListeners() ─► Electron 앱 이벤트 바인딩
           │
           ├─────► initializeBeforeAppReady()    ─► 단일 인스턴스 잠금
           │                                       └► 프로토콜 핸들러 등록
           │                                       └► Tray 이미지 로드
           │
           ▼
    ┌──────────────────────┐
    │ app.whenReady() 대기 │
    │ Config.initRegistry()│  (병렬 실행)
    └──────────┬───────────┘
               │
               ▼
    ┌───────────────────────────────────────┐
    │  initializeInterCommunicationEventListeners()  │
    │  ─► IPC 핸들러 등록                            │
    └───────────────────┬───────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │       initializeAfterAppReady()       │
    │  ─► 프로토콜 핸들러 등록              │
    │  ─► 보안 스토리지 초기화              │
    │  ─► MainWindow.show()                 │
    │  ─► ServerManager.init()              │
    │  ─► NavigationManager.init()          │
    │  ─► Tray.init()                       │
    │  ─► MenuManager.refreshMenu()         │
    │  ─► PerformanceMonitor.init()         │
    └───────────────────────────────────────┘
```

### 4.2 IPC 통신 흐름

```
┌─────────────────┐     IPC Channel      ┌─────────────────┐
│  Main Process   │◄───────────────────►│ Renderer Process │
│                 │                      │                  │
│ - Config        │  GET_CONFIGURATION   │ - React UI      │
│ - ServerManager │  UPDATE_CONFIGURATION│ - Components    │
│ - AutoUpdater   │  NOTIFY_MENTION      │ - Hooks         │
│ - Downloads     │  USER_ACTIVITY_UPDATE│                  │
│ - Notifications │  ...                 │                  │
└─────────────────┘                      └─────────────────┘
         │
         │ Preload Script (contextBridge)
         ▼
┌─────────────────────────────────────────┐
│           BrowserView (WebApp)          │
│  - Mattermost 웹 애플리케이션 로드       │
│  - Desktop API 노출 (externalAPI.ts)    │
└─────────────────────────────────────────┘
```

### 4.3 서버 전환 흐름

```
[사용자 서버 선택]
        │
        ▼
ServerDropdownButton.onClick()
        │
        ▼
ipcRenderer.send(SWITCH_SERVER, serverId)
        │
        ▼
[Main Process]
NavigationManager.handleSwitchServer()
        │
        ├─► ServerManager.updateCurrentServer()
        │
        └─► WebContentsManager.showServerView()
                │
                └─► BrowserView 전환 및 URL 로드
```

---

## 5. 핵심 모듈/컴포넌트 설명

### 5.1 Main Process 모듈

#### Config (`src/common/config/index.ts`)
- **역할**: 애플리케이션 설정 관리
- **기능**: 
  - 로컬 설정 파일 로드/저장
  - Windows 레지스트리 설정 읽기
  - 빌드 설정과 사용자 설정 병합
  - 설정 변경 이벤트 발생

```typescript
// 설정 접근 예시
Config.darkMode           // boolean
Config.enableAutoUpdater  // boolean
Config.servers            // ConfigServer[]
```

#### ServerManager (`src/common/servers/serverManager.ts`)
- **역할**: 연결된 서버 인스턴스 관리
- **기능**:
  - 서버 추가/편집/삭제
  - 현재 활성 서버 관리
  - 서버 순서 관리
  - 서버 원격 정보 캐싱

```typescript
// 주요 메서드
ServerManager.addServer(server)
ServerManager.removeServer(serverId)
ServerManager.getOrderedServers()
ServerManager.updateCurrentServer(serverId)
```

#### MainWindow (`src/app/mainWindow/mainWindow.ts`)
- **역할**: 메인 BrowserWindow 관리
- **기능**:
  - 윈도우 생성 및 상태 관리
  - 최소화/최대화/전체화면 처리
  - 윈도우 위치 및 크기 저장/복원

#### NavigationManager (`src/app/navigationManager.ts`)
- **역할**: 앱 내 네비게이션 관리
- **기능**:
  - 서버/탭 전환 처리
  - 딥링크 URL 처리
  - 브라우저 히스토리 관리

#### WebContentsManager (`src/app/views/webContentsManager.ts`)
- **역할**: BrowserView 인스턴스 관리
- **기능**:
  - 서버별 BrowserView 생성/관리
  - 뷰 전환 및 표시
  - 웹 콘텐츠 이벤트 처리

### 5.2 Renderer Process 컴포넌트

#### MainPage (`src/renderer/components/MainPage.tsx`)
- 메인 UI 레이아웃 컴포넌트
- 탭바, 서버 드롭다운, 콘텐츠 영역 통합

#### SettingsModal (`src/renderer/components/SettingsModal/`)
- 사용자 설정 UI
- 서버 관리, 알림, 언어, 다운로드 경로 등 설정

#### TabBar (`src/renderer/components/TabBar/`)
- 서버 탭 표시 및 전환 UI
- 드래그 앤 드롭 순서 변경 지원

#### ConfigureServer (`src/renderer/components/ConfigureServer/`)
- 서버 추가/편집 폼

### 5.3 Preload 스크립트

#### externalAPI.ts (`src/app/preload/externalAPI.ts`)
- Mattermost 웹앱에 노출되는 Desktop API
- `contextBridge`를 통한 안전한 API 노출

```typescript
// 웹앱에서 접근 가능한 API
window.desktop.getAppInfo()
window.desktop.isDev()
window.desktop.onUserActivityUpdate(callback)
// ...
```

---

## 6. 데이터 모델/저장소 접근

### 6.1 설정 데이터 구조

```typescript
// src/types/config.ts - CurrentConfig (ConfigV4)
interface ConfigV4 {
  version: 4;
  servers: ConfigServer[];           // 연결된 서버 목록
  showTrayIcon: boolean;             // 트레이 아이콘 표시
  trayIconTheme: string;             // 트레이 아이콘 테마
  minimizeToTray: boolean;           // 트레이로 최소화
  notifications: {
    flashWindow: number;             // 윈도우 깜빡임
    bounceIcon: boolean;             // 독 아이콘 바운스 (macOS)
    bounceIconType: '' | 'critical' | 'informational';
  };
  showUnreadBadge: boolean;          // 읽지 않은 배지 표시
  useSpellChecker: boolean;          // 맞춤법 검사 사용
  enableHardwareAcceleration: boolean; // 하드웨어 가속
  autostart: boolean;                // 자동 시작
  darkMode: boolean;                 // 다크 모드
  downloadLocation?: string;         // 다운로드 위치
  appLanguage?: string;              // 앱 언어
  enableSentry?: boolean;            // Sentry 에러 추적
  // ...
}
```

### 6.2 서버 데이터 구조

```typescript
// src/types/config.ts
interface Server {
  name: string;   // 서버 표시명
  url: string;    // 서버 URL
}

interface ConfigServer extends Server {
  order: number;  // 표시 순서
}

// src/common/servers/MattermostServer.ts
class MattermostServer {
  id: string;           // 고유 ID (UUID)
  name: string;
  url: URL;
  isPredefined: boolean; // 사전 정의 서버 여부
  isLoggedIn: boolean;   // 로그인 상태
  theme?: Theme;         // 서버 테마
  preAuthSecret?: string; // Pre-auth 시크릿
}
```

### 6.3 저장 위치

| 데이터 | 위치 | 포맷 |
|--------|------|------|
| 사용자 설정 | `{userData}/config.json` | JSON |
| 로그 파일 | `{userData}/logs/` | 텍스트 |
| 다운로드 상태 | `{userData}/downloads.json` | JSON |
| 앱 버전 정보 | `{userData}/app-state.json` | JSON |

**userData 경로**:
- Windows: `%APPDATA%\Mattermost`
- macOS: `~/Library/Application Support/Mattermost`
- Linux: `~/.config/Mattermost`

### 6.4 JsonFileManager

```typescript
// src/common/JsonFileManager.ts
class JsonFileManager<T> {
  constructor(filePath: string);
  get json(): T;           // 동기 읽기
  setJson(data: T): Promise<void>;  // 비동기 저장
}
```

---

## 7. 외부 연동/인터페이스

### 7.1 자동 업데이트 (`src/main/autoUpdater.ts`)

- **라이브러리**: `electron-updater`
- **업데이트 서버**: `https://releases.mattermost.com/desktop`
- **지원 포맷**: NSIS (Windows), AppImage (Linux)

```typescript
// 업데이트 이벤트
UPDATE_AVAILABLE     // 새 버전 감지
UPDATE_DOWNLOADED    // 다운로드 완료
UPDATE_PROGRESS      // 다운로드 진행률
NO_UPDATE_AVAILABLE  // 최신 버전
```

### 7.2 알림 시스템 (`src/main/notifications/`)

```
notifications/
├── index.ts      # 알림 매니저
├── Mention.ts    # 멘션 알림
├── Download.ts   # 다운로드 알림
├── Upgrade.ts    # 업그레이드 알림
├── dnd-windows.ts # Windows 방해금지 모드
└── dnd-linux.ts   # Linux 방해금지 모드
```

### 7.3 딥링킹

- **프로토콜**: `mattermost://`
- **처리**: `NavigationManager.openLinkInPrimaryTab()`

```
mattermost://server.com/team/channel
           │
           ▼
   URL 파싱 → 서버 매칭 → 해당 서버 탭에서 열기
```

### 7.4 Windows 레지스트리 연동

```typescript
// src/common/config/RegistryConfig.ts
// GPO(그룹 정책) 설정 읽기
HKLM\Software\Policies\Mattermost\
├── DefaultServers    // 기본 서버 목록
├── EnableServerManagement  // 서버 관리 허용 여부
└── EnableAutoUpdater       // 자동 업데이트 허용 여부
```

### 7.5 Mattermost 웹앱 Desktop API

웹앱에서 데스크톱 앱 기능 접근:

```typescript
// 웹앱에서 사용
if (window.desktop) {
  window.desktop.getAppInfo();
  window.desktop.onBrowserHistoryPush(callback);
  window.desktop.requestNotificationPermission();
  window.desktop.sendNotification(title, body, channel);
}
```

---

## 8. 설정/구성 (Configurability)

### 8.1 설정 계층 구조

```
우선순위 (높음 → 낮음)
├── Windows Registry (GPO)     ─► 관리자 정책
├── Build Config               ─► 빌드 시점 설정
├── Local Config (config.json) ─► 사용자 설정
└── Default Preferences        ─► 기본값
```

### 8.2 빌드 설정 (`src/common/config/buildConfig.ts`)

```typescript
const buildConfig: BuildConfig = {
  defaultServers: [],              // 기본 서버 (빈 배열)
  helpLink: 'https://...',         // 도움말 링크
  enableServerManagement: true,    // 서버 관리 허용
  enableAutoUpdater: true,         // 자동 업데이트 허용
  managedResources: [],            // 관리 리소스
  allowedProtocols: [              // 허용 프로토콜
    'http', 'https', 'ftp', 'mailto', 'tel'
  ],
};
```

### 8.3 환경 변수 / 빌드 플래그

| 변수 | 설명 |
|------|------|
| `NODE_ENV` | `development` / `production` / `test` |
| `__CAN_UPGRADE__` | 업그레이드 가능 여부 |
| `__IS_MAC_APP_STORE__` | Mac App Store 빌드 |
| `__IS_NIGHTLY_BUILD__` | 나이틀리 빌드 |
| `__SENTRY_DSN__` | Sentry DSN |
| `__DISABLE_GPU__` | GPU 비활성화 |

### 8.4 커맨드라인 인자

```bash
# 데이터 디렉터리 변경
./mattermost-desktop --args --data-dir ~/custom-data/

# 개발 모드 비활성화
./mattermost-desktop --disable-dev-mode
```

---

## 9. 에러 처리/로깅/관측성 (Observability)

### 9.1 로깅 시스템

**라이브러리**: `electron-log`

```typescript
// src/common/log.ts
import { Logger } from 'common/log';

const log = new Logger('ModuleName');
log.error('에러 메시지');
log.warn('경고 메시지');
log.info('정보 메시지');
log.debug('디버그 메시지');
log.silly('상세 메시지');
```

**로그 레벨 설정**:
```typescript
setLoggingLevel('debug'); // error, warn, info, verbose, debug, silly
```

**로그 파일 위치**: `{userData}/logs/main.log`

### 9.2 에러 추적 - Sentry

```typescript
// src/main/sentryHandler.ts
class SentryHandler {
  init()                        // 초기화 (프로덕션에서만 활성화)
  captureException(error: Error) // 에러 전송
}
```

**전송 조건**:
- `NODE_ENV === 'production'`
- `Config.enableSentry === true`

**컨텍스트 정보**:
- 앱 버전, Electron 버전
- 플랫폼, 아키텍처
- 메모리 상태

### 9.3 크리티컬 에러 핸들러

```typescript
// src/main/CriticalErrorHandler.ts
class CriticalErrorHandler {
  init()                       // uncaughtException, unhandledRejection 핸들러 등록
  handleUncaughtException(err) // 복구 불가능 에러 처리
}
```

### 9.4 진단 도구

```
src/main/diagnostics/
├── DiagnosticsReport.ts    // 진단 리포트 생성
└── README.md               // 진단 가이드
```

---

## 10. 테스트 구조와 품질 게이트

### 10.1 유닛 테스트 (Jest)

**설정**: `package.json` 내 `jest` 설정

```bash
# 유닛 테스트 실행
npm run test:unit

# 커버리지 포함
npm run test:unit-coverage
```

**테스트 파일 위치**: 소스 파일과 같은 위치
```
src/main/
├── autoUpdater.ts
├── autoUpdater.test.ts    # 테스트 파일
├── i18nManager.ts
├── i18nManager.test.js
└── ...
```

**커버리지 대상**:
- `src/common/**/*.ts`
- `src/main/**/*.ts`

### 10.2 E2E 테스트 (Playwright)

**위치**: `e2e/`

```bash
# E2E 테스트 실행
npm run e2e
```

**테스트 스펙 구조**:
```
e2e/specs/
├── server_management/  # 서버 관리 테스트
├── settings/           # 설정 테스트
├── downloads/          # 다운로드 테스트
├── deep_linking/       # 딥링크 테스트
├── menu_bar/           # 메뉴 바 테스트
├── startup/            # 시작 테스트
└── ...
```

### 10.3 품질 게이트

```bash
# 전체 검사 (CI 파이프라인)
npm run check
# 실행 내용:
#   - lint:js-quiet (ESLint)
#   - check-build-config (빌드 설정 검증)
#   - check-types (TypeScript 타입 체크)
#   - test:unit (유닛 테스트)
```

### 10.4 린트 규칙

- ESLint + `@mattermost/eslint-plugin`
- React Hooks 규칙 적용
- TypeScript 엄격 모드

---

## 11. 변경 포인트 가이드

### 11.1 새 서버 설정 추가하기

1. **타입 정의**: `src/types/config.ts`의 `ConfigV4` 수정
2. **기본값 설정**: `src/common/config/defaultPreferences.ts`
3. **UI 추가**: `src/renderer/components/SettingsModal/`
4. **마이그레이션**: `src/common/config/upgradePreferences.ts` (버전 업)

### 11.2 새 IPC 채널 추가하기

1. **채널 상수**: `src/common/communication.ts`에 상수 추가
2. **Main 핸들러**: `src/main/app/initialize.ts`에 핸들러 등록
3. **Renderer 호출**: `ipcRenderer.invoke(CHANNEL_NAME)`

### 11.3 새 알림 타입 추가하기

1. `src/main/notifications/`에 새 알림 클래스 생성
2. `index.ts`에서 export
3. 필요한 곳에서 import 및 사용

### 11.4 새 언어 추가하기

1. `i18n/` 폴더에 `{locale}.json` 파일 생성
2. `i18n/i18n.ts`에 언어 등록
3. 번역 문자열 추가

### 11.5 플랫폼별 기능 추가하기

```typescript
// 플랫폼 분기 예시
if (process.platform === 'win32') {
  // Windows 전용 로직
} else if (process.platform === 'darwin') {
  // macOS 전용 로직
} else {
  // Linux 전용 로직
}
```

### 11.6 주요 수정 시 체크리스트

- [ ] TypeScript 타입 체크 통과
- [ ] ESLint 규칙 준수
- [ ] 유닛 테스트 추가/수정
- [ ] E2E 테스트 영향 확인
- [ ] 다국어 문자열 추가 (해당 시)
- [ ] 설정 마이그레이션 필요 여부 확인

---

## 12. 보안 아키텍처

### 12.1 샌드박스 및 컨텍스트 격리

```typescript
// Main Process에서 활성화
app.enableSandbox(); // 렌더러 프로세스 샌드박스화

// BrowserWindow 옵션
webPreferences: {
  contextIsolation: true,     // 컨텍스트 격리
  nodeIntegration: false,     // Node.js 접근 차단
  preload: preloadPath,       // Preload 스크립트로 제한된 API만 노출
}
```

### 12.2 Preload 스크립트 보안

```typescript
// contextBridge를 통한 안전한 API 노출
contextBridge.exposeInMainWorld('desktop', {
  getAppInfo: () => ipcRenderer.invoke(GET_APP_INFO),
  // ... 필요한 API만 명시적으로 노출
});
```

### 12.3 CSP (Content Security Policy)

```typescript
// 내부 페이지용 CSP 헤더
'Content-Security-Policy': [
  `default-src 'self'; style-src 'self' 'nonce-${nonce}'; ...`
]
```

### 12.4 프로토콜 허용 목록

```typescript
// src/common/config/buildConfig.ts
allowedProtocols: ['http', 'https', 'ftp', 'mailto', 'tel']
```

### 12.5 인증서 검증

```typescript
// src/main/app/app.ts
app.on('certificate-error', handleAppCertificateError);
// 자체 서명 인증서 처리 로직
```

### 12.6 권한 관리

```typescript
// src/main/security/permissionsManager.ts
class PermissionsManager {
  handlePermissionRequest(webContents, permission, callback);
  // 카메라, 마이크, 알림 등 권한 처리
}
```

---

## 13. 성능 모니터링

### 13.1 PerformanceMonitor (`src/main/performanceMonitor.ts`)

- CPU 사용량 추적
- 메모리 사용량 추적
- 메트릭 수집 및 리포트

### 13.2 하드웨어 가속

```typescript
// GPU 가속 비활성화 옵션
if (Config.enableHardwareAcceleration === false) {
  app.disableHardwareAcceleration();
}
```

### 13.3 비동기 로깅

```typescript
// 메인 스레드 블로킹 방지
log.transports.file.sync = false;
```

---

## 14. 국제화 (i18n)

### 14.1 지원 언어

`i18n/` 폴더에 60개 이상의 언어 파일 존재:
- 한국어 (`ko.json`)
- 영어 (`en.json`)
- 일본어 (`ja.json`)
- 중국어 간체/번체 (`zh-CN.json`, `zh-TW.json`)
- 그 외 다수

### 14.2 번역 관리

```typescript
// src/main/i18nManager.ts
class I18nManager {
  setLocale(locale: string): boolean;
  getLocale(): string;
  localizeMessage(id: string, defaultMessage: string): string;
}
```

### 14.3 React에서 사용

```tsx
// react-intl 사용
import { FormattedMessage, useIntl } from 'react-intl';

// 컴포넌트에서
<FormattedMessage id="settings.title" defaultMessage="Settings" />

// Hook으로
const intl = useIntl();
intl.formatMessage({ id: 'settings.title' });
```

### 14.4 번역 추출

```bash
npm run i18n-extract  # 소스에서 번역 키 추출
```

---

## 부록: 주요 파일 참조

| 목적 | 파일 경로 |
|------|----------|
| 앱 진입점 | `src/main/app/index.ts` |
| 초기화 로직 | `src/main/app/initialize.ts` |
| 설정 관리 | `src/common/config/index.ts` |
| 서버 관리 | `src/common/servers/serverManager.ts` |
| IPC 채널 | `src/common/communication.ts` |
| 타입 정의 | `src/types/` |
| 빌드 설정 | `webpack.config.*.js` |
| 패키징 설정 | `electron-builder.json` |
| 테스트 설정 | `package.json` (jest section) |
| E2E 테스트 | `e2e/specs/` |

---

*문서 최종 업데이트: 2026-01-04*

