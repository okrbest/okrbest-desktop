# OKR Best 리브랜딩 현황

> 마지막 업데이트: 2026-03-11
>
> 상태 라벨:
> - `완료`: 저장소에서 직접 확인됨
> - `미완료`: 저장소 기준으로 아직 남아 있음
> - `외부 미검증`: 저장소 밖 상태라 별도 확인 필요

---

## 리브랜딩 개요

| 항목 | 변경 전 | 변경 후 | 상태 |
|------|---------|---------|------|
| 제품명 | Mattermost Desktop | OKR Best | 완료 |
| 패키지명 | mattermost-desktop | okrbest-desktop | 완료 |
| 앱 ID | Mattermost.Desktop | OKRBest.Desktop | 완료 |
| Linux appId | com.Mattermost.Desktop | com.OKRBest.Desktop | 완료 |
| 프로토콜 | mattermost:// | okrbest:// + `mattermost://` 호환 유지 | 완료 |
| 홈페이지 | mattermost.com | okr.best | 완료 |
| 저장소 | mattermost/desktop | okrbest/okrbest-desktop | 완료 |

전체 진행률 수치는 문서에서 제거했습니다. 저장소 밖 상태가 섞여 있어 단일 퍼센트로 표현하면 오해 소지가 큽니다.

---

## 1. 완료된 작업

### 1.1 패키지 메타데이터

| 파일 | 필드 | 값 | 상태 |
|------|------|-----|------|
| `package.json` | `name` | `okrbest-desktop` | 완료 |
| `package.json` | `productName` | `OKR Best` | 완료 |
| `package.json` | `description` | `OKR Best Desktop` | 완료 |
| `package.json` | `author` | `OKR Best` | 완료 |
| `package.json` | `desktopName` | `OKRBest.Desktop` | 완료 |
| `package.json` | `homepage` | `https://okr.best` | 완료 |
| `package.json` | `repository` | `git://github.com/okrbest/okrbest-desktop.git` | 완료 |
| `package-lock.json` | `name` | `okrbest-desktop` | 완료 |

### 1.2 `electron-builder.json`

- `appId`: `OKRBest.Desktop`
- `linux.appId`: `com.OKRBest.Desktop`
- `protocols[0].name`: `OKR Best`
- `protocols[0].schemes`: `okrbest` 포함, `mattermost` 호환 스키마 유지
- `deb.synopsis`: `OKR Best Desktop App`
- macOS `NSFocusStatusUsageDescription`: OKR Best 기준 문구 적용

상태: 완료

### 1.3 README

- `README.md` 제목, 제품 설명, 다운로드/문서 링크, 데이터 디렉터리 예시가 OKR Best 기준으로 반영됨

상태: 완료

### 1.4 i18n 및 사용자 노출 문구

- 전체 i18n 파일에서 `Mattermost` 문자열 검색 결과 0건
- i18n 키 리브랜딩 확인:
  - `notMattermost` -> `notOKRBest`
  - `MattermostVersionX` -> `VersionX`
- 사용자 노출 기본 문구도 OKR Best 기준으로 반영됨

상태: 완료

### 1.5 소스 코드/상수 리브랜딩

- `URLValidationStatus.NotMattermost` -> `NotOKRBest`
- `src/common/config/buildConfig.ts` 내 릴리스/문서 URL이 OKR Best 기준으로 반영됨
- `src/main/utils.ts`, `src/main/notifications/dnd-windows.ts`의 앱 식별자 반영됨
- `src/common/constants.ts` 외부 링크가 이미 OKR Best URL로 반영됨

상태: 완료

### 1.6 Windows GPO 파일

- `resources/windows/gpo/okrbest.admx`
- `resources/windows/gpo/en-US/okrbest.adml`
- `resources/windows/gpo/README.md`

위 파일들의 파일명과 표시 문구가 OKR Best 기준으로 반영됨.

상태: 완료

### 1.7 릴리스 스크립트/패치 일부

- `scripts/generate_release_markdown.sh`: 릴리스 파일명 패턴과 URL이 OKR Best 기준으로 반영됨
- `patches/app-builder-lib+26.6.0.patch`: MSI 설치 경로, 실행 파일명, 메시지 반영됨

상태: 완료

### 1.8 Rainforest daily build 파일명 정리

- `.github/workflows/nightly-rainforest.yml`의 `mattermost` 기반 파일명 치환 정규식 제거
- Rainforest 업로드 전 `okrbest-desktop-${VERSION}-...` 산출물을 `okrbest-desktop-daily-develop-...` 고정 alias로 이동하도록 수정
- 이 변경으로 `daily-develop` stable key는 유지하면서, 날짜별 nightly 파일이 S3에 누적되지 않도록 기존 workflow 의도를 유지함

상태: 완료

### 1.9 저작권 헤더

- 다수의 파일에 OKR Best 추가 저작권 라인이 반영됨
- 원본 `Mattermost, Inc.` 저작권 라인은 Apache 2.0 및 upstream 추적을 위해 유지되는 것이 정상임

상태: 완료

### 1.10 테스트 파일 정리

- 앱 동작에 영향을 주는 mock 값 수정은 완료된 것으로 유지
- `mattermost://` 테스트, 클래스명, 서버 응답 mock 등은 호환성/구조상 유지되는 정상 예외로 간주

상태: 완료

---

## 2. 미완료 항목

### 2.1 워크플로우/배포 리브랜딩 잔여물

아래 항목 때문에 `워크플로우 전체 리브랜딩 완료`로 보기는 어렵습니다.

| 파일 | 잔여 내용 | 상태 |
|------|----------|------|
| `scripts/generate_release_post.sh` | GitHub 저장소 URL, PR 링크가 Mattermost 기준으로 남아 있음 | 미완료 |

### 2.2 릴리스 환경 문서/상태 동기화

- 워크플로우 Secret/Variable 이름은 대부분 `OKRBEST_*`로 전환되었지만, 운영 문서와 상태 문서의 설명은 주기적으로 재검증 필요
- 릴리스 업로드 방식은 Access Key가 아니라 `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` + `OKRBEST_DESKTOP_RELEASE_BUCKET` 기준으로 이미 구현되어 있음

상태: 미완료

### 2.3 아이콘 시각 검수

- 저장소에는 리브랜딩된 아이콘 자산이 반영되어 있지만, 최종 산출물 기준의 시각 검수 여부는 이 문서만으로 확정하지 않음

상태: 미완료

---

## 3. 외부 미검증 항목

이 섹션은 저장소 코드로는 판정할 수 없고, GitHub/AWS/Apple Developer 계정에서 별도 확인해야 하는 항목입니다.

### 3.1 GitHub Secrets / Variables 등록 상태

저장소 사용처는 존재하지만 실제 등록 여부는 별도 확인이 필요합니다.

| 이름 | 용도 | 저장소 사용처 | 상태 |
|------|------|---------------|------|
| `CERTUM_OTP_URI` | Windows 코드 서명 | 4개 워크플로우 | 외부 미검증 |
| `CERTUM_USERID` | Windows 코드 서명 | 4개 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | macOS Developer ID 서명 | release/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | macOS Developer ID 서명 | release/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | macOS 프로비저닝 프로파일 | release/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | App Store Connect | release/release-mas/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | App Store Connect | release/release-mas/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | App Store Connect | release/release-mas/build/nightly 워크플로우 | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | MAS 프로파일 | release-mas/nightly-main | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | MAS 인증서 | release-mas/nightly-main | 외부 미검증 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` | MAS 인증서 | release-mas/nightly-main | 외부 미검증 |
| `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | 릴리스/나이틀리 메인 S3 업로드 | `release.yaml`, `nightly-main.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_RELEASE_BUCKET` | 릴리스 버킷 이름 | `release.yaml`, `nightly-main.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | Rainforest 업로드 | `nightly-rainforest.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | Rainforest 업로드 | `nightly-rainforest.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_USER_NAME` | E2E 기본 계정 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | E2E 기본 비밀번호 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | E2E 리포트 업로드 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | E2E 리포트 업로드 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | E2E 결과 알림 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr 연동 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | 테스트 사이클 링크 | `e2e-functional-template.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_BUILD_GH_TOKEN` | GitHub Release 생성 / checkout token | `release.yaml`, `run-release-script.yml` | 외부 미검증 |
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리스 알림 | `release.yaml` | 외부 미검증 |
| `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` | 나이틀리 알림 | `nightly-main.yml` | 외부 미검증 |
| `UNIFIED_CI_USERNAME` | release 스크립트용 Git 사용자명 | `run-release-script.yml` | 외부 미검증 |
| `UNIFIED_CI_EMAIL` | release 스크립트용 Git 이메일 | `run-release-script.yml` | 외부 미검증 |

### 3.2 Apple / AWS 실제 인프라 상태

- Apple Developer Program 가입 여부
- Developer ID / MAS 인증서 실제 발급 여부
- `releases.okrbest.com` 버킷 실제 생성 여부
- `okrbest-desktop-daily-builds` 버킷 실제 생성 여부
- `okrbest-cypress-report` 버킷 실제 생성 여부
- Certum SimplySign 실제 계정/QR 등록 완료 여부

상태: 외부 미검증

---

## 4. 변경하면 안 되는 항목

### 4.1 서버 호환성

| 항목 | 값 | 이유 |
|------|-----|------|
| `COOKIE_NAME_USER_ID` | `'MMUSERID'` | 서버 인증 쿠키명 |
| `COOKIE_NAME_CSRF` | `'MMCSRF'` | 서버 CSRF 보호 쿠키 |
| `COOKIE_NAME_AUTH_TOKEN` | `'MMAUTHTOKEN'` | 서버 인증 토큰 쿠키 |
| `CALLS_PLUGIN_ID` | `'com.mattermost.calls'` | 서버 Calls 플러그인 ID |
| `com.mattermost.nps` | NPS 플러그인 ID | 서버 플러그인 식별 |
| `com.mattermost.plugin-channel-export` | 채널 내보내기 플러그인 | 서버 URL 경로 |
| `protocols` 내 `mattermost` 스키마 | 딥링크/서버 호환성 | 호환성 유지 필요 |

> 서버가 쿠키명이나 플러그인 ID를 바꾸지 않는 한 데스크톱 앱 단독으로 변경하면 안 됩니다.

### 4.2 라이선스 및 외부 의존성

- `LICENSE.txt` 내 원본 저작권 유지
- `NOTICE.txt` 내 원본 프로젝트 정보 유지
- 소스 파일의 원본 저작권 라인 유지
- `@mattermost/compass-icons`, `@mattermost/desktop-api`, `@mattermost/eslint-plugin` 같은 외부 의존성 패키지명 유지

---

## 5. 우선순위 요약

| 우선순위 | 작업 | 구분 | 상태 |
|----------|------|------|------|
| 높음 | `scripts/generate_release_post.sh`의 Mattermost GitHub 링크 교체 | 저장소 | 미완료 |
| 중간 | GitHub Secrets / Variables 실제 등록 여부 확인 | 외부 | 외부 미검증 |
| 중간 | Apple Developer / Certum / AWS 실제 인프라 상태 확인 | 외부 | 외부 미검증 |
| 낮음 | 리브랜딩 아이콘 최종 산출물 시각 검수 | 수동 검수 | 미완료 |

---

*이 문서는 리브랜딩 진행 상황을 추적하는 상태판이며, 저장소 기준 사실과 외부 미검증 상태를 분리해 기록합니다.*
