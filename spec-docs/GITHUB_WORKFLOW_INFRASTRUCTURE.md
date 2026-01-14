# GitHub 워크플로우 인프라 설정 가이드

이 문서는 OKR Best Desktop CI/CD 파이프라인을 완전히 운영하기 위해 필요한 인프라 설정을 상세히 정리합니다.

---

## 📋 인프라 요약

| 구분 | 항목 | 수량 |
|------|------|------|
| AWS S3 버킷 | 릴리스, Nightly, E2E 리포트 | 3개 |
| GitHub Secrets | 인증, 서명, API 키 | 20+개 |
| 외부 Actions | Mattermost 알림 | 1개 |
| Webhook | 릴리스/Nightly 알림 | 2개 |

---

## 1️⃣ AWS S3 버킷

### 1.1 릴리스 배포 버킷

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

### 1.2 일일 빌드 버킷 (Rainforest)

**현재:** `s3://mattermost-desktop-daily-builds/`  
**변경:** `s3://okrbest-desktop-daily-builds/`

**사용 위치:**
- `.github/workflows/nightly-rainforest.yml` (line 155)

### 1.3 E2E 테스트 리포트 버킷

**현재:** `mattermost-cypress-report`  
**변경:** `okrbest-cypress-report`

**사용 위치:**
- `.github/workflows/e2e-functional-template.yml` (line 118)

---

## 2️⃣ GitHub Secrets

### 2.1 AWS 자격증명

| Secret 이름 | 용도 | 사용 위치 |
|------------|------|----------|
| `MM_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | 릴리스 S3 업로드 | release.yaml, nightly-main.yml |
| `MM_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | 릴리스 S3 업로드 | release.yaml, nightly-main.yml |
| `MM_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | E2E 리포트 S3 업로드 | e2e-functional-template.yml |
| `MM_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | E2E 리포트 S3 업로드 | e2e-functional-template.yml |

**권장 변경:**
```
MM_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID → OKRBEST_RELEASE_AWS_ACCESS_KEY_ID
MM_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY → OKRBEST_RELEASE_AWS_SECRET_ACCESS_KEY
MM_DESKTOP_E2E_AWS_ACCESS_KEY_ID → OKRBEST_E2E_AWS_ACCESS_KEY_ID
MM_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY → OKRBEST_E2E_AWS_SECRET_ACCESS_KEY
```

### 2.2 Windows 코드 서명

| Secret 이름 | 용도 |
|------------|------|
| `MM_DESKTOP_MSI_INSTALLER_PFX_KEY` | PFX 키 |
| `MM_DESKTOP_MSI_INSTALLER_CSC_KEY_PASSWORD` | 인증서 비밀번호 |
| `MM_DESKTOP_MSI_INSTALLER_PFX` | PFX 파일 (Base64) |
| `MM_DESKTOP_MSI_INSTALLER_CSC_LINK` | 인증서 링크 |

**사용 위치:** release.yaml (line 102-105), nightly-main.yml (line 90-93)

### 2.3 macOS 코드 서명 및 App Store

| Secret 이름 | 용도 |
|------------|------|
| `MM_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | Developer ID 인증서 비밀번호 |
| `MM_DESKTOP_MAC_INSTALLER_CSC_LINK` | Developer ID 인증서 |
| `MM_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | DMG 프로비저닝 프로파일 |
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | App Store Connect API 키 ID |
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | App Store Connect API 키 |
| `MM_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | App Store Connect Issuer ID |
| `MM_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | MAS 인증서 비밀번호 |
| `MM_DESKTOP_MAC_APP_STORE_CSC_LINK` | MAS 인증서 |
| `MM_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | MAS 프로비저닝 프로파일 |

### 2.4 Webhook 및 API

| Secret 이름 | 용도 |
|------------|------|
| `MM_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리스 알림 Webhook |
| `MM_DESKTOP_NIGHTLY_WEBHOOK_URL` | Nightly 알림 Webhook |
| `MM_DESKTOP_E2E_WEBHOOK_URL` | E2E 테스트 알림 Webhook |
| `MATTERMOST_BUILD_GH_TOKEN` | GitHub Release 생성 토큰 |

### 2.5 E2E 테스트

| Secret 이름 | 용도 |
|------------|------|
| `MM_DESKTOP_E2E_USER_NAME` | 테스트 사용자 이름 |
| `MM_DESKTOP_E2E_USER_CREDENTIALS` | 테스트 사용자 비밀번호 |
| `MM_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | Zephyr 테스트 사이클 링크 |
| `MM_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr API 키 |

---

## 3️⃣ 외부 GitHub Actions

### 3.1 Mattermost 알림 Action

**현재 사용:**
```yaml
uses: mattermost/action-mattermost-notify@d317daebed2a792679f68fd0248557a8d21d82b6
```

**대안 옵션:**

#### 옵션 A: Action 포크
```bash
# 1. mattermost/action-mattermost-notify 포크
# 2. okrbest/action-mattermost-notify로 사용

uses: okrbest/action-mattermost-notify@main
```

#### 옵션 B: 범용 Webhook 사용
```yaml
- name: Send notification
  run: |
    curl -X POST -H 'Content-Type: application/json' \
      -d '{"text": "${{ env.MESSAGE }}", "username": "OKRBestRelease"}' \
      ${{ secrets.OKRBEST_RELEASE_WEBHOOK_URL }}
```

#### 옵션 C: Slack 알림으로 대체
```yaml
uses: slackapi/slack-github-action@v1
with:
  channel-id: 'releases'
  slack-message: 'Release ${{ env.VERSION }} started'
```

### 3.2 커밋 상태 업데이트 Action

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

## 4️⃣ 워크플로우 파일 수정 목록

### 4.1 release.yaml

| 라인 | 현재 | 변경 |
|------|------|------|
| 29 | `mattermost/action-mattermost-notify@...` | 대안 선택 |
| 31 | `MM_DESKTOP_RELEASE_WEBHOOK_URL` | `OKRBEST_RELEASE_WEBHOOK_URL` |
| 32 | `MattermostRelease` | `OKRBestRelease` |
| 33 | `https://mattermost.com/wp-content/uploads/...` | OKR Best 아이콘 URL |
| 183-184 | `MM_DESKTOP_RELEASE_AWS_*` | `OKRBEST_RELEASE_AWS_*` |
| 198 | `s3://releases.mattermost.com/desktop/` | `s3://releases.okrbest.com/desktop/` |
| 222 | `MATTERMOST_BUILD_GH_TOKEN` | `OKRBEST_BUILD_GH_TOKEN` |
| 248-252 | Webhook 설정 | 동일하게 변경 |

### 4.2 nightly-main.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 90-93 | `MM_DESKTOP_MSI_INSTALLER_*` | 유지 또는 `OKRBEST_*` |
| 112-118 | `MM_DESKTOP_MAC_APP_STORE_*` | 유지 또는 `OKRBEST_*` |
| 214-215 | `MM_DESKTOP_RELEASE_AWS_*` | `OKRBEST_RELEASE_AWS_*` |
| 227 | `s3://releases.mattermost.com/desktop/` | `s3://releases.okrbest.com/desktop/` |
| 235-239 | `releases.mattermost.com` | `releases.okrbest.com` |
| 259 | `MM_DESKTOP_NIGHTLY_WEBHOOK_URL` | `OKRBEST_NIGHTLY_WEBHOOK_URL` |

### 4.3 nightly-rainforest.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 152-153 | `mattermost` (파일명 패턴) | `okrbest` |
| 155 | `s3://mattermost-desktop-daily-builds/` | `s3://okrbest-desktop-daily-builds/` |

### 4.4 e2e-functional-template.yml

| 라인 | 현재 | 변경 |
|------|------|------|
| 118 | `mattermost-cypress-report` | `okrbest-cypress-report` |
| 121 | `MM` (JIRA 프로젝트 키) | OKR Best JIRA 키 또는 삭제 |
| 123-124 | `MM_DESKTOP_E2E_USER_*` | `OKRBEST_E2E_USER_*` |
| 128-133 | 기타 E2E secrets | `OKRBEST_*` |

---

## 5️⃣ 구현 순서

### Phase 1: AWS 인프라 (1-2일)
1. S3 버킷 3개 생성
2. IAM 사용자 생성 및 정책 연결
3. 버킷 퍼블릭 읽기 정책 설정

### Phase 2: 코드 서명 인증서 (1주)
1. Windows EV 코드 서명 인증서 구매
2. macOS Developer ID 인증서 발급
3. Mac App Store 프로비저닝 프로파일 생성

### Phase 3: GitHub 설정 (1일)
1. Secrets 등록 (20+개)
2. 워크플로우 파일 수정
3. 테스트 실행

### Phase 4: 알림 시스템 (1일)
1. Webhook URL 생성 (OKR Best 서버 또는 Slack)
2. 알림 Action 대안 구현
3. 테스트

---

## 6️⃣ 비용 예상

| 항목 | 예상 비용 |
|------|----------|
| AWS S3 (월) | ~$5-20 (사용량에 따라) |
| Windows EV 코드 서명 (년) | ~$300-500 |
| Apple Developer Program (년) | $99 |
| **합계 (연간)** | **~$500-700** |

---

## 7️⃣ 임시 대안 (인프라 준비 전)

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

## 참고 자료

- [AWS S3 정적 웹사이트 호스팅](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Windows 코드 서명 가이드](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Apple Developer Program](https://developer.apple.com/programs/)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
