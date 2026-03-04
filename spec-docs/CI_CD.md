# OKR Best Desktop CI/CD 가이드

> GitHub Actions 기반 CI/CD 파이프라인 구성, 배포 프로세스, 인프라 설정 가이드

---

## 1. 파이프라인 개요

### 1.1 워크플로우 파일 목록

| 워크플로우 | 트리거 | 목적 |
|-----------|--------|------|
| `release.yaml` | Git 태그 `v*.*.*` | 프로덕션 릴리스 배포 |
| `run-release-script.yml` | 수동 (workflow_dispatch) | release.sh 실행 (태그 생성, 버전 bump) |
| `ci.yaml` | Pull Request | PR 검증 (빌드 + 테스트) |
| `build-for-pr.yml` | PR 라벨 `Build Apps for PR` | PR용 빌드 아티팩트 생성 |
| `nightly-builds.yaml` | 스케줄/수동 | 나이틀리 빌드 |
| `release-mas.yaml` | Git 태그 `v*.*.*-mas.*` | Mac App Store 배포 |
| `nightly-main.yml` | 스케줄 | 주간 나이틀리 빌드 + S3 배포 |
| `nightly-rainforest.yml` | 수동 | Rainforest 테스트용 빌드 |
| `e2e-functional.yml` | PR/수동 | E2E 기능 테스트 |
| `e2e-functional-template.yml` | 재사용 | E2E 테스트 템플릿 |

### 1.2 빌드 플랫폼

- **Linux**: Ubuntu 22.04 (x64, arm64)
- **Windows**: Windows 2022 (x64, arm64)
- **macOS**: macOS 15 (x64, arm64, universal)

### 1.3 릴리스 배포 흐름

```
태그 푸시 (v1.0.0)
    ↓
begin-notification (알림)
    ↓
┌────────────────────────────────┐
│         병렬 빌드               │
│  build-linux    (deb, rpm, tar.gz, AppImage)
│  build-windows  (NSIS, MSI, ZIP + 코드 서명)
│  build-macos    (DMG x64, arm64, universal + 서명/공증)
└────────────────────────────────┘
    ↓
upload-to-s3 (S3 업로드)
    ↓
github-release (GitHub Releases 드래프트 생성)
    ↓
end-notification (완료 알림)
```

---

## 2. 릴리스 배포 절차

### 2.1 버전 업데이트 및 태그 생성

```bash
# 1. package.json 버전 수정
# 2. 커밋 및 푸시
git add package.json package-lock.json
git commit -m "Bump version to 1.0.0"
git push origin main

# 3. 태그 생성 및 푸시 → 자동으로 release.yaml 실행
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

**태그 형식:**
- 정식 릴리스: `v1.0.0`
- RC: `v1.0.0-rc.1`
- Mac App Store: `v1.0.0-mas.1`

### 2.2 배포 확인

1. GitHub Actions 탭에서 워크플로우 실행 확인 (약 20-30분)
2. Releases 탭에서 드래프트 릴리스 확인
3. 릴리스 노트 검토 후 "Publish release" 클릭

### 2.3 배포 후 확인

- [ ] 각 플랫폼 다운로드 링크 테스트
- [ ] 설치 및 실행 확인
- [ ] 자동 업데이트 감지 확인 (설정된 경우)

---

## 3. GitHub Secrets 설정

**위치**: GitHub 저장소 → Settings → Secrets and variables → Actions

### 3.1 Windows 코드 서명 (Certum SimplySign)

**인증서 상태**: Certum Standard Code Signing in the Cloud (365일) - ✅ 활성화 완료  
**조직**: OKRBEST Inc. (경기도 안양시, KR)  
**유효 기간**: 2026-02-14 ~ 2027-02-14  
**Serial**: `0e20f726ad841afdc64745642c4327b9`

`electron-builder.json`의 `"sign": false`는 유지합니다. 클라우드 서명은 빌드 후 `scripts/certum-sign.ps1`에서 별도 실행됩니다.

> **상세 가이드**: [spec-docs/Certum-SimplySign.md](Certum-SimplySign.md) (Certum 공식 문서 기준)

#### Runner 및 서명 방식

| 방식 | 현재 사용 | 설명 |
|------|----------|------|
| **GitHub Hosted** (windows-2022) | ✅ | TOTP 자동화(certum-sign.ps1)로 매 빌드마다 SimplySign 설치·로그인 후 서명 |
| **Self-hosted Windows Runner** | - | 로그인 세션 유지 중일 때 TOTP 없이 서명 (세션 만료 시 재인증). 실무 Best Practice |

#### 초보자 빠른 시작 (GitHub Hosted)

1. Certum 인증서 활성화 + SimplySign Mobile 활성화 완료
2. 활성화 QR 코드를 1Password로 스캔해서 `otpauth://...` URI 확보
3. GitHub Secrets 등록
   - `CERTUM_OTP_URI`: `otpauth://totp/...` 전체 URI
   - `CERTUM_USERID`: SimplySign 계정 이메일
4. Windows 빌드 워크플로우 실행 (`release.yaml` 또는 PR 빌드)
5. Actions 로그에서 아래 문구 확인
   - `TOTP code generated.`
   - `Using signtool:`
   - `Successfully signed:`
6. 빌드 아티팩트 다운로드 후 서명 검증

```powershell
signtool verify /pa path\to\okrbest-desktop.exe
signtool verify /pa path\to\okrbest-desktop.msi
```

#### 필요한 GitHub Secrets (2개)

| Secret | 용도 |
|--------|------|
| `CERTUM_OTP_URI` | `otpauth://totp/...?secret=...&period=30` 전체 URI (1Password로 QR 스캔 후 추출) |
| `CERTUM_USERID` | SimplySign 계정 이메일 |

조건: `if: ${{ secrets.CERTUM_OTP_URI != '' && secrets.CERTUM_USERID != '' }}`로 두 Secret이 모두 있을 때만 서명 단계 활성화.

#### 워크플로우 (적용 완료)

`release.yaml`, `build-for-pr.yml`, `nightly-main.yml`, `nightly-rainforest.yml`:

```yaml
- name: release/sign-windows-exe
  if: ${{ secrets.CERTUM_OTP_URI != '' && secrets.CERTUM_USERID != '' }}
  shell: powershell
  env:
    CERTUM_OTP_URI: ${{ secrets.CERTUM_OTP_URI }}
    CERTUM_USERID: ${{ secrets.CERTUM_USERID }}
  run: pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign.ps1 -FilePath "release/win*-unpacked/*.exe"
```

#### 첫 실행 성공 판정 (초보자용)

아래 3가지를 모두 만족하면 정상입니다.

1. Actions 로그에 `Successfully signed:`가 `.exe`, `.msi` 각각 출력됨
2. `Failing code signing step` 또는 `No files found matching pattern` 오류가 없음
3. 아티팩트에 대해 `signtool verify /pa` 검증 성공

#### 서명 없이 배포 시 영향

| 항목 | 영향 |
|------|------|
| SmartScreen | "Windows가 PC를 보호했습니다" 경고 |
| 사용자 경험 | "추가 정보" → "실행" 클릭 필요 |
| 기업 환경 | IT 정책으로 설치 차단 가능 |

### 3.2 macOS Developer ID 코드 서명

| Secret (변경 후 이름) | 용도 | 사용 파일 |
|----------------------|------|----------|
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | 인증서 비밀번호 | 4개 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | 인증서 파일 경로 | 4개 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | 프로비저닝 프로파일 (Base64) | 4개 |

### 3.3 macOS App Store Connect

| Secret (변경 후 이름) | 용도 | 사용 파일 |
|----------------------|------|----------|
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | Apple API 키 ID | 5개 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | Apple API 키 (Base64) | 5개 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | Apple API Issuer ID | 5개 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | MAS 프로비저닝 프로파일 | 2개 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | MAS 인증서 비밀번호 | 2개 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` | MAS 인증서 경로 | 2개 |

### 3.4 AWS S3 배포

| Secret (변경 후 이름) | 용도 |
|----------------------|------|
| `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | 릴리스 S3 Access Key |
| `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | 릴리스 S3 Secret Key |
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | 일일 빌드 S3 Access Key |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | 일일 빌드 S3 Secret Key |

### 3.5 E2E 테스트

| Secret (변경 후 이름) | 용도 |
|----------------------|------|
| `OKRBEST_DESKTOP_E2E_USER_NAME` | E2E 테스트 사용자명 |
| `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | E2E 테스트 인증 |
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | E2E 리포트 S3 Key |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | E2E 리포트 S3 Secret |
| `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | E2E 결과 알림 |
| `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr 연동 |
| `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | 테스트 사이클 링크 |

### 3.6 기타

| Secret (변경 후 이름) | 용도 |
|----------------------|------|
| `OKRBEST_DESKTOP_BUILD_GH_TOKEN` | GitHub Personal Access Token (`repo` 권한) - release.yaml, run-release-script.yml |
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리스 알림 웹훅 URL |
| `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` | 나이틀리 알림 웹훅 URL |

---

## 4. 인프라 설정

### 4.1 AWS S3 버킷

| 버킷 | 용도 | 변경 전 |
|------|------|---------|
| `releases.okrbest.com` | 릴리스 배포 | `releases.mattermost.com` |
| `okrbest-desktop-daily-builds` | 일일 빌드 | `mattermost-desktop-daily-builds` |
| `okrbest-cypress-report` | E2E 리포트 | `mattermost-cypress-report` |

**릴리스 버킷 설정:**

```bash
# 버킷 생성
aws s3 mb s3://releases.okrbest.com

# 퍼블릭 읽기 정책
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

**CORS 설정:**
```json
[{
  "AllowedHeaders": ["*"],
  "AllowedMethods": ["GET", "HEAD"],
  "AllowedOrigins": ["*"],
  "ExposeHeaders": []
}]
```

### 4.2 업데이트 서버 파일 구조

```
releases.okrbest.com/desktop/
├── latest.yml              # Windows 최신 버전 정보
├── latest-mac.yml          # macOS 최신 버전 정보
├── latest-linux.yml        # Linux 최신 버전 정보
└── {version}/
    ├── okrbest-desktop-{version}-win-x64.msi
    ├── okrbest-desktop-{version}-mac-universal.dmg
    ├── okrbest-desktop-{version}-linux-x64.tar.gz
    └── ...
```

### 4.3 비용 예상

| 항목 | 비용 |
|------|------|
| AWS S3 (월) | ~$5-20 |
| Windows 코드 서명 - Certum Standard (년) | €209 (~$230) ✅ 구매 완료 |
| Apple Developer Program (년) | $99 |
| **합계 (연간)** | **~$390-570** |

### 4.4 임시 대안 (인프라 준비 전)

인프라 없이 로컬 빌드 후 수동 배포:

```bash
# 로컬 빌드
npm run package:linux
npm run package:mac

# GitHub Release 수동 생성
gh release create v1.0.0 release/**/* --title "v1.0.0" --draft
```

---

## 5. 리브랜딩 남은 작업

### 5.1 워크플로우 환경변수 이름 변경

모든 `MM_*` 환경변수를 `OKRBEST_*`로 변경 필요.

**코드에서도 참조하는 변수 (코드+워크플로우 동시 수정 필요):**

| 현재 | 변경 후 | 코드 파일 |
|------|---------|----------|
| `MM_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` | `OKRBEST_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` | `webpack.config.base.js` (line 22) |
| `MM_DESKTOP_BUILD_DISABLEGPU` | `OKRBEST_DESKTOP_BUILD_DISABLEGPU` | `webpack.config.base.js` (line 23) |
| `MM_DESKTOP_BUILD_SENTRYDSN` | `OKRBEST_DESKTOP_BUILD_SENTRYDSN` | `webpack.config.base.js` (line 24) |
| `MM_TEST_SERVER_URL` | `OKRBEST_TEST_SERVER_URL` | `e2e/modules/environment.js` (line 36) |
| `MM_TEST_USER_NAME` | `OKRBEST_TEST_USER_NAME` | `e2e/modules/environment.js` (line 232) |
| `MM_TEST_PASSWORD` | `OKRBEST_TEST_PASSWORD` | `e2e/modules/environment.js` (line 233) |

**워크플로우에서만 사용하는 변수:**

| 현재 | 변경 후 |
|------|---------|
| `MM_WIN_INSTALLERS` | `OKRBEST_WIN_INSTALLERS` |
| `MM_SERVER_VERSION` | `OKRBEST_SERVER_VERSION` |

### ~~5.2 수정 필요한 워크플로우 파일~~ ✅ 완료

모든 워크플로우의 `MM_*` Secret/환경변수가 `OKRBEST_*`로 변경됨:
- `release.yaml` - Secrets, 환경변수, Webhook 알림 변경 완료
- `build-for-pr.yml` - macOS Secrets 변경 완료
- `nightly-main.yml` - Secrets, S3 URL, Webhook 변경 완료
- `nightly-rainforest.yml` - Secrets, S3 URL 변경 완료
- `release-mas.yaml` - macOS App Store Secrets 변경 완료
- `e2e-functional-template.yml` - 이미 `OKRBEST_*` 적용됨

### 5.3 스크립트 파일 수정

| 파일 | 변경 내용 |
|------|----------|
| `scripts/generate_release_markdown.sh` | 다운로드 URL, 제품명, 파일명 패턴 |
| `scripts/generate_release_post.sh` | GitHub 저장소 URL |

### 5.4 외부 Actions 대체

| 원래 | 변경 후 | 상태 |
|------|---------|------|
| `mattermost/action-mattermost-notify` | `okrbest/action-okrbest-notify@master` | ✅ 완료 |
| `mattermost/actions/delivery/update-commit-status` | `okrbest/actions/delivery/update-commit-status` | ✅ 완료 |
| `mattermost/actions-workflows/.../snyk-sbom.yml` | `okrbest/actions-workflows/.../snyk-sbom.yml` | ✅ 완료 |

대체 예시 (커밋 상태 업데이트):
```yaml
- name: Update commit status
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.repos.createCommitStatus({
        owner: context.repo.owner,
        repo: context.repo.repo,
        sha: context.sha,
        state: 'pending',
        context: 'e2e/${{ matrix.platform }}',
        description: 'E2E tests started...'
      })
```

### 5.5 GitHub 설정 (.github 폴더)

**완료됨:**
- [x] 이슈/PR 템플릿 수정
- [x] Dependabot 설정 수정
- [x] Actions 저작권 헤더 추가
- [x] 워크플로우 문구/URL 1차 수정

**남은 작업 (인프라 준비 후):**
- [ ] 워크플로우 S3 URL 변경
- [ ] Webhook 설정 변경
- [ ] GitHub Secrets 새 이름으로 등록
- [ ] 기존 `MM_*` Secrets 삭제

---

## 6. 트러블슈팅

### Windows 빌드 실패
- **코드 서명 실패**: Secrets 확인, 인증서 유효기간 확인
- **MSI 빌드 실패**: WiX Toolset 설치 확인

### macOS 빌드 실패
- **코드 서명 실패**: 인증서/프로비저닝 프로파일 확인, Apple Developer 계정 상태 확인
- **공증 실패**: API 키 및 Issuer ID 확인

### S3 업로드 실패
- **권한 오류**: IAM 권한 확인 (`s3:PutObject`, `s3:PutObjectAcl`)
- **경로 오류**: 버킷 이름/경로 확인

### 자동 업데이트 문제
- **`latest.yml` 형식 오류**: `patch_updater_yml.sh` 스크립트 확인
- **업데이트 서버 접근 불가**: CORS 설정 확인

---

## 부록: 주요 파일 경로

```
워크플로우:
├── .github/workflows/release.yaml
├── .github/workflows/run-release-script.yml
├── .github/workflows/ci.yaml
├── .github/workflows/build-for-pr.yml
├── .github/workflows/nightly-builds.yaml
├── .github/workflows/nightly-main.yml
├── .github/workflows/release-mas.yaml
├── .github/workflows/e2e-functional.yml
└── .github/workflows/e2e-functional-template.yml

스크립트:
├── scripts/patch_updater_yml.sh
├── scripts/generate_release_markdown.sh
├── scripts/generate_release_post.sh
└── scripts/cp_artifacts.sh

커스텀 액션:
└── .github/actions/test/action.yaml
```

---

*문서 작성일: 2026-02-14*
