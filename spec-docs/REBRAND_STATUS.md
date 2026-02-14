# OKR Best 리브랜딩 현황

> 마지막 업데이트: 2026-02-14

---

## 리브랜딩 개요

| 항목 | 변경 전 | 변경 후 | 상태 |
|------|---------|---------|------|
| 제품명 | Mattermost Desktop | OKR Best | ✅ 완료 |
| 패키지명 | mattermost-desktop | okrbest-desktop | ✅ 완료 |
| 앱 ID | Mattermost.Desktop | OKRBest.Desktop | ✅ 완료 |
| 프로토콜 | mattermost:// | okrbest:// | ✅ 완료 |
| 홈페이지 | mattermost.com | okr.best | ✅ 완료 |
| 저장소 | mattermost/desktop | okrbest/okrbest-desktop | ✅ 완료 |

**전체 진행률: 약 75%**

---

## 1. 완료된 작업

### 1.1 패키지 메타데이터 ✅

| 파일 | 필드 | 값 |
|------|------|-----|
| `package.json` | name | `okrbest-desktop` |
| `package.json` | productName | `OKR Best` |
| `package.json` | description | `OKR Best Desktop` |
| `package.json` | author | `OKR Best` |
| `package.json` | desktopName | `OKRBest.Desktop` |
| `package.json` | homepage | `https://okr.best` |
| `package.json` | repository | `git://github.com/okrbest/okrbest-desktop.git` |

### 1.2 electron-builder.json (부분 완료) ✅

완료 항목:
- `appId`: `OKRBest.Desktop`
- `protocols[0].name`: `OKR Best`
- `protocols[0].schemes`: `okrbest` 포함
- `deb.synopsis`: `OKR Best Desktop App`
- macOS `NSFocusStatusUsageDescription`: OKR Best 언급

### 1.3 소스 코드 저작권 헤더 ✅

대부분의 소스 파일에 다음 헤더 추가 완료:

```
Copyright (c) 2024-present OKR Best. All Rights Reserved.
Modified for OKR Best project.
```

### 1.4 README.md ✅

전체 내용 OKR Best로 재작성 완료.

### 1.5 i18n 번역 파일 (부분 완료) ✅

`i18n/en.json` 주요 문자열 변경 완료:
- `main.menus.app.help.academy` → "OKR Best Academy"
- 서버 유효성 검사 메시지 → "OKR Best server"

### 1.6 워크플로우 파일 (부분 완료) ✅

완료 항목:
- `nightly-builds.yaml`: 이메일 `nightly-build@okr.best`
- `build-for-pr.yml`: `OKRBEST_WIN_INSTALLERS` 환경변수, 파일 경로 `okrbest-desktop*`
- `release.yaml`: `OKRBEST_WIN_INSTALLERS` 환경변수, 파일 경로 `okrbest-desktop*`

### 1.7 에셋 ✅

- `src/assets/thumbnails/okrbest.svg` 생성됨

---

## 2. 남은 작업

### 2.1 [높음] electron-builder.json 미완료 항목

| 항목 | 현재값 | 변경 필요값 |
|------|--------|------------|
| `linux.appId` (line 68) | `com.Mattermost.Desktop` | `com.OKRBest.Desktop` |

**파일**: `electron-builder.json`

### 2.2 [높음] 빌드 설정 URL

`src/common/config/buildConfig.ts`에 Mattermost URL이 남아 있음:

| 라인 | 현재값 | 변경값 |
|------|--------|--------|
| 39 | `updateNotificationURL: 'https://releases.mattermost.com/desktop'` | OKR Best 업데이트 서버 URL |
| 42 | `linuxUpdateURL: 'https://docs.mattermost.com/...'` | OKR Best 문서 URL |

**참고**: 업데이트 서버 인프라 구축 후 변경 가능

### 2.3 [높음] 소스 코드 내 잔여 Mattermost 참조

| 파일 | 내용 | 비고 |
|------|------|------|
| `src/main/utils.ts` (line 124) | `'Mattermost.Desktop'` (tccutil 명령) | macOS 권한 리셋 명령 |
| `src/main/notifications/dnd-windows.ts` (line 25) | `isPriority('Mattermost.Desktop')` | Windows 방해금지 모드 |
| `src/common/utils/constants.ts` (line 55) | `NotMattermost: 'NOT_MATTERMOST'` | enum 값 |

**의도적 유지 항목** (변경 불필요):
- `src/main/server/serverInfo.ts` (line 97): `'com.mattermost.nps'` → Mattermost 서버 플러그인 ID
- `src/common/utils/constants.ts` (line 33): `CALLS_PLUGIN_ID = 'com.mattermost.calls'` → Mattermost 서버 플러그인 ID
- `electron-builder.json` protocols에 `mattermost` 스키마 유지 → Mattermost 서버 호환성

### 2.4 [높음] 아이콘 교체

모든 앱 아이콘이 아직 Mattermost 기본 아이콘 상태:

**메인 앱 아이콘:**
- [ ] `src/assets/icon.ico` (Windows)
- [ ] `src/assets/icon.icns` (macOS)
- [ ] `src/assets/appicon_48.png`
- [ ] `src/assets/appicon_with_spacing_32.png`
- [ ] `src/assets/linux/app_icon.png`

**트레이 아이콘 (Windows):**
- [ ] `src/assets/windows/tray_light.ico`
- [ ] `src/assets/windows/tray_light_unread.ico`
- [ ] `src/assets/windows/tray_light_mention.ico`
- [ ] `src/assets/windows/tray_dark.ico`
- [ ] `src/assets/windows/tray_dark_unread.ico`
- [ ] `src/assets/windows/tray_dark_mention.ico`

**트레이 아이콘 (Linux):**
- [ ] `src/assets/linux/top_bar_light_16.png` 및 `@2x`
- [ ] `src/assets/linux/top_bar_light_unread_16.png` 및 `@2x`
- [ ] `src/assets/linux/top_bar_light_mention_16.png` 및 `@2x`
- [ ] `src/assets/linux/top_bar_dark_*.png` 전체

**macOS 리소스:**
- [ ] `src/assets/osx/DMG_BG.png` (DMG 배경)
- [ ] `src/assets/osx/menuIcons/` 디렉터리 내 아이콘

**아이콘 제작 요구사항:**
- ICO: 16, 24, 32, 48, 64, 128, 256px 다중 해상도
- ICNS: 16~1024px, @1x/@2x
- PNG: 투명 배경, sRGB 프로파일

### 2.5 [중간] Windows GPO 파일

파일명 및 내용 변경 필요:

- [ ] `resources/windows/gpo/mattermost.admx` → `okrbest.admx`
  - namespace: `OKRBest.Policies`
  - key: `Software\Policies\OKRBest`
- [ ] `resources/windows/gpo/en-US/mattermost.adml` → `okrbest.adml`
  - 모든 문자열에서 Mattermost → OKR Best

### 2.6 [중간] 다국어 파일 잔여 항목

`i18n/en.json` 내 잔여 Mattermost 참조:
- line 326: 키 이름에 `Mattermost` 포함 (값은 `{appName}` 플레이스홀더 사용으로 무방)

**기타 언어 파일** (60개+):
- [ ] 각 언어 파일에서 "Mattermost" 문자열 확인 및 변경 필요

검색 명령:
```bash
rg "Mattermost" i18n/ --include="*.json"
```

### 2.7 [중간] 워크플로우 인프라 (인프라 준비 후 진행)

아래 항목은 OKR Best 자체 인프라가 준비된 후 변경:

**S3 버킷 URL:**
- `release.yaml` (lines 227, 229): `s3://releases.mattermost.com/desktop/`
- `nightly-main.yml` (lines 253, 255, 263, 265, 267): `s3://releases.mattermost.com/desktop/`

**알림 Webhook:**
- `release.yaml`: Mattermost 알림 username/icon → OKR Best로 변경 또는 Slack/Discord로 대체

**외부 Actions:**
- `mattermost/action-mattermost-notify` → 포크 또는 대체 액션 사용
- `mattermost/actions/delivery/update-commit-status` → `actions/github-script`로 대체

**GitHub Secrets 이름 변경:**
- 기존 `MM_*` prefix → `OKRBEST_*` prefix (CI_CD.md 참조)

### 2.8 [낮음] 코드 서명 인증서

현재 Windows 코드 서명이 비활성화 상태:

```json
{ "win": { "sign": false } }
```

프로덕션 배포 전 필요:
- [ ] Windows: SSL.com OV 코드 서명 인증서 (~$200-300/년)
- [ ] macOS: Apple Developer Program ($99/년)

### 2.9 [낮음] 외부 링크/상수

`src/common/constants.ts` 내 외부 링크 URL 변경 (인프라 준비 후):

| 상수 | 변경 필요 |
|------|-----------|
| `DEFAULT_HELP_LINK` | OKR Best 도움말 URL |
| `DEFAULT_ACADEMY_LINK` | OKR Best 아카데미 URL |
| `DEFAULT_TE_REPORT_PROBLEM_LINK` | OKR Best 버그 리포트 URL |
| `DEFAULT_EE_REPORT_PROBLEM_LINK` | OKR Best 지원 URL |
| `DEFAULT_UPGRADE_LINK` | OKR Best 업그레이드 URL |
| `DEFAULT_CHANGELOG_LINK` | OKR Best 변경 이력 URL |

### 2.10 [낮음] 테스트 파일

테스트 파일 내 Mattermost 문자열이 다수 존재. 기능에 영향 없으나 일관성을 위해 정리 권장.

검색 명령:
```bash
rg "Mattermost" src/ --type ts -l
rg "mattermost" src/ --type ts -l
```

---

## 3. 라이선스 준수 사항 (참고)

Apache License 2.0 파생 작업물로서 반드시 유지해야 할 항목:

### 변경하면 안 되는 것

- `LICENSE.txt` 내 원본 저작권 (Yuya Ochiai, Mattermost, Inc.)
- `NOTICE.txt` 내 원본 프로젝트 정보
- 소스 파일 헤더의 원본 저작권 라인
- `@mattermost/compass-icons` 등 외부 의존성 패키지명
- Mattermost 서버 플러그인 ID (`com.mattermost.calls`, `com.mattermost.nps`)

### 소스 파일 헤더 형식

```typescript
// Copyright (c) 2015-2016 Yuya Ochiai
// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.
```

---

## 4. 작업 우선순위 요약

| 우선순위 | 작업 | 인프라 필요 | 예상 소요 |
|----------|------|:-----------:|-----------|
| **높음** | Linux appId 수정 (2.1) | 아니오 | 5분 |
| **높음** | 소스 코드 잔여 참조 수정 (2.3) | 아니오 | 30분 |
| **높음** | 아이콘 교체 (2.4) | 아니오 (디자인 필요) | 디자인 완료 후 1시간 |
| **중간** | Windows GPO 파일 (2.5) | 아니오 | 1시간 |
| **중간** | 다국어 파일 정리 (2.6) | 아니오 | 2시간 |
| **중간** | 빌드 설정 URL (2.2) | **예** | 30분 |
| **중간** | 워크플로우 인프라 (2.7) | **예** | 2시간 |
| **낮음** | 코드 서명 (2.8) | **예** | 별도 |
| **낮음** | 외부 링크 상수 (2.9) | **예** | 30분 |
| **낮음** | 테스트 파일 (2.10) | 아니오 | 2시간 |

---

*이 문서는 리브랜딩 진행에 따라 업데이트합니다.*
