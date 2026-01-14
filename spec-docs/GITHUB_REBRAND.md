# GitHub 설정 리브랜딩 가이드

이 문서는 `.github` 폴더의 리브랜딩 작업을 단계별로 정리합니다.

---

## 📋 작업 개요

| 단계 | 작업 | 상태 |
|------|------|------|
| 1 | 이슈/PR 템플릿 수정 | ✅ 완료 |
| 2 | Dependabot 설정 수정 | ✅ 완료 |
| 3 | GitHub Actions 저작권 헤더 | ✅ 완료 |
| 4 | 워크플로우 파일 수정 (1차 - 문구/URL) | ✅ 완료 |
| 5 | 워크플로우 파일 수정 (2차 - 인프라) | ⬜ 대기 (인프라 준비 필요) |
| 6 | GitHub 시크릿 설정 | ⬜ 대기 (인프라 준비 필요) |

---

## 단계 1: 이슈/PR 템플릿 수정

### 1.1 PULL_REQUEST_TEMPLATE.md

**변경 사항:**
```diff
- https://developers.mattermost.com/contribute/getting-started/contribution-checklist/
+ https://docs.okrbest.com/contribute/getting-started/contribution-checklist/

- https://developers.mattermost.com/blog/2019-01-24-submitting-great-prs
+ https://docs.okrbest.com/contribute/submitting-great-prs

- https://developers.mattermost.com/contribute
+ https://docs.okrbest.com/contribute

- https://github.com/mattermost/desktop/issues/XXXXX
+ https://github.com/okrbest/okrbest-desktop/issues/XXXXX

- https://github.com/mattermost/desktop/blob/master/CONTRIBUTING.md
+ https://github.com/okrbest/okrbest-desktop/blob/master/CONTRIBUTING.md

- https://mattermost.com/contribute/
+ https://okr.best/contribute/
```

### 1.2 ISSUE_TEMPLATE/bug_report.yml

**변경 사항:**
```diff
- description: Create a report about an issue you found in the Mattermost Desktop App
+ description: Create a report about an issue you found in the OKR Best Desktop App

- https://github.com/mattermost/mattermost/issues
+ https://github.com/okrbest/okrbest/issues

- https://github.com/mattermost/mattermost-server/issues
+ https://github.com/okrbest/okrbest/issues

- https://github.com/mattermost/desktop/issues
+ https://github.com/okrbest/okrbest-desktop/issues

- https://forum.mattermost.com/c/trouble-shoot/16
+ https://forum.okrbest.com/c/trouble-shoot/16

- https://mattermost.com/suggestions/
+ https://okr.best/suggestions/

- https://github.com/mattermost/desktop/releases/latest
+ https://github.com/okrbest/okrbest-desktop/releases/latest

- https://github.com/mattermost/desktop/releases
+ https://github.com/okrbest/okrbest-desktop/releases

- https://github.com/mattermost/desktop/blob/master/CONTRIBUTING.md
+ https://github.com/okrbest/okrbest-desktop/blob/master/CONTRIBUTING.md

- label: Mattermost Desktop Version
+ label: OKR Best Desktop Version

- label: Mattermost Server Version
+ label: OKR Best Server Version

- [Mattermost Menu] > [About Mattermost]
+ [OKR Best Menu] > [About OKR Best]
```

### 1.3 ISSUE_TEMPLATE/crash_report.yml

**변경 사항:**
```diff
- description: Create a report about a crash you experienced while using the Mattermost Desktop App
+ description: Create a report about a crash you experienced while using the OKR Best Desktop App

- https://github.com/mattermost/desktop/issues
+ https://github.com/okrbest/okrbest-desktop/issues

- https://github.com/mattermost/mattermost-server/issues
+ https://github.com/okrbest/okrbest/issues

- https://github.com/mattermost/desktop/blob/master/CONTRIBUTING.md
+ https://github.com/okrbest/okrbest-desktop/blob/master/CONTRIBUTING.md

- label: Mattermost Desktop Version
+ label: OKR Best Desktop Version

- label: Mattermost Server Version
+ label: OKR Best Server Version

- "The Mattermost app quit unexpectedly"
+ "The OKR Best app quit unexpectedly"

- https://docs.mattermost.com/install/troubleshooting.html#mattermost-desktop-app-logs
+ https://docs.okrbest.com/install/troubleshooting.html#okrbest-desktop-app-logs
```

---

## 단계 2: Dependabot 설정 수정

### dependabot.yaml

**변경 사항:**
```diff
  reviewers:
-   - "mattermost/core-build-engineers"
+   - "okrbest/core-engineers"
    - "devinbinnie"
```

> ⚠️ `devinbinnie`는 원 프로젝트 메인테이너입니다. OKR Best 팀 멤버로 교체 필요.

---

## 단계 3: GitHub Actions 저작권 헤더

### actions/test/action.yaml, actions/patch-nightly-version/action.yaml

**현재:**
```yaml
# Copyright 2022 Mattermost, Inc.
```

**권장 (유지 + 추가):**
```yaml
# Copyright 2022 Mattermost, Inc.
# Copyright 2024-present OKR Best. All Rights Reserved.
# Modified for OKR Best project.
```

---

## 단계 4: 워크플로우 파일 수정 (1차 - 문구/URL)

### 4.1 nightly-builds.yaml

```diff
- git config --global user.email "nightly-build@mattermost.com"
+ git config --global user.email "nightly-build@okr.best"
```

### 4.2 e2e-functional.yml

```diff
- description: E2E tests for Mattermost desktop app on ${{ matrix.platform }} have started...
+ description: E2E tests for OKR Best desktop app on ${{ matrix.platform }} have started...
```

### 4.3 e2e-functional-template.yml

```diff
- PULL_REQUEST: "https://github.com/mattermost/desktop/pull/${{ github.event.number }}"
+ PULL_REQUEST: "https://github.com/okrbest/okrbest-desktop/pull/${{ github.event.number }}"
```

### 4.4 compatibility-matrix-testing.yml

```diff
- repository_full_name: mattermost/desktop
+ repository_full_name: okrbest/okrbest-desktop
```

---

## 단계 5: 워크플로우 파일 수정 (2차 - 인프라)

> ⚠️ **주의**: 이 단계는 OKR Best 인프라가 준비된 후 진행해야 합니다.

### 5.1 S3 버킷 URL 변경

| 파일 | 현재 | 변경 후 |
|------|------|---------|
| release.yaml | `s3://releases.mattermost.com/desktop/` | `s3://releases.okrbest.com/desktop/` |
| nightly-main.yml | `s3://releases.mattermost.com/desktop/` | `s3://releases.okrbest.com/desktop/` |
| nightly-main.yml | `s3.amazonaws.com/releases.mattermost.com/desktop/` | `s3.amazonaws.com/releases.okrbest.com/desktop/` |
| nightly-rainforest.yml | `s3://mattermost-desktop-daily-builds/` | OKR Best 버킷 |
| e2e-functional-template.yml | `mattermost-cypress-report` | OKR Best 버킷 |

### 5.2 Webhook/알림 설정

| 파일 | 항목 | 변경 내용 |
|------|------|----------|
| release.yaml | `MATTERMOST_USERNAME` | `OKRBestRelease` |
| release.yaml | `MATTERMOST_ICON_URL` | OKR Best 아이콘 URL |

### 5.3 외부 Actions 의존성

현재 Mattermost 조직의 액션을 사용 중:

```yaml
# 커밋 상태 업데이트
mattermost/actions/delivery/update-commit-status@main

# 릴리스 알림
mattermost/action-mattermost-notify@d317daebed2a792679f68fd0248557a8d21d82b6

# 보안 스캔
mattermost/actions-workflows/.github/workflows/snyk-sbom.yml@2174576d3c65eb4db691bf09fd72246b59f331c8
```

**대안:**
- 옵션 A: 해당 액션들을 `okrbest` 조직으로 포크
- 옵션 B: 범용 GitHub Actions로 대체
  - 커밋 상태: `actions/github-script`
  - 알림: Slack/Discord webhook 또는 자체 구현
  - 보안 스캔: GitHub 내장 Dependabot/CodeQL 활용

---

## 단계 6: GitHub 시크릿 설정

GitHub Repository Settings → Secrets and variables → Actions에서 설정:

| 시크릿 이름 | 설명 | 필요 작업 |
|------------|------|----------|
| `MM_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리스 알림 Webhook | OKR Best Webhook URL로 변경 |
| `MATTERMOST_BUILD_GH_TOKEN` | GitHub API 토큰 | OKR Best 토큰으로 변경 |
| `AWS_ACCESS_KEY_ID` | AWS S3 접근용 | OKR Best AWS 계정 |
| `AWS_SECRET_ACCESS_KEY` | AWS S3 접근용 | OKR Best AWS 계정 |
| `MM_DESKTOP_E2E_USER_CREDENTIALS` | E2E 테스트 인증 | OKR Best 테스트 계정 |

---

## 진행 순서 권장

```
1. 이슈/PR 템플릿 수정 (즉시 가능)
   ↓
2. Dependabot 설정 수정 (즉시 가능)
   ↓
3. GitHub Actions 저작권 헤더 (즉시 가능)
   ↓
4. 워크플로우 문구/URL 수정 (즉시 가능)
   ↓
5. 인프라 준비 (S3 버킷, Webhook 등)
   ↓
6. 워크플로우 인프라 설정 수정
   ↓
7. GitHub 시크릿 설정
   ↓
8. 테스트 및 검증
```

---

## 참고사항

- 단계 1~4는 즉시 진행 가능
- 단계 5~7은 OKR Best 인프라 준비 후 진행
- CI/CD 파이프라인이 중단되지 않도록 단계적으로 진행 권장
