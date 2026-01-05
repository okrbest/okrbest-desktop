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

> **리브랜딩 전략**: 외관부터 시작하여 점진적으로 내부 변경을 진행합니다.
> 각 카테고리 완료 후 빌드 및 테스트를 수행하여 안정성을 확보합니다.

---

## 카테고리 1: 외관 변경 (사용자에게 보이는 UI) ⭐ **최우선**

**목표**: 앱을 실행했을 때 OKR Best 브랜드가 보이도록 변경  
**예상 소요 시간**: 1-2일  
**완료 후**: 테스트 빌드 및 배포 가능

### 1.1 아이콘 교체

**우선순위**: 🔴 최우선 (가장 눈에 띄는 변경)

#### 메인 앱 아이콘 교체
- [ ] `src/assets/icon.ico` (Windows) - 다중 해상도 포함
- [ ] `src/assets/icon.icns` (macOS) - 다중 해상도 포함
- [ ] `src/assets/appicon_48.png` (48x48)
- [ ] `src/assets/appicon_with_spacing_32.png` (32x32)
- [ ] `src/assets/linux/app_icon.png` (256x256+)

#### 트레이 아이콘 교체 (Windows)
- [ ] `src/assets/windows/tray_light.ico` (16x16)
- [ ] `src/assets/windows/tray_light_unread.ico` (16x16)
- [ ] `src/assets/windows/tray_light_mention.ico` (16x16)
- [ ] `src/assets/windows/tray_dark.ico` (16x16)
- [ ] `src/assets/windows/tray_dark_unread.ico` (16x16)
- [ ] `src/assets/windows/tray_dark_mention.ico` (16x16)

#### 트레이 아이콘 교체 (Linux)
- [ ] `src/assets/linux/top_bar_light_16.png` 및 `@2x` 버전
- [ ] `src/assets/linux/top_bar_light_unread_16.png` 및 `@2x` 버전
- [ ] `src/assets/linux/top_bar_light_mention_16.png` 및 `@2x` 버전
- [ ] `src/assets/linux/top_bar_dark_*.png` 모든 버전

#### macOS 리소스 교체
- [ ] `src/assets/osx/DMG_BG.png` (DMG 설치 배경)
- [ ] `src/assets/osx/menuIcons/` 디렉터리 내 아이콘들

**검증 방법**: 빌드 후 앱 아이콘, 트레이 아이콘이 모두 변경되었는지 확인

---

### 1.2 다국어 파일 UI 문자열 변경

**우선순위**: 🔴 최우선 (앱 내 모든 텍스트)

#### 주요 언어 파일부터 시작 (우선순위 순)
- [ ] `i18n/en.json` - 영어 (가장 중요)
- [ ] `i18n/ko.json` - 한국어
- [ ] `i18n/ja.json` - 일본어
- [ ] `i18n/zh-CN.json` - 중국어 간체
- [ ] `i18n/zh-TW.json` - 중국어 번체
- [ ] 나머지 언어 파일들 (60개+)

#### 변경 대상 문자열 예시
```json
{
  "main.menus.app.about": "About OKR Best",
  "main.menus.app.name": "OKR Best",
  "renderer.settings.page.header": "OKR Best Settings",
  "main.menus.app.checkForUpdates": "Check for Updates...",
  "main.menus.app.preferences": "Preferences...",
  // ... 모든 "Mattermost" 언급을 "OKR Best"로 변경
}
```

#### 검색 명령어
```bash
# 모든 언어 파일에서 Mattermost 찾기
grep -r "Mattermost" i18n/ --include="*.json"
grep -r "mattermost" i18n/ --include="*.json"
```

**검증 방법**: 앱 실행 후 메뉴, 설정 화면 등 모든 UI 텍스트 확인

---

### 1.3 앱 이름 표시 관련 코드 변경

**우선순위**: 🟡 높음 (윈도우 타이틀바, 메뉴바 등)

- [ ] `src/main/constants.ts` - 앱 이름 상수 변경
- [ ] `src/renderer/constants.ts` - 렌더러 앱 이름 상수 변경
- [ ] `src/main/app/initialize.ts` - 앱 이름 설정 확인

**검증 방법**: 앱 실행 후 윈도우 타이틀, 메뉴바에 "OKR Best" 표시 확인

---

### 1.4 Linux 데스크톱 파일 수정

**우선순위**: 🟡 높음 (Linux 사용자에게 보임)

- [ ] `src/assets/linux/create_desktop_file.sh` 수정
  - 파일명: `Mattermost.desktop` → `OKRBest.desktop`
  - Name: `OKR Best`
  - Comment: `OKR Best Desktop application for Linux`
  - Exec: `okrbest-desktop`
  - MimeType: `x-scheme-handler/okrbest`

**검증 방법**: Linux에서 빌드 후 데스크톱 파일 생성 확인

---

**카테고리 1 완료 체크리스트**:
- [ ] 모든 아이콘 교체 완료
- [ ] 주요 언어 파일 UI 문자열 변경 완료
- [ ] 앱 실행 시 "OKR Best" 브랜드 표시 확인
- [ ] 테스트 빌드 성공
- [ ] **테스트 배포 준비 완료** ✅

---

## 카테고리 2: 기본 설정 변경 (빌드/패키징)

**목표**: 빌드 시스템과 패키지 메타데이터 변경  
**예상 소요 시간**: 0.5-1일  
**완료 후**: 정상적인 빌드 및 패키징 가능

### 2.1 package.json 메타데이터 변경

**우선순위**: 🔴 최우선 (빌드에 필수)

- [ ] 루트 `package.json` 수정
  - `name`: `mattermost-desktop` → `okrbest-desktop`
  - `productName`: `Mattermost` → `OKR Best`
  - `description`: `OKR Best Desktop Application`
  - `author`: `OKR Best <contact@okrbest.com>`
  - `desktopName`: `OKRBest.Desktop`
  - `homepage`: `https://okrbest.com`
  - `repository.url`: 새 저장소 URL

- [ ] `api-types/package.json` 수정
  - `name`: `@okrbest/desktop-api`

- [ ] `e2e/package.json` 수정
  - `name`: `okrbest-desktop-e2e`

**검증 방법**: `npm install` 정상 실행 확인

---

### 2.2 electron-builder.json 설정 변경

**우선순위**: 🔴 최우선 (패키징에 필수)

- [ ] `electron-builder.json` 수정
  - `appId`: `Mattermost.Desktop` → `OKRBest.Desktop`
  - `protocols[0].name`: `Mattermost` → `OKR Best`
  - `protocols[0].schemes[0]`: `mattermost` → `okrbest`
  - `deb.synopsis`: `OKR Best Desktop App`
  - `win.publisherName`: `OKR Best`
  - `publish[0].url`: 업데이트 서버 URL (임시로 로컬 또는 미설정 가능)

**검증 방법**: `npm run build` 정상 실행 확인

---

### 2.3 기본 상수 파일 변경

**우선순위**: 🟡 높음 (앱 동작에 영향)

- [ ] `src/common/constants.ts` 수정
  - 외부 링크 URL 변경 (임시로 플레이스홀더 사용 가능)
  - 쿠키명 접두사 변경: `MM` → `OKR` (서버와 협의 필요)

**주의**: 외부 링크는 인프라 준비 전까지 임시 URL 사용 가능

---

**카테고리 2 완료 체크리스트**:
- [ ] package.json 모든 필드 변경 완료
- [ ] electron-builder.json 설정 변경 완료
- [ ] 빌드 성공 확인 (`npm run build`)
- [ ] 패키징 성공 확인 (각 플랫폼별)

---

## 카테고리 3: 코드 내부 변경 (기능 관련)

**목표**: 프로토콜 핸들러, 레지스트리, 데이터 디렉터리 등 내부 기능 변경  
**예상 소요 시간**: 1-2일  
**완료 후**: 완전한 리브랜딩 완료

### 3.1 프로토콜 핸들러 변경

**우선순위**: 🟡 높음 (`mattermost://` → `okrbest://`)

#### 영향 받는 파일
- [ ] `src/main/app/initialize.ts` - 프로토콜 핸들러 등록
- [ ] `src/common/config/buildConfig.ts` - `allowedProtocols` 배열
- [ ] `electron-builder.json` - 프로토콜 스키마 (이미 2.2에서 변경)
- [ ] `src/assets/linux/create_desktop_file.sh` - MimeType (이미 1.4에서 변경)

#### 검색 명령어
```bash
grep -r "mattermost://" --include="*.ts" --include="*.js" --include="*.json" --include="*.sh"
grep -r "mattermost-dev://" --include="*.ts" --include="*.js"
```

**검증 방법**: `okrbest://` 프로토콜 링크가 정상 작동하는지 확인

---

### 3.2 레지스트리 및 GPO 설정 변경 (Windows)

**우선순위**: 🟢 중간 (Windows 엔터프라이즈 환경용)

- [ ] `src/common/config/RegistryConfig.ts` 수정
  - `REGISTRY_KEY`: `Software\\Policies\\Mattermost` → `Software\\Policies\\OKRBest`

- [ ] Windows GPO 파일 수정 및 이름 변경
  - `resources/windows/gpo/mattermost.admx` → `okrbest.admx`
  - `resources/windows/gpo/en-US/mattermost.adml` → `okrbest.adml`
  - 파일 내용 내 모든 "Mattermost" → "OKR Best" 변경

**검증 방법**: Windows에서 레지스트리 경로 확인

---

### 3.3 데이터 디렉터리 변경

**우선순위**: 🟢 낮음 (자동 적용됨)

**참고**: `package.json`의 `productName` 변경으로 자동 적용됩니다.
- Windows: `%APPDATA%\OKRBest`
- macOS: `~/Library/Application Support/OKRBest`
- Linux: `~/.config/OKRBest`

**검증 방법**: 앱 실행 후 데이터 디렉터리 경로 확인

---

### 3.4 나머지 소스 코드 브랜드명 변경

**우선순위**: 🟡 높음 (코드 일관성)

#### 검색 및 치환 대상
- [ ] 클래스명: `MattermostServer` → `OKRBestServer` (선택사항)
- [ ] 클래스명: `MattermostWebContentsView` → `OKRBestWebContentsView` (선택사항)
- [ ] 주석 내 브랜드명 (라이선스 헤더 제외)
- [ ] 테스트 파일 내 브랜드명

#### 검색 명령어
```bash
# 모든 소스 파일에서 Mattermost 찾기
grep -r "Mattermost" --include="*.ts" --include="*.tsx" --include="*.js" src/
grep -r "mattermost" --include="*.ts" --include="*.tsx" --include="*.js" src/
grep -r "MATTERMOST" --include="*.ts" --include="*.tsx" --include="*.js" src/
```

**주의**: 라이선스 헤더의 원본 저작권 표시는 유지해야 함

---

**카테고리 3 완료 체크리스트**:
- [ ] 프로토콜 핸들러 변경 완료
- [ ] 레지스트리/GPO 설정 변경 완료
- [ ] 소스 코드 내 브랜드명 일관성 확인
- [ ] 모든 기능 정상 작동 확인

---

## 카테고리 4: 문서 및 라이선스

**목표**: 라이선스 준수 및 문서 업데이트  
**예상 소요 시간**: 0.5-1일  
**완료 후**: 법적 요구사항 충족

### 4.1 라이선스 파일 수정

**우선순위**: 🔴 최우선 (법적 요구사항)

- [ ] `LICENSE.txt` 수정
  - 원본 저작권 유지
  - OKR Best 저작권 추가:
    ```
    Copyright (c) 2024-present OKR Best. All Rights Reserved.
    ```

- [ ] `NOTICE.txt` 수정
  - 원본 NOTICE 내용 유지
  - OKR Best 프로젝트 정보 추가:
    ```
    OKR Best Desktop
    Copyright (c) 2024-present OKR Best
    
    This product includes software developed at Mattermost, Inc.
    Based on Mattermost Desktop
    ```

---

### 4.2 소스 파일 헤더 추가

**우선순위**: 🟡 높음 (수정된 파일에만)

**주의**: 모든 파일에 추가할 필요는 없고, 주요 수정 파일에만 추가

```typescript
// Copyright (c) 2015-2016 Yuya Ochiai
// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.
```

---

### 4.3 문서 파일 업데이트

**우선순위**: 🟢 중간 (사용자/개발자 가이드)

- [ ] `README.md` 재작성 - OKR Best 프로젝트 설명
- [ ] `CONTRIBUTING.md` 업데이트 - 기여 가이드
- [ ] `CHANGELOG.md` 새 변경 이력 시작
- [ ] `SECURITY.md` 업데이트 - 보안 정책
- [ ] `TESTING.md` 업데이트 - 테스트 가이드

---

**카테고리 4 완료 체크리스트**:
- [ ] LICENSE.txt 및 NOTICE.txt 수정 완료
- [ ] 주요 소스 파일 헤더 추가 완료
- [ ] 문서 파일 업데이트 완료

---

## 카테고리 5: 인프라 설정 (별도 작업)

**목표**: 자동 업데이트, 외부 링크 등 인프라 연동  
**예상 소요 시간**: 별도 (인프라 팀과 협업)  
**완료 후**: 프로덕션 배포 준비 완료

### 5.1 자동 업데이트 서버 구축

**우선순위**: 🟡 높음 (프로덕션 배포 전 필요)

- [ ] 업데이트 서버 구축 (`https://releases.okrbest.com/desktop/`)
- [ ] `electron-builder.json`의 `publish[0].url` 업데이트
- [ ] 업데이트 파일 구조 준비:
  ```
  latest.yml (Windows)
  latest-mac.yml (macOS)
  latest-linux.yml (Linux)
  {version}/ 디렉터리
  ```

---

### 5.2 외부 링크 설정

**우선순위**: 🟡 높음 (사용자 지원)

- [ ] 도움말 사이트 준비 → `src/common/constants.ts`의 `DEFAULT_HELP_LINK`
- [ ] 아카데미 링크 준비 → `DEFAULT_ACADEMY_LINK`
- [ ] 버그 리포트 링크 준비 → `DEFAULT_TE_REPORT_PROBLEM_LINK`
- [ ] 변경 이력 링크 준비 → `DEFAULT_CHANGELOG_LINK`
- [ ] 업그레이드 링크 준비 → `DEFAULT_UPGRADE_LINK`

---

### 5.3 Sentry 설정 (선택)

**우선순위**: 🟢 낮음 (에러 추적)

- [ ] Sentry 프로젝트 생성
- [ ] DSN 설정 (`webpack.config.base.js` 또는 환경 변수)

---

**카테고리 5 완료 체크리스트**:
- [ ] 업데이트 서버 구축 완료
- [ ] 모든 외부 링크 설정 완료
- [ ] 자동 업데이트 정상 작동 확인

---

## 최종 검증 및 배포

### 전체 테스트 체크리스트

- [ ] **빌드 테스트**
  - [ ] `npm run build` 성공
  - [ ] 각 플랫폼별 패키징 성공 (Windows, macOS, Linux)

- [ ] **기능 테스트**
  - [ ] 앱 정상 실행
  - [ ] 서버 연결 정상 작동
  - [ ] 프로토콜 핸들러 작동 (`okrbest://`)
  - [ ] 설정 화면 정상 작동
  - [ ] 업데이트 체크 기능 (인프라 준비 후)

- [ ] **UI/UX 테스트**
  - [ ] 모든 아이콘 정상 표시
  - [ ] 다국어 문자열 정상 표시
  - [ ] 브랜드명 일관성 확인

- [ ] **테스트 배포**
  - [ ] 내부 테스트 배포
  - [ ] 피드백 수집 및 수정

- [ ] **프로덕션 배포**
  - [ ] 인프라 설정 완료 확인
  - [ ] 프로덕션 배포 실행

---

## 작업 우선순위 요약

| 카테고리 | 우선순위 | 목표 | 완료 후 결과 |
|---------|---------|------|-------------|
| **카테고리 1** | 🔴 최우선 | 외관 변경 | 테스트 배포 가능 |
| **카테고리 2** | 🔴 최우선 | 기본 설정 | 정상 빌드 가능 |
| **카테고리 3** | 🟡 높음 | 기능 변경 | 완전한 리브랜딩 |
| **카테고리 4** | 🟡 높음 | 라이선스 | 법적 요구사항 충족 |
| **카테고리 5** | 🟢 중간 | 인프라 | 프로덕션 배포 준비 |

---

## 빠른 시작 가이드

**테스트 배포를 위한 최소 작업** (카테고리 1 + 2.1):
1. 아이콘 교체 (1.1)
2. 주요 언어 파일 UI 문자열 변경 (1.2) - en.json, ko.json 우선
3. package.json 기본 필드 변경 (2.1)
4. 빌드 및 테스트 배포

**완전한 리브랜딩을 위한 전체 작업**:
- 카테고리 1 → 2 → 3 → 4 → 5 순서로 진행
- 각 카테고리 완료 후 빌드 및 테스트 수행

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

