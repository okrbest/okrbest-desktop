# OKRBEST Desktop CI/CD 가이드

> GitHub Actions 기반 CI/CD 파이프라인, 배포 환경 설정, 운영 체크리스트

---

## 1. 파이프라인 개요

### 1.1 워크플로우 파일 목록

| 워크플로우 | 트리거 | 목적 |
|-----------|--------|------|
| `release.yaml` | Git 태그 `v*.*.*`, `v*.*.*-rc.*` | 정식 릴리스/RC 빌드, S3 업로드, GitHub Release 드래프트 생성 |
| `release-mas.yaml` | Git 태그 `v*.*.*-rc.*`, `v*.*.*-mas.*` | Mac App Store용 패키징 및 `fastlane publish_test` 실행 |
| `run-release-script.yml` | 수동 (`workflow_dispatch`) | `scripts/release.sh` 실행, 태그/버전 자동화 |
| `ci.yaml` | Pull Request | PR 검증용 빌드 + 테스트 |
| `build-for-pr.yml` | PR 라벨 `Build Apps for PR` | PR용 배포 아티팩트 생성 |
| `nightly-builds.yaml` | 스케줄/수동 | 나이틀리 태그 생성 후 `nightly-main.yml`, `nightly-rainforest.yml` 호출 |
| `nightly-main.yml` | 재사용(`workflow_call`)/수동 | 나이틀리 메인 빌드, 릴리스 버킷 업로드, 링크 생성 |
| `nightly-rainforest.yml` | 재사용(`workflow_call`)/수동 | Rainforest 테스트용 빌드, 일일 빌드 버킷 업로드 |
| `e2e-functional.yml` | 수동 (`workflow_dispatch`) | 수동 매트릭스 E2E 실행 |
| `e2e-functional-template.yml` | 재사용(`workflow_call`)/수동 | E2E 실행 템플릿 |
| `compatibility-matrix-testing.yml` | 수동 (`workflow_dispatch`) | 서버/OS 조합별 호환성 매트릭스 테스트 |

### 1.2 빌드 플랫폼

- Linux: `ubuntu-22.04` (x64, arm64)
- Windows: `windows-2022` (x64, arm64)
- macOS: `macos-15` (x64, arm64, universal)

### 1.3 릴리스 배포 흐름

```text
태그 푸시 (v1.0.0 또는 v1.0.0-rc.1)
    ↓
begin-notification
    ↓
병렬 빌드
  - build-linux         (deb, rpm, flatpak, tar.gz, AppImage)
  - build-msi-installer (zip, msi + 선택적 Certum 서명)
  - build-mac-installer (zip, dmg x64/arm64/universal + 서명/공증)
    ↓
upload-to-s3
  - OIDC AssumeRole: OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME
  - Bucket Secret: OKRBEST_DESKTOP_RELEASE_BUCKET
    ↓
github-release
  - GitHub Release draft 생성
    ↓
end-notification
```

### 1.4 Mac App Store 배포 흐름

```text
태그 푸시 (v1.0.0-rc.1 또는 v1.0.0-mas.1)
    ↓
mac-app-store-preflight
  - MAS 프로비저닝 프로파일 복원
  - package:mas 실행
  - fastlane publish_test 실행
```

---

## 2. 릴리스 운영 절차

### 2.1 태그 규칙

- 정식 릴리스: `v1.0.0` -> `release.yaml`
- RC 릴리스: `v1.0.0-rc.1` -> `release.yaml` + `release-mas.yaml`
- MAS 전용 릴리스: `v1.0.0-mas.1` -> `release-mas.yaml`

### 2.2 수동 릴리스 절차

```bash
# 1. package.json / package-lock.json 버전 갱신
git add package.json package-lock.json
git commit -m "Bump version to 1.0.0"
git push origin main

# 2. 태그 푸시
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### 2.3 release.sh 기반 자동화 절차

`run-release-script.yml`은 `release-X.Y` 브랜치에서만 실행됩니다.

필수 설정:
- Secret: `OKRBEST_DESKTOP_BUILD_GH_TOKEN`
- Variable: `UNIFIED_CI_USERNAME`
- Variable: `UNIFIED_CI_EMAIL`

지원 입력값:
- `start`
- `rc`
- `pre-final`
- `final`
- `patch`

### 2.4 배포 확인

1. GitHub Actions에서 대상 워크플로우가 정상 완료됐는지 확인
2. GitHub Releases의 드래프트 릴리스 확인
3. S3 업로드 경로와 `latest*.yml` 또는 채널 포인터 파일(`latest.txt`, `rc.txt`, `nightly.txt` 등) 확인
4. 플랫폼별 다운로드 및 실행 확인

---

## 3. GitHub Actions 설정

**위치**: GitHub 저장소 -> Settings -> Secrets and variables -> Actions

### 3.1 Windows 코드 서명

`electron-builder.json`의 `"sign": false`는 유지합니다. Windows 서명은 빌드 후 `scripts/certum-sign.ps1`에서 별도 수행됩니다.

필수 Secrets:

| Secret | 용도 |
|--------|------|
| `CERTUM_OTP_URI` | SimplySign OTP용 `otpauth://...` 전체 URI |
| `CERTUM_USERID` | SimplySign 계정 이메일 |

사용 워크플로우:
- `release.yaml`
- `build-for-pr.yml`
- `nightly-main.yml`
- `nightly-rainforest.yml`

서명 단계 조건:

```yaml
if: ${{ secrets.CERTUM_OTP_URI != '' && secrets.CERTUM_USERID != '' }}
```

### 3.2 macOS Developer ID 서명

| Secret | 용도 |
|--------|------|
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | Developer ID 인증서 비밀번호 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | Developer ID 인증서 경로 또는 링크 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | DMG용 프로비저닝 프로파일(Base64) |

사용 워크플로우:
- `release.yaml`
- `build-for-pr.yml`
- `nightly-main.yml`
- `nightly-rainforest.yml`

### 3.3 macOS App Store Connect / MAS

| Secret | 용도 |
|--------|------|
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | App Store Connect API Key ID |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | App Store Connect API Key 내용 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | App Store Connect Issuer ID |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | MAS 프로비저닝 프로파일(Base64) |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | MAS 인증서 비밀번호 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` | MAS 인증서 경로 또는 링크 |

사용 워크플로우:
- `release.yaml`
- `release-mas.yaml`
- `build-for-pr.yml`
- `nightly-main.yml`
- `nightly-rainforest.yml`

### 3.4 AWS 배포

#### 릴리스/RC/나이틀리 메인 업로드

`release.yaml`과 `nightly-main.yml`은 AWS Access Key가 아니라 OIDC AssumeRole을 사용합니다.

| Secret | 용도 |
|--------|------|
| `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | 업로드용 IAM Role ARN |
| `OKRBEST_DESKTOP_RELEASE_BUCKET` | 릴리스 버킷 이름. 권장값: `releases.okrbest.com` |

#### Rainforest 일일 빌드 업로드

`nightly-rainforest.yml`은 정적 Access Key를 사용합니다.

| Secret | 용도 |
|--------|------|
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | 일일 빌드 업로드용 Access Key |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | 일일 빌드 업로드용 Secret Key |

### 3.5 E2E 테스트

| Secret | 용도 |
|--------|------|
| `OKRBEST_DESKTOP_E2E_USER_NAME` | 기본 E2E 테스트 계정명 |
| `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | 기본 E2E 테스트 비밀번호 |
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | E2E 리포트 업로드용 Access Key |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | E2E 리포트 업로드용 Secret Key |
| `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | E2E 결과 알림 웹훅 |
| `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr 연동 API Key |
| `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | 테스트 사이클 링크 Prefix |

고정 환경값:
- E2E 리포트 버킷: `okrbest-cypress-report`

### 3.6 기타 Secrets / Variables

| 이름 | 종류 | 용도 |
|------|------|------|
| `OKRBEST_DESKTOP_BUILD_GH_TOKEN` | Secret | GitHub Release 생성 및 `run-release-script.yml` checkout token |
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | Secret | 릴리스 시작/완료 알림 |
| `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` | Secret | 나이틀리 링크 공유 알림 |
| `UNIFIED_CI_USERNAME` | Variable | `run-release-script.yml` Git 사용자명 |
| `UNIFIED_CI_EMAIL` | Variable | `run-release-script.yml` Git 이메일 |

---

## 4. 인프라 설정

### 4.1 S3 버킷

| 버킷 | 현재 사용 방식 |
|------|---------------|
| `releases.okrbest.com` | 릴리스/RC/나이틀리 메인 업로드 대상. 실제 워크플로우에서는 `OKRBEST_DESKTOP_RELEASE_BUCKET` 값으로 참조 |
| `okrbest-desktop-daily-builds` | Rainforest 일일 빌드 업로드 대상. `nightly-rainforest.yml`에 하드코딩 |
| `okrbest-cypress-report` | E2E 리포트 업로드 대상. `e2e-functional-template.yml` 환경변수로 고정 |

### 4.2 릴리스 버킷 권장 설정

```bash
aws s3 mb s3://releases.okrbest.com

aws s3api put-bucket-policy --bucket releases.okrbest.com --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicRead",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::releases.okrbest.com/*"
  }]
}'
```

CORS 예시:

```json
[{
  "AllowedHeaders": ["*"],
  "AllowedMethods": ["GET", "HEAD"],
  "AllowedOrigins": ["*"],
  "ExposeHeaders": []
}]
```

### 4.3 릴리스 버킷 업로드 구조

`cp_artifacts.sh`와 릴리스 워크플로우 기준으로 버전 디렉터리와 updater 메타데이터가 함께 업로드됩니다.

```text
releases.okrbest.com/desktop/
├── latest.yml
├── latest-mac.yml
├── latest-linux.yml
├── latest.txt
├── <channel>.txt           # prerelease일 때 생성. 예: rc.txt, nightly.txt
└── {version}/
    ├── okrbest-desktop-{version}-win-x64.msi
    ├── okrbest-desktop-{version}-win-arm64.msi
    ├── okrbest-desktop-{version}-win-x64.zip
    ├── okrbest-desktop-{version}-win-arm64.zip
    ├── okrbest-desktop-{version}-mac-universal.dmg
    ├── okrbest-desktop-{version}-mac-x64.dmg
    ├── okrbest-desktop-{version}-mac-arm64.dmg
    ├── okrbest-desktop-{version}-linux-x64.tar.gz
    ├── okrbest-desktop-{version}-linux-arm64.tar.gz
    └── ...
```

### 4.4 Windows 산출물 기준

현재 Windows 릴리스 산출물은 아래 두 계열입니다.

- `zip`
- `msi`

문서상 NSIS는 현재 구현 기준에 포함되지 않습니다.

---

## 5. 현재 리브랜딩 상태

### 5.1 배포 환경 기준으로 반영 완료된 항목

- 주요 워크플로우의 Secret/환경변수는 `OKRBEST_*` 명명으로 전환됨
- Windows 서명용 `CERTUM_*` 시크릿 조건부 사용 적용됨
- 릴리스/나이틀리 알림 액션은 `okrbest/action-okrbest-notify@master` 사용
- E2E 템플릿 입력/환경변수는 `OKRBEST_TEST_*`, `OKRBEST_SERVER_VERSION` 기준으로 통일됨
- `webpack.config.base.js`는 `OKRBEST_DESKTOP_BUILD_SKIPONBOARDINGSCREENS`, `OKRBEST_DESKTOP_BUILD_DISABLEGPU`, `OKRBEST_DESKTOP_BUILD_SENTRYDSN`를 사용
- `e2e/modules/environment.js`는 `OKRBEST_TEST_SERVER_URL`, `OKRBEST_TEST_USER_NAME`, `OKRBEST_TEST_PASSWORD`를 사용

### 5.2 아직 남아 있는 배포 관련 잔여 항목

아래 항목은 CI/CD 또는 배포 안내와 직접 연결된 리브랜딩 미완료 영역입니다.

| 파일 | 현재 상태 |
|------|----------|
| `nightly-rainforest.yml` | 파일명 치환 정규식에 `mattermost` 문자열이 남아 있음 |
| `scripts/generate_release_post.sh` | GitHub 저장소 URL과 PR 링크가 Mattermost 기준으로 남아 있음 |

### 5.3 문서 운영 원칙

- 이 문서는 과거 TODO 기록이 아니라 현재 운영 기준서로 유지합니다.
- 완료된 항목과 미완료 항목을 한 섹션에 섞지 않습니다.
- 배포 환경과 무관한 일반 리브랜딩 잔여 작업은 별도 상태 문서에서 관리합니다.

---

## 6. 운영 체크리스트

### 6.1 신규 저장소 관리자 설정 체크리스트

- [ ] `OKRBEST_DESKTOP_BUILD_GH_TOKEN` 등록
- [ ] `UNIFIED_CI_USERNAME`, `UNIFIED_CI_EMAIL` Variables 등록
- [ ] Windows 서명용 `CERTUM_OTP_URI`, `CERTUM_USERID` 등록
- [ ] macOS Developer ID 서명용 `OKRBEST_DESKTOP_MAC_INSTALLER_*` 등록
- [ ] App Store Connect / MAS용 `OKRBEST_DESKTOP_MAC_APP_STORE_*` 등록
- [ ] 릴리스 업로드용 `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME`, `OKRBEST_DESKTOP_RELEASE_BUCKET` 등록
- [ ] Rainforest 업로드용 `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID`, `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` 등록
- [ ] E2E용 `OKRBEST_DESKTOP_E2E_*` Secrets 등록
- [ ] `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL`, `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` 등록

### 6.2 배포 후 검증 체크리스트

- [ ] GitHub Actions 전체 성공 확인
- [ ] GitHub Release draft 생성 확인
- [ ] S3 버킷 내 버전 디렉터리 및 메타데이터 파일 확인
- [ ] Windows `zip`/`msi`, macOS `dmg`, Linux 패키지 다운로드 확인
- [ ] 자동 업데이트 메타데이터(`latest*.yml`, `latest.txt` 또는 채널 포인터 파일) 확인

---

## 7. 트러블슈팅

### Windows 빌드 실패

- 코드 서명 실패: `CERTUM_OTP_URI`, `CERTUM_USERID` 존재 여부와 인증서 유효기간 확인
- MSI 빌드 실패: WiX 관련 오류 로그 확인

### macOS 빌드 실패

- 코드 서명 실패: Developer ID 인증서와 프로비저닝 프로파일 확인
- MAS 배포 실패: App Store Connect API Key, Issuer ID, MAS 프로파일 확인

### S3 업로드 실패

- 릴리스 업로드 실패: `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME`, `OKRBEST_DESKTOP_RELEASE_BUCKET` 값과 IAM Trust Policy 확인
- Rainforest 업로드 실패: `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID`, `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` 확인

### 자동 업데이트 문제

- `latest.yml` / `latest-mac.yml` / `latest-linux.yml` 형식 확인
- `latest.txt` 또는 채널 포인터 파일 생성 여부 확인
- 버킷 퍼블릭 읽기 정책 및 CORS 확인

---

## 부록: 주요 파일 경로

```text
워크플로우
├── .github/workflows/release.yaml
├── .github/workflows/release-mas.yaml
├── .github/workflows/run-release-script.yml
├── .github/workflows/ci.yaml
├── .github/workflows/build-for-pr.yml
├── .github/workflows/nightly-builds.yaml
├── .github/workflows/nightly-main.yml
├── .github/workflows/nightly-rainforest.yml
├── .github/workflows/e2e-functional.yml
├── .github/workflows/e2e-functional-template.yml
└── .github/workflows/compatibility-matrix-testing.yml

스크립트
├── scripts/certum-sign.ps1
├── scripts/cp_artifacts.sh
├── scripts/generate_latest_version.sh
├── scripts/generate_release_markdown.sh
└── scripts/generate_release_post.sh
```

---

*문서 기준일: 2026-03-10*
