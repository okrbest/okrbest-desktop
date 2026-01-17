# GitHub 워크플로우 인프라 설정 가이드

이 문서는 OKR Best Desktop CI/CD 파이프라인을 완전히 운영하기 위해 필요한 인프라 설정을 상세히 정리합니다.

---

## 📋 인프라 요약

| 구분 | 항목 | 수량 |
|------|------|------|
| AWS S3 버킷 | 릴리스, Nightly, E2E 리포트 | 3개 |
| GitHub Secrets | 인증, 서명, API 키 | 25개 |
| 환경변수 (코드 참조) | 빌드/테스트 설정 | 6개 |
| 워크플로우 파일 | 수정 필요 | 8개 |
| 코드 파일 | 환경변수 참조 | 2개 |
| 외부 Actions | Mattermost 알림 | 1개 |
| Webhook | 릴리스/Nightly 알림 | 2개 |

---

## 🔄 작업 순서

### Phase 1: 코드 파일 수정 (환경변수 참조)

코드에서 직접 참조하는 환경변수를 먼저 수정해야 합니다.

#### 1.1 webpack.config.base.js

| 라인 | 현재 | 변경 |
|------|------|------|
| 22 | `MM_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` | `OKRBEST_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` |
| 23 | `MM_DESKTOP_BUILD_DISABLEGPU` | `OKRBEST_DESKTOP_BUILD_DISABLEGPU` |
| 24 | `MM_DESKTOP_BUILD_SENTRYDSN` | `OKRBEST_DESKTOP_BUILD_SENTRYDSN` |

#### 1.2 e2e/modules/environment.js

| 라인 | 현재 | 변경 |
|------|------|------|
| 36 | `MM_TEST_SERVER_URL` | `OKRBEST_TEST_SERVER_URL` |
| 232 | `MM_TEST_USER_NAME` | `OKRBEST_TEST_USER_NAME` |
| 233 | `MM_TEST_PASSWORD` | `OKRBEST_TEST_PASSWORD` |

---

### Phase 2: GitHub Secrets 등록 (25개)

GitHub 레포지토리 Settings → Secrets and variables → Actions에서 새 이름으로 등록합니다.

#### 2.1 Windows 코드 서명 (Azure)

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_ID` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_ID` | 4개 파일 |
| `MM_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_SECRET` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_SECRET` | 4개 파일 |
| `MM_DESKTOP_MSI_INSTALLER_AZURE_TENANT_ID` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_TENANT_ID` | 4개 파일 |

**사용 위치:** build-for-pr.yml, nightly-main.yml, nightly-rainforest.yml, release.yaml

#### 2.2 macOS Developer ID 코드 서명

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | 4개 파일 |
| `MM_DESKTOP_MAC_INSTALLER_CSC_LINK` | `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | 4개 파일 |
| `MM_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | 4개 파일 |

**사용 위치:** build-for-pr.yml, nightly-main.yml, nightly-rainforest.yml, release.yaml

#### 2.3 macOS App Store Connect

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | 5개 파일 |
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | 5개 파일 |
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | 5개 파일 |
| `MM_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | 2개 파일 |
| `MM_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | 2개 파일 |
| `MM_DESKTOP_MAC_APP_STORE_CSC_LINK` | `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` | 2개 파일 |

**사용 위치:** build-for-pr.yml, nightly-main.yml, nightly-rainforest.yml, release.yaml, release-mas.yaml

#### 2.4 AWS 자격증명

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | 2개 파일 |
| `MM_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | 2개 파일 |
| `MM_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | 1개 파일 |
| `MM_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | 1개 파일 |

**사용 위치:** nightly-main.yml, release.yaml, nightly-rainforest.yml

#### 2.5 E2E 테스트

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_E2E_USER_NAME` | `OKRBEST_DESKTOP_E2E_USER_NAME` | 1개 파일 |
| `MM_DESKTOP_E2E_USER_CREDENTIALS` | `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | 1개 파일 |
| `MM_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | 1개 파일 |
| `MM_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | 1개 파일 |
| `MM_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | 1개 파일 |
| `MM_DESKTOP_E2E_WEBHOOK_URL` | `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | 1개 파일 |
| `MM_DESKTOP_E2E_ZEPHYR_API_KEY` | `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | 1개 파일 |

**사용 위치:** e2e-functional-template.yml

#### 2.6 Webhook

| 현재 | 변경 | 사용 파일 |
|------|------|----------|
| `MM_DESKTOP_NIGHTLY_WEBHOOK_URL` | `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` | 1개 파일 |
| `MM_DESKTOP_RELEASE_WEBHOOK_URL` | `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 1개 파일 |

**사용 위치:** nightly-main.yml, release.yaml

---

### Phase 3: 워크플로우 파일 수정 (8개)

#### 3.1 build-for-pr.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 124 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 125 | `MM_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_ID` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_ID` |
| 126 | `MM_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_SECRET` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_CLIENT_SECRET` |
| 127 | `MM_DESKTOP_MSI_INSTALLER_AZURE_TENANT_ID` | `OKRBEST_DESKTOP_MSI_INSTALLER_AZURE_TENANT_ID` |
| 166 | `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` |
| 167 | `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` |
| 169 | `MM_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` |
| 171 | `MM_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` |
| 172 | `MM_DESKTOP_MAC_INSTALLER_CSC_LINK` | `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` |
| 173 | `MM_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` |

#### 3.2 nightly-main.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 23 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 89 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 90-92 | `MM_DESKTOP_MSI_INSTALLER_*` | `OKRBEST_DESKTOP_MSI_INSTALLER_*` |
| 111-117 | `MM_DESKTOP_MAC_APP_STORE_*` | `OKRBEST_DESKTOP_MAC_APP_STORE_*` |
| 171-178 | `MM_DESKTOP_MAC_*` | `OKRBEST_DESKTOP_MAC_*` |
| 213-214 | `MM_DESKTOP_RELEASE_AWS_*` | `OKRBEST_DESKTOP_RELEASE_AWS_*` |
| 258 | `MM_DESKTOP_NIGHTLY_WEBHOOK_URL` | `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` |

#### 3.3 nightly-rainforest.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 23 | `MM_DESKTOP_BUILD_DISABLEGPU: true` | `OKRBEST_DESKTOP_BUILD_DISABLEGPU: true` |
| 24 | `MM_DESKTOP_BUILD_SKIPONBOARDINGSCREENS: true` | `OKRBEST_DESKTOP_BUILD_SKIPONBOARDINGSCREENS: true` |
| 25 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 56-59 | `MM_DESKTOP_MSI_INSTALLER_*` | `OKRBEST_DESKTOP_MSI_INSTALLER_*` |
| 98-105 | `MM_DESKTOP_MAC_*` | `OKRBEST_DESKTOP_MAC_*` |
| 137-138 | `MM_DESKTOP_DAILY_AWS_*` | `OKRBEST_DESKTOP_DAILY_AWS_*` |

#### 3.4 release.yaml

| 라인 | 현재 | 변경 |
|------|------|------|
| 15 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 31 | `MM_DESKTOP_RELEASE_WEBHOOK_URL` | `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` |
| 101 | `MM_WIN_INSTALLERS: 1` | `OKRBEST_WIN_INSTALLERS: 1` |
| 102-104 | `MM_DESKTOP_MSI_INSTALLER_*` | `OKRBEST_DESKTOP_MSI_INSTALLER_*` |
| 146-153 | `MM_DESKTOP_MAC_*` | `OKRBEST_DESKTOP_MAC_*` |
| 182-183 | `MM_DESKTOP_RELEASE_AWS_*` | `OKRBEST_DESKTOP_RELEASE_AWS_*` |
| 249 | `MM_DESKTOP_RELEASE_WEBHOOK_URL` | `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` |

#### 3.5 release-mas.yaml

| 라인 | 현재 | 변경 |
|------|------|------|
| 21-27 | `MM_DESKTOP_MAC_APP_STORE_*` | `OKRBEST_DESKTOP_MAC_APP_STORE_*` |

#### 3.6 e2e-functional-template.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 6, 76 | `MM_TEST_SERVER_URL` | `OKRBEST_TEST_SERVER_URL` |
| 10, 80 | `MM_TEST_USER_NAME` | `OKRBEST_TEST_USER_NAME` |
| 14, 84 | `MM_TEST_PASSWORD` | `OKRBEST_TEST_PASSWORD` |
| 42, 113, 136 | `MM_SERVER_VERSION` | `OKRBEST_SERVER_VERSION` |
| 122-133 | `MM_*` 환경변수/시크릿 | `OKRBEST_*` |

#### 3.7 e2e-functional.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 16 | `MM_TEST_USER_NAME` | `OKRBEST_TEST_USER_NAME` |
| 20 | `MM_TEST_PASSWORD` | `OKRBEST_TEST_PASSWORD` |
| 24 | `MM_SERVER_VERSION` | `OKRBEST_SERVER_VERSION` |
| 76-79 | `MM_*` 환경변수 | `OKRBEST_*` |

#### 3.8 compatibility-matrix-testing.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 97 | `MM_TEST_SERVER_URL` | `OKRBEST_TEST_SERVER_URL` |
| 99 | `MM_SERVER_VERSION` | `OKRBEST_SERVER_VERSION` |

---

### Phase 4: AWS 인프라 설정

#### 4.1 릴리스 배포 버킷

**현재:** `s3://releases.mattermost.com/desktop/`  
**변경:** `s3://releases.okrbest.com/desktop/`

**사용 위치:**
- `.github/workflows/release.yaml` (line 198)
- `.github/workflows/nightly-main.yml` (line 227, 235-239)

**필요 설정:**
```bash
# S3 버킷 생성
aws s3 mb s3://releases.okrbest.com

# 퍼블릭 읽기 정책 설정
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

#### 4.2 일일 빌드 버킷 (Rainforest)

**현재:** `s3://mattermost-desktop-daily-builds/`  
**변경:** `s3://okrbest-desktop-daily-builds/`

**사용 위치:**
- `.github/workflows/nightly-rainforest.yml` (line 155)

#### 4.3 E2E 테스트 리포트 버킷

**현재:** `mattermost-cypress-report`  
**변경:** `okrbest-cypress-report`

**사용 위치:**
- `.github/workflows/e2e-functional-template.yml` (line 118)

---

### Phase 5: 외부 Actions 대체

#### 5.1 Mattermost 알림 Action

**현재 사용:**
```yaml
uses: mattermost/action-mattermost-notify@d317daebed2a792679f68fd0248557a8d21d82b6
```

**대안 옵션:**

##### 옵션 A: Action 포크
```bash
# 1. mattermost/action-mattermost-notify 포크
# 2. okrbest/action-mattermost-notify로 사용

uses: okrbest/action-mattermost-notify@main
```

##### 옵션 B: 범용 Webhook 사용
```yaml
- name: Send notification
  run: |
    curl -X POST -H 'Content-Type: application/json' \
      -d '{"text": "${{ env.MESSAGE }}", "username": "OKRBestRelease"}' \
      ${{ secrets.OKRBEST_RELEASE_WEBHOOK_URL }}
```

##### 옵션 C: Slack 알림으로 대체
```yaml
uses: slackapi/slack-github-action@v1
with:
  channel-id: 'releases'
  slack-message: 'Release ${{ env.VERSION }} started'
```

#### 5.2 커밋 상태 업데이트 Action

**현재 사용:**
```yaml
uses: mattermost/actions/delivery/update-commit-status@main
```

**대안: GitHub Script 사용**
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

---

### Phase 6: 기존 Secrets 삭제

모든 테스트가 완료된 후 기존 `MM_*` 시크릿을 삭제합니다.

---

## 📊 환경변수 참조 요약

### 코드에서 참조하는 환경변수 (변경 시 코드도 수정 필요)

| 환경변수 | 파일 | 라인 |
|----------|------|------|
| `MM_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` | `webpack.config.base.js` | 22 |
| `MM_DESKTOP_BUILD_DISABLEGPU` | `webpack.config.base.js` | 23 |
| `MM_DESKTOP_BUILD_SENTRYDSN` | `webpack.config.base.js` | 24 |
| `MM_TEST_SERVER_URL` | `e2e/modules/environment.js` | 36 |
| `MM_TEST_USER_NAME` | `e2e/modules/environment.js` | 232 |
| `MM_TEST_PASSWORD` | `e2e/modules/environment.js` | 233 |

### Workflow에서만 사용하는 환경변수 (코드 참조 없음)

| 환경변수 | 용도 |
|----------|------|
| `MM_WIN_INSTALLERS` | Windows 설치 파일 빌드 플래그 |
| `MM_SERVER_VERSION` | 테스트 서버 버전 |

---

## 💰 비용 예상

| 항목 | 예상 비용 |
|------|----------|
| AWS S3 (월) | ~$5-20 (사용량에 따라) |
| Windows EV 코드 서명 (년) | ~$300-500 |
| Apple Developer Program (년) | $99 |
| **합계 (연간)** | **~$500-700** |

---

## 🚧 임시 대안 (인프라 준비 전)

인프라가 준비되기 전까지 CI/CD를 비활성화하거나 최소 기능만 유지:

```yaml
# 릴리스 워크플로우 임시 비활성화
on:
  push:
    tags:
      - "v[0-9]+.[0-9]+.[0-9]+"
  # workflow_dispatch: # 수동 트리거만 허용
```

또는 로컬 빌드 후 수동 배포:
```bash
# 로컬에서 빌드
npm run package:linux
npm run package:windows
npm run package:mac

# 수동으로 GitHub Release 생성
```

---

## 📚 참고 자료

- [AWS S3 정적 웹사이트 호스팅](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Windows 코드 서명 가이드](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
