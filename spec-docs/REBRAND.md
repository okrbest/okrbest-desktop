# OKR Best 리브랜딩 가이드

> Mattermost Desktop을 OKR Best로 리브랜딩하기 위한 종합 가이드입니다.

---

## 목차

1. [개요](#1-개요)
2. [라이선스 준수 요구사항](#2-라이선스-준수-요구사항)
3. [브랜드 변경 체크리스트](#3-브랜드-변경-체크리스트)
4. [검색/치환 패턴](#4-검색치환-패턴)
5. [아이콘 교체 가이드](#5-아이콘-교체-가이드)
6. [자체 인프라 설정](#6-자체-인프라-설정)
7. [단계별 실행 가이드](#7-단계별-실행-가이드)

---

## 1. 개요

### 1.1 리브랜딩 범위

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 제품명 | Mattermost Desktop | OKR Best |
| 패키지명 | mattermost-desktop | okrbest-desktop |
| 앱 ID | Mattermost.Desktop | OKRBest.Desktop |
| 프로토콜 | mattermost:// | okrbest:// |
| 데이터 디렉터리 | Mattermost | OKRBest |

### 1.2 변경 파일 통계

- **핵심 설정 파일**: ~10개
- **소스 코드 파일**: ~300개 이상
- **다국어 파일**: 60개 이상
- **리소스/이미지**: ~30개

---

## 2. 라이선스 준수 요구사항

이 프로젝트는 **Apache License 2.0** 하에 배포됩니다. 파생 작업물로서 다음 요구사항을 준수해야 합니다.

### 2.1 필수 유지 사항

#### LICENSE.txt 수정
원본 저작권 유지 + OKR Best 저작권 추가:

```
Copyright (c) 2015-2016 Yuya Ochiai
Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
Copyright (c) 2024-present OKR Best. All Rights Reserved.

                             Apache License
                       Version 2.0, January 2004
...
```

#### NOTICE.txt 수정
원본 NOTICE 유지 + 새로운 프로젝트 정보 추가:

```
OKR Best Desktop
Copyright (c) 2024-present OKR Best

This product includes software developed at Mattermost, Inc.
(https://mattermost.com/)

Based on Mattermost Desktop
Copyright (c) 2015-2016 Yuya Ochiai
Copyright (c) 2016-present Mattermost, Inc.

---
(기존 NOTICE.txt 내용 유지)
```

### 2.2 소스 파일 헤더

모든 수정된 소스 파일에 변경 표시 추가:

```typescript
// Copyright (c) 2015-2016 Yuya Ochiai
// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.
```

### 2.3 상표 관련 주의사항

- "Mattermost" 상표는 제품 설명에서 **출처 표시** 용도로만 사용 가능
- UI에서 Mattermost 브랜드 요소 제거 필수
- 아이콘/로고는 새로운 디자인으로 교체 필수

---

## 3. 브랜드 변경 체크리스트

### 3.1 패키지 메타데이터

#### [package.json](../package.json)

| 필드 | 현재값 | 변경값 |
|------|--------|--------|
| `name` | `mattermost-desktop` | `okrbest-desktop` |
| `productName` | `Mattermost` | `OKR Best` |
| `description` | `Mattermost` | `OKR Best Desktop Application` |
| `author` | `Mattermost, Inc. <feedback@mattermost.com>` | `OKR Best <contact@okrbest.com>` |
| `desktopName` | `Mattermost.Desktop` | `OKRBest.Desktop` |
| `homepage` | `https://mattermost.com` | `https://okrbest.com` |
| `repository.url` | `git://github.com/mattermost/desktop.git` | `(새 저장소 URL)` |

```json
{
  "name": "okrbest-desktop",
  "productName": "OKR Best",
  "version": "1.0.0",
  "description": "OKR Best Desktop Application",
  "author": "OKR Best <contact@okrbest.com>",
  "desktopName": "OKRBest.Desktop",
  "homepage": "https://okrbest.com",
  "repository": {
    "type": "git",
    "url": "(새 저장소 URL)"
  }
}
```

#### [api-types/package.json](../api-types/package.json)

| 필드 | 변경값 |
|------|--------|
| `name` | `@okrbest/desktop-api` |

#### [e2e/package.json](../e2e/package.json)

| 필드 | 변경값 |
|------|--------|
| `name` | `okrbest-desktop-e2e` |

---

### 3.2 빌드/패키징 설정

#### [electron-builder.json](../electron-builder.json)

```json
{
  "publish": [
    {
      "provider": "generic",
      "url": "https://releases.okrbest.com/desktop"  // 변경
    }
  ],
  "appId": "OKRBest.Desktop",  // 변경
  "protocols": [
    {
      "name": "OKR Best",  // 변경
      "schemes": ["okrbest"]  // 변경
    }
  ],
  "deb": {
    "synopsis": "OKR Best Desktop App"  // 변경
  },
  "linux": {
    "category": "Network;InstantMessaging"
  },
  "win": {
    "publisherName": "OKR Best"  // 변경
  }
}
```

**수정 필요 항목:**

| 경로 | 현재값 | 변경값 |
|------|--------|--------|
| `publish[0].url` | `https://releases.mattermost.com/desktop` | `{{UPDATE_SERVER_URL}}` |
| `appId` | `Mattermost.Desktop` | `OKRBest.Desktop` |
| `protocols[0].name` | `Mattermost` | `OKR Best` |
| `protocols[0].schemes[0]` | `mattermost` | `okrbest` |
| `deb.synopsis` | `Mattermost Desktop App` | `OKR Best Desktop App` |
| `win.publisherName` | `CN="Mattermost, Inc."...` | `CN="OKR Best"...` |

---

### 3.3 소스 코드 수정

#### 3.3.1 초기화 및 앱 설정

| 파일 | 수정 위치 | 변경 내용 |
|------|-----------|-----------|
| [src/main/app/initialize.ts](../src/main/app/initialize.ts) | Line 326 | `app.setAppUserModelId('OKRBest.Desktop')` |
| [src/main/constants.ts](../src/main/constants.ts) | 전체 | 앱 이름 관련 상수 |
| [src/renderer/constants.ts](../src/renderer/constants.ts) | 전체 | 앱 이름 관련 상수 |

#### 3.3.2 상수 및 외부 링크

| 파일 | [src/common/constants.ts](../src/common/constants.ts) |
|------|--------------------------------------------------------|

```typescript
// 변경 필요 항목
export const IS_ONLINE_ENDPOINT = 'https://api.okrbest.com/ping';  // 또는 제거

export const COOKIE_NAME_USER_ID = 'OKRUSERID';    // OKR Best 서버와 협의 필요
export const COOKIE_NAME_CSRF = 'OKRCSRF';
export const COOKIE_NAME_AUTH_TOKEN = 'OKRAUTHTOKEN';

export const DEFAULT_HELP_LINK = 'https://docs.okrbest.com/guides';
export const DEFAULT_ACADEMY_LINK = 'https://academy.okrbest.com/';
export const DEFAULT_TE_REPORT_PROBLEM_LINK = 'https://okrbest.com/report-bug';
export const DEFAULT_EE_REPORT_PROBLEM_LINK = 'https://support.okrbest.com/';
export const DEFAULT_UPGRADE_LINK = 'https://okrbest.com/desktop-upgrade';
export const DEFAULT_CHANGELOG_LINK = 'https://docs.okrbest.com/desktop-changelog';
```

#### 3.3.3 빌드 설정

| 파일 | [src/common/config/buildConfig.ts](../src/common/config/buildConfig.ts) |
|------|-------------------------------------------------------------------------|

```typescript
const buildConfig: BuildConfig = {
    defaultServers: [
    // OKR Best 기본 서버 추가 (선택사항)
    // {
    //   name: 'OKR Best',
    //   url: 'https://app.okrbest.com'
    // }
    ],
    helpLink: DEFAULT_HELP_LINK,
    academyLink: DEFAULT_ACADEMY_LINK,
    upgradeLink: DEFAULT_UPGRADE_LINK,
    enableServerManagement: true,
    enableAutoUpdater: true,
    managedResources: ['trusted'],
    allowedProtocols: [
        'okrbest',  // 변경
        'ftp',
        'mailto',
        'tel',
    ],
};
```

#### 3.3.4 레지스트리 설정 (Windows)

| 파일 | [src/common/config/RegistryConfig.ts](../src/common/config/RegistryConfig.ts) |
|------|-------------------------------------------------------------------------------|

```typescript
// 변경 필요
const REGISTRY_KEY = 'Software\\Policies\\OKRBest';  // Mattermost → OKRBest
```

#### 3.3.5 데이터 디렉터리

| 파일 | [src/common/config/defaultPreferences.ts](../src/common/config/defaultPreferences.ts) |
|------|----------------------------------------------------------------------------------------|

앱 데이터 디렉터리 이름 변경:
- Windows: `%APPDATA%\OKRBest`
- macOS: `~/Library/Application Support/OKRBest`
- Linux: `~/.config/OKRBest`

> **참고**: Electron의 `app.name`이 이를 결정하므로 `package.json`의 `productName` 변경으로 자동 적용됩니다.

---

### 3.4 프로토콜 핸들러

`mattermost://` 프로토콜을 `okrbest://`로 변경합니다.

#### 영향 받는 파일 목록

```
src/main/app/initialize.ts
src/common/config/buildConfig.ts
electron-builder.json
src/assets/linux/create_desktop_file.sh
resources/windows/gpo/mattermost.admx
```

#### 검색 패턴
```bash
grep -r "mattermost://" --include="*.ts" --include="*.js" --include="*.json" --include="*.sh"
grep -r "mattermost-dev://" --include="*.ts" --include="*.js"
```

---

### 3.5 Windows GPO/레지스트리

#### [resources/windows/gpo/mattermost.admx](../resources/windows/gpo/mattermost.admx)

**파일명 변경**: `mattermost.admx` → `okrbest.admx`

```xml
<?xml version="1.0" encoding="utf-8"?>
<policyDefinitions revision="0.1" schemaVersion="1.0">
    <policyNamespaces>
        <target prefix="okrbest" namespace="OKRBest.Policies"/>  <!-- 변경 -->
    </policyNamespaces>
    <categories>
        <category displayName="$(string.okrbest)" name="okrbest"/>  <!-- 변경 -->
    </categories>
    <policies>
        <policy name="EnableAutoUpdater" ... key="Software\Policies\OKRBest" ...>  <!-- 변경 -->
        <!-- 나머지 정책들도 동일하게 변경 -->
    </policies>
</policyDefinitions>
```

#### [resources/windows/gpo/en-US/mattermost.adml](../resources/windows/gpo/en-US/mattermost.adml)

**파일명 변경**: `mattermost.adml` → `okrbest.adml`

```xml
<stringTable>
    <string id="RequiresOKRBest43">Requires OKR Best Desktop 1.0 or later</string>
    <string id="okrbest">OKR Best</string>
    <!-- 나머지 문자열 변경 -->
</stringTable>
```

---

### 3.6 Linux 데스크톱 통합

#### [src/assets/linux/create_desktop_file.sh](../src/assets/linux/create_desktop_file.sh)

```bash
#!/bin/sh
set -e
WORKING_DIR=`pwd`
THIS_PATH=`readlink -f $0`
cd `dirname ${THIS_PATH}`
FULL_PATH=`pwd`
cd "${WORKING_DIR}"
cat <<EOS > OKRBest.desktop
[Desktop Entry]
Name=OKR Best
Comment=OKR Best Desktop application for Linux
Exec="${FULL_PATH}/okrbest-desktop" %U
Terminal=false
Type=Application
MimeType=x-scheme-handler/okrbest
Icon=${FULL_PATH}/app_icon.png
Categories=Network;InstantMessaging;
EOS
chmod +x OKRBest.desktop
```

---

### 3.7 다국어 파일 (i18n)

60개 이상의 언어 파일에서 브랜드명 변경이 필요합니다.

#### 영향 받는 파일
```
i18n/en.json
i18n/ko.json
i18n/ja.json
i18n/zh-CN.json
i18n/zh-TW.json
... (모든 *.json 파일)
```

#### 변경 대상 문자열 예시

**[i18n/en.json](../i18n/en.json)**
```json
{
  "main.menus.app.about": "About OKR Best",
  "main.menus.app.name": "OKR Best",
  "renderer.settings.page.header": "OKR Best Settings",
  // ... 기타 Mattermost 언급 부분
}
```

#### 검색 명령
```bash
grep -r "Mattermost" i18n/ --include="*.json"
grep -r "mattermost" i18n/ --include="*.json"
```

---

### 3.8 문서 파일

| 파일 | 수정 내용 |
|------|-----------|
| [README.md](../README.md) | 전체 재작성 - OKR Best 프로젝트 설명 |
| [CONTRIBUTING.md](../CONTRIBUTING.md) | 기여 가이드 업데이트 |
| [CHANGELOG.md](../CHANGELOG.md) | 새 변경 이력 시작 |
| [SECURITY.md](../SECURITY.md) | 보안 정책 업데이트 |
| [TESTING.md](../TESTING.md) | 테스트 가이드 업데이트 |

---

## 4. 검색/치환 패턴

### 4.1 전체 검색 명령

```bash
# 대소문자 구분 검색
grep -r "Mattermost" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.json"
grep -r "mattermost" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.json"
grep -r "MATTERMOST" --include="*.ts" --include="*.tsx" --include="*.js"

# 파일명 검색
find . -name "*mattermost*" -o -name "*Mattermost*"
```

### 4.2 주요 치환 패턴

| 패턴 | 검색 | 치환 | 적용 범위 |
|------|------|------|-----------|
| 제품명 (대문자) | `Mattermost` | `OKR Best` | UI 문자열, 문서 |
| 제품명 (소문자) | `mattermost` | `okrbest` | 코드, URL, 파일명 |
| 패키지명 | `mattermost-desktop` | `okrbest-desktop` | package.json, 코드 |
| 앱 ID | `Mattermost.Desktop` | `OKRBest.Desktop` | 설정 파일 |
| 프로토콜 | `mattermost://` | `okrbest://` | 코드, 설정 |
| 쿠키 접두사 | `MM` | `OKR` | 쿠키명 상수 |
| 클래스명 | `MattermostServer` | `OKRBestServer` (선택) | 코드 |
| 클래스명 | `MattermostWebContentsView` | `OKRBestWebContentsView` (선택) | 코드 |

### 4.3 주의사항

- **단순 치환 금지**: 문맥에 따라 다르게 처리 필요
- **주석/라이선스 유지**: 원본 저작권 표시는 유지
- **테스트 파일**: 테스트 파일도 함께 업데이트
- **URL 도메인**: mattermost.com → okrbest.com (자체 인프라 필요)

### 4.4 치환하면 안 되는 항목

```
- LICENSE.txt 내 원본 저작권 표시
- NOTICE.txt 내 원본 프로젝트 정보
- 소스 파일 헤더의 원본 저작권
- 주석 내 원본 프로젝트 참조 링크
- @mattermost/compass-icons (외부 의존성)
- @mattermost/desktop-api (로컬 패키지 - 이름 변경 별도 처리)
```

---

## 5. 아이콘 교체 가이드

### 5.1 필요한 아이콘 목록

#### 메인 앱 아이콘

| 파일 | 크기 | 용도 |
|------|------|------|
| `src/assets/icon.ico` | 다중 해상도 | Windows 앱 아이콘 |
| `src/assets/icon.icns` | 다중 해상도 | macOS 앱 아이콘 |
| `src/assets/appicon_48.png` | 48x48 | 앱 아이콘 |
| `src/assets/appicon_with_spacing_32.png` | 32x32 | 여백 포함 아이콘 |
| `src/assets/linux/app_icon.png` | 256x256+ | Linux 앱 아이콘 |

#### 트레이 아이콘 (Windows)

| 파일 | 크기 | 설명 |
|------|------|------|
| `src/assets/windows/tray_light.ico` | 16x16 | 라이트 테마 기본 |
| `src/assets/windows/tray_light_unread.ico` | 16x16 | 라이트 테마 읽지않음 |
| `src/assets/windows/tray_light_mention.ico` | 16x16 | 라이트 테마 멘션 |
| `src/assets/windows/tray_dark.ico` | 16x16 | 다크 테마 기본 |
| `src/assets/windows/tray_dark_unread.ico` | 16x16 | 다크 테마 읽지않음 |
| `src/assets/windows/tray_dark_mention.ico` | 16x16 | 다크 테마 멘션 |

#### 트레이 아이콘 (Linux)

| 파일 | 크기 | 설명 |
|------|------|------|
| `src/assets/linux/top_bar_light_16.png` | 16x16 | 라이트 테마 기본 |
| `src/assets/linux/top_bar_light_16@2x.png` | 32x32 | 라이트 테마 기본 @2x |
| `src/assets/linux/top_bar_light_unread_16.png` | 16x16 | 읽지않음 |
| `src/assets/linux/top_bar_light_unread_16@2x.png` | 32x32 | 읽지않음 @2x |
| `src/assets/linux/top_bar_light_mention_16.png` | 16x16 | 멘션 |
| `src/assets/linux/top_bar_light_mention_16@2x.png` | 32x32 | 멘션 @2x |
| `src/assets/linux/top_bar_dark_*.png` | 16/32 | 다크 테마 버전들 |

#### macOS 리소스

| 파일 | 크기 | 용도 |
|------|------|------|
| `src/assets/osx/DMG_BG.png` | 660x400 | DMG 설치 배경 |
| `src/assets/osx/menuIcons/` | 다양함 | 메뉴바 아이콘 |

### 5.2 아이콘 제작 요구사항

#### ICO 파일 (Windows)
포함해야 할 크기:
- 16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256

#### ICNS 파일 (macOS)
포함해야 할 크기:
- 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
- @1x 및 @2x 버전

#### PNG 파일 요구사항
- 투명 배경 지원
- sRGB 색상 프로파일
- 최적화된 파일 크기

### 5.3 아이콘 생성 도구

```bash
# macOS - iconutil 사용
iconutil -c icns icon.iconset

# 크로스 플랫폼 - png2icons
npm install -g png2icons
png2icons input.png output -allfiles

# ImageMagick
convert icon-1024.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico
```

---

## 6. 자체 인프라 설정

### 6.1 필수 인프라 URL

다음 URL들을 자체 인프라로 설정해야 합니다:

| 용도 | 플레이스홀더 | 설정 위치 |
|------|--------------|-----------|
| 업데이트 서버 | `{{UPDATE_SERVER_URL}}` | electron-builder.json |
| 도움말 링크 | `{{HELP_URL}}` | src/common/constants.ts |
| 아카데미 링크 | `{{ACADEMY_URL}}` | src/common/constants.ts |
| 버그 리포트 | `{{BUG_REPORT_URL}}` | src/common/constants.ts |
| 변경 이력 | `{{CHANGELOG_URL}}` | src/common/constants.ts |
| 홈페이지 | `{{HOMEPAGE_URL}}` | package.json |

### 6.2 자동 업데이트 서버 설정

electron-updater를 위한 서버 구성:

```
https://releases.okrbest.com/desktop/
├── latest.yml              # Windows 최신 버전 정보
├── latest-mac.yml          # macOS 최신 버전 정보
├── latest-linux.yml        # Linux 최신 버전 정보
├── {version}/
│   ├── okrbest-desktop-{version}-win.exe
│   ├── okrbest-desktop-{version}-mac.dmg
│   └── okrbest-desktop-{version}-linux.AppImage
```

### 6.3 Sentry 설정 (선택)

에러 추적을 위한 Sentry DSN 설정:

```typescript
// webpack.config.base.js 또는 환경 변수
__SENTRY_DSN__: 'https://your-sentry-dsn@sentry.io/project'
```

### 6.4 기본 서버 설정 (선택)

```typescript
// src/common/config/buildConfig.ts
defaultServers: [
    {
        name: 'OKR Best',
        url: 'https://app.okrbest.com'
    }
],
```

---

## 7. 단계별 실행 가이드

### Phase 1: 기반 작업 (1일)

- [ ] 1.1 LICENSE.txt에 OKR Best 저작권 추가
- [ ] 1.2 NOTICE.txt 업데이트
- [ ] 1.3 새 아이콘 세트 준비

### Phase 2: 핵심 설정 변경 (1일)

- [ ] 2.1 package.json 수정
- [ ] 2.2 electron-builder.json 수정
- [ ] 2.3 api-types/package.json 수정
- [ ] 2.4 e2e/package.json 수정

### Phase 3: 소스 코드 변경 (2-3일)

- [ ] 3.1 src/common/constants.ts 수정
- [ ] 3.2 src/common/config/buildConfig.ts 수정
- [ ] 3.3 src/common/config/RegistryConfig.ts 수정
- [ ] 3.4 src/main/app/initialize.ts 수정
- [ ] 3.5 프로토콜 핸들러 변경 (mattermost:// → okrbest://)
- [ ] 3.6 나머지 소스 파일 브랜드명 변경

### Phase 4: 리소스 변경 (1일)

- [ ] 4.1 모든 아이콘 파일 교체
- [ ] 4.2 DMG 배경 이미지 교체
- [ ] 4.3 Linux desktop 파일 수정
- [ ] 4.4 Windows GPO 파일 수정 및 이름 변경

### Phase 5: 다국어 및 문서 (1-2일)

- [ ] 5.1 i18n/*.json 파일 업데이트 (60개+)
- [ ] 5.2 README.md 재작성
- [ ] 5.3 기타 문서 업데이트

### Phase 6: 테스트 및 검증 (1-2일)

- [ ] 6.1 빌드 테스트 (npm run build)
- [ ] 6.2 유닛 테스트 실행 (npm run test:unit)
- [ ] 6.3 E2E 테스트 실행 (npm run e2e)
- [ ] 6.4 패키징 테스트 (각 플랫폼)
- [ ] 6.5 설치 및 실행 테스트

### Phase 7: 인프라 연동 (별도)

- [ ] 7.1 자동 업데이트 서버 구축
- [ ] 7.2 도움말/문서 사이트 준비
- [ ] 7.3 Sentry 프로젝트 설정 (선택)

---

## 부록: 빠른 참조

### 주요 파일 경로

```
설정:
├── package.json
├── electron-builder.json
├── src/common/config/buildConfig.ts
├── src/common/config/RegistryConfig.ts
└── src/common/constants.ts

아이콘:
├── src/assets/icon.ico
├── src/assets/icon.icns
├── src/assets/linux/
├── src/assets/windows/
└── src/assets/osx/

GPO:
├── resources/windows/gpo/mattermost.admx
└── resources/windows/gpo/en-US/mattermost.adml

다국어:
└── i18n/*.json (60개+)
```

### grep 검색 명령어 모음

```bash
# 모든 Mattermost 언급 찾기
grep -r "Mattermost" --include="*.{ts,tsx,js,json,md,sh,xml}" .

# 프로토콜 핸들러 찾기
grep -r "mattermost://" .

# 쿠키명 찾기
grep -r "MM[A-Z]" --include="*.ts" .

# 레지스트리 경로 찾기
grep -r "Policies\\\\Mattermost" .
```

---

*문서 작성일: 2026-01-04*

