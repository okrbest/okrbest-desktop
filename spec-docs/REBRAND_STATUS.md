# OKR Best 리브랜딩 현황

> 마지막 업데이트: 2026-02-14

---

## 리브랜딩 개요

| 항목 | 변경 전 | 변경 후 | 상태 |
|------|---------|---------|------|
| 제품명 | Mattermost Desktop | OKR Best | ✅ 완료 |
| 패키지명 | mattermost-desktop | okrbest-desktop | ✅ 완료 |
| 앱 ID | Mattermost.Desktop | OKRBest.Desktop | ✅ 완료 |
| Linux appId | com.Mattermost.Desktop | com.OKRBest.Desktop | ✅ 완료 |
| 프로토콜 | mattermost:// | okrbest:// | ✅ 완료 |
| 홈페이지 | mattermost.com | okr.best | ✅ 완료 |
| 저장소 | mattermost/desktop | okrbest/okrbest-desktop | ✅ 완료 |

**전체 진행률: 약 95%** (인프라 설정 제외한 코드 변경은 거의 완료)

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
| `package-lock.json` | name | `okrbest-desktop` |

### 1.2 electron-builder.json ✅

- `appId`: `OKRBest.Desktop`
- `linux.appId`: `com.OKRBest.Desktop`
- `protocols[0].name`: `OKR Best`
- `protocols[0].schemes`: `okrbest` 포함 (+ `mattermost` 호환성 유지)
- `deb.synopsis`: `OKR Best Desktop App`
- macOS `NSFocusStatusUsageDescription`: OKR Best 언급

### 1.3 소스 코드 저작권 헤더 ✅

대부분의 소스 파일에 OKR Best 저작권 헤더 추가 완료.

### 1.4 README.md ✅

전체 내용 OKR Best로 재작성 완료.

### 1.5 i18n 번역 파일 ✅

- 32개 전체 언어 파일에서 `Mattermost` 참조 **0건** (완전 제거)
- i18n 키 이름도 리브랜딩 완료:
  - `notMattermost` → `notOKRBest`
  - `MattermostVersionX` → `VersionX`

### 1.6 소스 코드 리브랜딩 ✅

- `URLValidationStatus.NotMattermost` → `NotOKRBest` (enum + 참조 전체)
- `src/main/utils.ts`: tccutil 앱 식별자 → `OKRBest.Desktop`
- `src/main/notifications/dnd-windows.ts`: Windows DnD 식별자 → `OKRBest.Desktop`
- `src/common/config/buildConfig.ts`: URL 전체 변경
  - `updateNotificationURL` → `releases.okrbest.com/desktop`
  - `linuxUpdateURL` → `docs.okrbest.com/...`
  - `linuxGitHubReleaseURL` → `github.com/okrbest/okrbest-desktop/...`
  - `macAppStoreUpdateURL` → `okrbest-desktop` 반영
- defaultMessage 폴백 텍스트: "Mattermost server" → "OKR Best server"

### 1.7 아이콘 ✅

모든 앱 아이콘(메인, 트레이 Windows/Linux, macOS DMG 배경, 메뉴 아이콘) 교체 완료.

### 1.8 Windows GPO 파일 ✅

`okrbest.admx`, `okrbest.adml` 파일명 및 내용 전부 리브랜딩 완료.

### 1.9 스크립트/패치 파일 ✅

- `scripts/generate_release_markdown.sh`: 릴리스 파일명 패턴 + URL 전부 변경
- `patches/app-builder-lib+26.6.0.patch`: MSI 설치 경로, 실행파일명, 메시지 변경

### 1.10 워크플로우 전체 리브랜딩 ✅

- 모든 `MM_*` Secret → `OKRBEST_*` 변경 (5개 워크플로우)
- 환경변수 `MM_WIN_INSTALLERS` → `OKRBEST_WIN_INSTALLERS`
- S3 URL: `releases.okrbest.com/desktop/`, `okrbest-desktop-daily-builds`
- 릴리스 파일 경로: `okrbest-desktop*`

### 1.11 외부 Actions 전환 ✅

| 원래 | 변경 후 |
|------|---------|
| `mattermost/action-mattermost-notify` | `okrbest/action-okrbest-notify@master` |
| `mattermost/actions/delivery/update-commit-status` | `okrbest/actions/delivery/update-commit-status` |
| `mattermost/actions-workflows/.../snyk-sbom.yml` | `okrbest/actions-workflows/.../snyk-sbom.yml` |

### 1.12 Windows 코드 서명 인증서 ✅

| 항목 | 값 |
|------|-----|
| 인증서 | Certum Standard Code Signing in the Cloud (365일) |
| 조직 | OKRBEST Inc. (경기도 안양시, KR) |
| 유효 기간 | 2026-02-14 ~ 2027-02-14 |
| 활성화 | ✅ 완료 |
| 워크플로우 연동 | ✅ `scripts/certum-sign.ps1` + 4개 워크플로우 적용 |

---

## 2. 남은 작업

### 2.1 [높음] Windows 코드 서명 - GitHub Secrets 등록

- [ ] SimplySign QR 코드에서 `otpauth://` URI 추출 (1Password 등 사용)
- [ ] GitHub Secrets 2개 등록:
  - `CERTUM_OTP_URI` (QR 코드의 `otpauth://totp/...` 전체 URI)
  - `CERTUM_USERID` (`sdh@okr.best`)
- [ ] PR 빌드(`build-for-pr.yml`)로 서명 테스트

### 2.2 [중간] macOS 코드 서명

- [ ] Apple Developer Program 가입 ($99/년)
- [ ] Developer ID 인증서 발급
- [ ] GitHub Secrets 등록 (`OKRBEST_DESKTOP_MAC_INSTALLER_*`)

### 2.3 [중간] AWS S3 인프라

- [ ] 릴리스 버킷 생성: `releases.okrbest.com`
- [ ] 일일 빌드 버킷 생성: `okrbest-desktop-daily-builds`
- [ ] E2E 리포트 버킷 생성: `okrbest-cypress-report`
- [ ] GitHub Secrets 등록 (`OKRBEST_DESKTOP_RELEASE_AWS_*`, `OKRBEST_DESKTOP_DAILY_AWS_*`)

### 2.4 [중간] GitHub Secrets 전체 등록

인프라 준비 후 등록할 Secrets:

| Secret | 용도 | 상태 |
|--------|------|------|
| `CERTUM_OTP_URI` | Windows 코드 서명 | 미등록 |
| `CERTUM_USERID` | Windows 코드 서명 | 미등록 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | macOS 서명 | 미등록 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | macOS 서명 | 미등록 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | macOS 서명 | 미등록 |
| `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | S3 릴리스 배포 | 미등록 |
| `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | S3 릴리스 배포 | 미등록 |
| `OKRBEST_BUILD_GH_TOKEN` | GitHub Releases 생성 | 미등록 |
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리스 알림 | 미등록 |

### 2.5 [낮음] 외부 링크/상수

`src/common/constants.ts` 내 외부 링크 URL (인프라 준비 후):

| 상수 | 변경 필요 |
|------|-----------|
| `DEFAULT_HELP_LINK` | OKR Best 도움말 URL |
| `DEFAULT_ACADEMY_LINK` | OKR Best 아카데미 URL |
| `DEFAULT_TE_REPORT_PROBLEM_LINK` | OKR Best 버그 리포트 URL |
| `DEFAULT_EE_REPORT_PROBLEM_LINK` | OKR Best 지원 URL |
| `DEFAULT_UPGRADE_LINK` | OKR Best 업그레이드 URL |
| `DEFAULT_CHANGELOG_LINK` | OKR Best 변경 이력 URL |

### ~~2.6 [낮음] 테스트 파일~~ ✅ 완료

테스트 파일 검토 완료. 앱 동작에 영향을 주는 mock 값 2곳 수정:
- `AutoLauncher.test.js`: `app.name` → `'OKR Best'`
- `initialize.test.js`: 프로토콜 mock → `name: 'OKR Best'`, `schemes: ['okrbest', 'mattermost']`

나머지 잔여 참조(~300곳)는 변경 불필요:
- 저작권 헤더 (라이선스 의무), 클래스명 import (`MattermostServer` 등 소스 클래스와 일치),
  `mattermost://` 프로토콜 테스트 (호환성), 서버 응답 mock, 테스트 도메인 URL

---

## 3. 변경하면 안 되는 항목 (서버 호환성)

### 서버 프로토콜 호환 (Mattermost 서버 기반)

| 항목 | 값 | 이유 |
|------|-----|------|
| `COOKIE_NAME_USER_ID` | `'MMUSERID'` | 서버 인증 쿠키명 |
| `COOKIE_NAME_CSRF` | `'MMCSRF'` | 서버 CSRF 보호 쿠키 |
| `COOKIE_NAME_AUTH_TOKEN` | `'MMAUTHTOKEN'` | 서버 인증 토큰 쿠키 |
| `CALLS_PLUGIN_ID` | `'com.mattermost.calls'` | 서버 Calls 플러그인 ID |
| `com.mattermost.nps` | NPS 플러그인 ID | 서버 플러그인 식별 |
| `com.mattermost.plugin-channel-export` | 채널 내보내기 플러그인 | 서버 URL 경로 |
| `protocols` 내 `mattermost` 스키마 | Mattermost 서버 호환 | 딥링크 호환성 |

> 서버가 쿠키명/플러그인 ID를 변경하지 않는 한 데스크톱 앱에서 단독 변경 불가.

### 라이선스 준수 (Apache 2.0)

- `LICENSE.txt` 내 원본 저작권 유지
- `NOTICE.txt` 내 원본 프로젝트 정보 유지
- 소스 파일 헤더의 원본 저작권 라인 유지
- `@mattermost/compass-icons` 등 외부 의존성 패키지명 유지

---

## 4. 작업 우선순위 요약

| 우선순위 | 작업 | 인프라 필요 | 상태 |
|----------|------|:-----------:|------|
| **높음** | Windows 코드 서명 Secrets 등록 (2.1) | **예** | 미완료 |
| **중간** | macOS 코드 서명 (2.2) | **예** | 미완료 |
| **중간** | AWS S3 버킷 생성 (2.3) | **예** | 미완료 |
| **중간** | GitHub Secrets 전체 등록 (2.4) | **예** | 미완료 |
| **낮음** | 외부 링크 상수 (2.5) | **예** | 미완료 |
| **낮음** | 테스트 파일 정리 (2.6) | 아니오 | 미완료 |

---

*이 문서는 리브랜딩 진행에 따라 업데이트합니다.*
