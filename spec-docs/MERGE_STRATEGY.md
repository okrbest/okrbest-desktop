# OKRBEST 병합 전략 가이드

> 원본 오픈소스(Mattermost) 추적과 선형 히스토리 유지를 동시에 달성하는 Git 병합 전략

---

## 목차

1. [개요](#1-개요)
2. [브랜치 구조](#2-브랜치-구조)
3. [병합 전략](#3-병합-전략)
4. [Upstream 동기화](#4-upstream-동기화)
5. [Patch-ID 기반 추적](#5-patch-id-기반-추적)
6. [실용 워크플로우](#6-실용-워크플로우)
7. [GitHub/GitLab 설정](#7-githubgitlab-설정)
8. [GitHub CLI 활용](#8-github-cli-활용)
9. [문제 해결](#9-문제-해결)

---

## 1. 개요

### 1.1 요구사항

| 요구사항            | 설명                                                              |
| ------------------- | ----------------------------------------------------------------- |
| **PR 필수**         | master에 직접 병합 금지, 모든 변경은 Pull Request를 통해서만 병합 |
| **선형 히스토리**   | 머지 커밋 없이 개별 작업 커밋만 유지                              |
| **Upstream 추적**   | 원본 오픈소스(Mattermost) 변경 추적 가능                          |
| **깔끔한 히스토리** | 각 커밋이 논리적 단위로 구성                                      |

### 1.2 핵심 딜레마

```
┌─────────────────────────────────────────────────────────────┐
│                    병합 전략 딜레마                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  방법              │ 선형 히스토리 │ Upstream 추적           │
│  ─────────────────────────────────────────────────────────  │
│  Merge Commit      │     ✗        │      ✓ (해시 유지)      │
│  Rebase & Merge    │     ✓        │      ✗ (해시 변경)      │
│  Squash Merge      │     ✓        │      ✗ (커밋 손실)      │
│                                                             │
│  해결책: Rebase + Patch-ID 기반 추적                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 해결 전략 요약

- **기능 브랜치 → master**: Pull Request를 통한 Rebase and Merge (선형 유지)
- **upstream → master**: Pull Request를 통한 Cherry-pick -x (메타데이터 보존)
- **Upstream 추적**: Patch-ID 기반 비교 (`git cherry`)
- **핵심 원칙**: ❌ master에 직접 병합 금지, ✅ 항상 PR을 통해서만 병합

---

## 2. 브랜치 구조

### 2.1 브랜치 역할

```
┌─────────────────────────────────────────────────────────────┐
│                      브랜치 구조                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  upstream/master (Mattermost 원본, remote)                  │
│  ──●──●──●──●──●──●──►                                      │
│     A  B  C  D  E  F                                        │
│              │                                              │
│              │ git fetch upstream                           │
│              ▼                                              │
│  upstream-master (동기화 추적용, local)                      │
│  ──●──●──●──●─────────►                                     │
│     A  B  C  D   (원본 해시 그대로 유지)                     │
│              │                                              │
│              │ git cherry-pick -x                           │
│              ▼                                              │
│  master (OKRBEST 메인)                                     │
│  ──●──●──●──●'─●──●──►                                      │
│     X  Y  Z  D' a' b'  (선형 히스토리)                       │
│              ▲                                              │
│              │ rebase and merge                             │
│              │                                              │
│  feature/xxx (기능 개발)                                    │
│       └──●──●                                               │
│          a  b                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 브랜치 설명

| 브랜치            | 유형         | 용도                 | 관리 방식         |
| ----------------- | ------------ | -------------------- | ----------------- |
| `upstream/master` | Remote       | Mattermost 원본      | 읽기 전용         |
| `upstream-master` | Local        | Upstream 동기화 추적 | Fast-forward only |
| `master`          | Local/Remote | OKRBEST 메인 개발   | 선형 유지         |
| `feature/*`       | Local        | 기능 개발            | → master로 rebase |
| `hotfix/*`        | Local        | 긴급 수정            | → master로 rebase |

### 2.3 초기 설정

```bash
# 1. Upstream remote 추가
git remote add upstream https://github.com/mattermost/desktop.git

# 2. upstream-master 브랜치 생성 (현재 upstream 기준)
git fetch upstream
git checkout -b upstream-master upstream/master

# 3. 초기 동기화 지점 태그
git tag upstream-sync-init

# 4. master 브랜치로 돌아가기
git checkout master
```

---

## 3. 병합 전략

### 3.1 기능 브랜치 → master

**방식: Pull Request를 통한 병합 (필수)**

```bash
# 1. 기능 브랜치에서 작업
git checkout feature/new-feature
git fetch origin master
git rebase origin/master

# 2. 충돌 해결 후 푸시
git push origin feature/new-feature

# 3. GitHub에서 Pull Request 생성
# - Base: master
# - Compare: feature/new-feature
# - PR 제목과 설명 작성

# 4. 리뷰 후 GitHub에서 병합
# - "Rebase and merge" 버튼 사용 (권장)
# - 또는 "Squash and merge" (하나의 논리적 커밋으로)

# 5. 병합 후 브랜치 정리
git checkout master
git pull origin master
git branch -d feature/new-feature
git push origin --delete feature/new-feature
```

**중요 규칙:**

- ❌ **master에 직접 병합 금지**: 항상 PR을 통해서만 병합
- ✅ **PR 생성 필수**: 모든 변경사항은 PR을 통해 검토 후 병합
- ✅ **리뷰 승인 후 병합**: 최소 1명 이상의 승인 필요

### 3.2 병합 규칙

| 상황                     | 병합 방식        | 이유             |
| ------------------------ | ---------------- | ---------------- |
| 기능 브랜치 (커밋 1-2개) | Rebase and Merge | 커밋별 추적 용이 |
| 기능 브랜치 (커밋 다수)  | Squash and Merge | 깔끔한 히스토리  |
| Hotfix                   | Rebase and Merge | 빠른 반영        |
| Upstream 변경            | Cherry-pick -x   | 원본 추적        |

### 3.3 커밋 메시지 규칙

```
<type>: <subject>

<body>

<footer>
```

**타입:**

- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서
- `refactor`: 리팩토링
- `chore`: 빌드, 설정 변경
- `upstream`: Upstream에서 가져온 변경

---

## 4. Upstream 동기화

### 4.1 동기화 프로세스

```
┌─────────────────────────────────────────────────────────────┐
│                  Upstream 동기화 프로세스                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Upstream 최신화                                    │
│  ────────────────────────                                   │
│  $ git fetch upstream                                       │
│                                                             │
│  Step 2: upstream-master 업데이트                           │
│  ──────────────────────────────────                         │
│  $ git checkout upstream-master                             │
│  $ git merge --ff-only upstream/master                      │
│                                                             │
│  Step 3: 가져올 커밋 확인 (Patch-ID 기반)                   │
│  ────────────────────────────────────────                   │
│  $ git cherry -v master upstream-master                     │
│  # + 표시된 커밋만 가져와야 함                               │
│                                                             │
│  Step 4: Cherry-pick으로 반영                               │
│  ───────────────────────────────                            │
│  $ git checkout master                                      │
│  $ git cherry-pick -x <commit-hash>                         │
│                                                             │
│  Step 5: 동기화 완료 태그 (형식: upstream-sync/YYYYMMDD/해시8자리) │
│  ─────────────────────────────────────────────────────────  │
│  $ git tag upstream-sync/$(date +%Y%m%d)/$(git rev-parse --short=8 HEAD) │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Cherry-pick 옵션

```bash
# 단일 커밋 (원본 해시 기록)
git cherry-pick -x <commit-hash>

# 여러 커밋 (범위)
git cherry-pick -x <start-hash>^..<end-hash>

# 충돌 시 계속
git cherry-pick --continue

# 중단
git cherry-pick --abort
```

### 4.3 Cherry-pick -x 결과

```
commit 7a8b9c0d (HEAD -> master)
Author: Mattermost Dev <dev@mattermost.com>
Date:   Mon Jan 6 2025

    fix: 알림 중복 표시 버그 수정

    알림이 여러 번 표시되는 문제를 해결합니다.

    (cherry picked from commit abc123def456789)
    ↑ 이 정보로 원본 커밋 추적 가능
```

### 4.4 동기화 태그 규칙

동기화 완료 시점에 태그를 생성하여 이력을 추적합니다.

**태그 형식:** `upstream-sync/YYYYMMDD/해시8자리`

| 구성 | 설명 | 예시 |
| ---- | ---- | ---- |
| `upstream-sync/` | 접두사 | 고정 |
| `YYYYMMDD` | 동기화 날짜 | 20240304 |
| `해시8자리` | 현재 HEAD 커밋 8자리 해시 | a1b2c3d4 |

**예시:** `upstream-sync/20240304/a1b2c3d4`

`scripts/sync-upstream.sh` 실행 시 cherry-pick 완료 후 자동으로 태그 생성 여부를 묻습니다.

### 4.5 동기화 주기

| 유형            | 주기      | 대상                |
| --------------- | --------- | ------------------- |
| **정기 동기화** | 월 1회    | 모든 변경 검토      |
| **보안 패치**   | 즉시      | 보안 관련 커밋만    |
| **주요 버전**   | 릴리스 시 | 특정 버전 태그 기준 |

---

## 5. Patch-ID 기반 추적

### 5.1 Patch-ID란?

Git은 각 커밋의 변경 내용(diff)에 대해 고유한 Patch-ID를 계산합니다. **커밋 해시가 달라도 동일한 변경이면 같은 Patch-ID를 가집니다.**

```
┌─────────────────────────────────────────────────────────────┐
│                    Patch-ID 비교 원리                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Commit A (upstream-master)                                 │
│  ┌────────────────────────────┐                            │
│  │ Hash: abc123               │                            │
│  │ Author: upstream-dev       │                            │
│  │ Date: 2024-01-01           │                            │
│  │                            │                            │
│  │ Diff:                      │ ──► Patch-ID: xyz789       │
│  │   - old code               │     (diff 내용만 해시)      │
│  │   + new code               │                            │
│  └────────────────────────────┘                            │
│                                                             │
│  Commit A' (master, cherry-picked)                         │
│  ┌────────────────────────────┐                            │
│  │ Hash: def456 (다름!)       │                            │
│  │ Author: upstream-dev       │                            │
│  │ Date: 2024-01-05 (다름!)   │                            │
│  │                            │                            │
│  │ Diff:                      │ ──► Patch-ID: xyz789       │
│  │   - old code               │     (동일!)                 │
│  │   + new code               │                            │
│  └────────────────────────────┘                            │
│                                                             │
│  결과: git cherry는 이 두 커밋을 "동일"하다고 판단           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 추적 명령어

#### `git cherry` - 가져올 커밋 확인

```bash
git cherry -v master upstream-master
```

**출력:**

```
- abc123 fix: 이미 master에 있음 (스킵)
- def456 feat: 이미 master에 있음 (스킵)
+ 789abc feat: 새로 가져와야 함
+ 012def fix: 새로 가져와야 함
```

| 기호 | 의미                                     |
| ---- | ---------------------------------------- |
| `-`  | master에 **이미 반영됨** (Patch-ID 일치) |
| `+`  | master에 **없음** (가져와야 함)          |

#### `git log --cherry-pick` - 중복 제외 로그

```bash
# 가져와야 할 커밋만 표시
git log --cherry-pick --oneline upstream-master ^master
```

#### `git log --cherry-mark` - 상태 표시 로그

```bash
# 모든 커밋을 보되, 동일 여부 표시
git log --cherry-mark --oneline upstream-master ^master
```

**출력:**

```
= abc123 fix: 이미 있음 (Patch-ID 일치)
= def456 feat: 이미 있음 (Patch-ID 일치)
+ 789abc feat: 새 커밋
+ 012def fix: 새 커밋
```

### 5.3 Patch-ID 한계

| 상황                | Patch-ID 결과 | 해결 방법               |
| ------------------- | ------------- | ----------------------- |
| 동일한 변경         | 일치 ✓        | 자동 인식               |
| 충돌 해결 시 수정   | 불일치 ✗      | 커밋 메시지에 원본 명시 |
| 컨텍스트 변경       | 불일치 ✗      | 수동 추적               |
| 백포트 시 코드 조정 | 불일치 ✗      | 커밋 메시지에 원본 명시 |

---

## 6. 실용 워크플로우

### 6.1 동기화 스크립트

```bash
#!/bin/bash
# scripts/sync-upstream.sh

set -e

echo "=== OKRBEST Upstream 동기화 ==="
echo ""

# 1. Upstream 최신화
echo "📥 Upstream 가져오는 중..."
git fetch upstream

# 2. upstream-master 업데이트
echo "🔄 upstream-master 업데이트 중..."
git checkout upstream-master
git merge --ff-only upstream/master

# 3. 가져와야 할 커밋 확인
echo ""
echo "📋 master에 반영해야 할 커밋들:"
echo "────────────────────────────────"
git cherry -v master upstream-master | grep "^+" || echo "(없음)"

# 4. 개수 표시
NEW_COMMITS=$(git cherry master upstream-master | grep -c "^+" || echo "0")
echo ""
echo "────────────────────────────────"
echo "총 ${NEW_COMMITS}개의 새 커밋이 있습니다."

# 5. master로 돌아가기
git checkout master

if [ "$NEW_COMMITS" -gt 0 ]; then
    echo ""
    echo "💡 cherry-pick 명령어:"
    echo "   git cherry-pick -x <commit-hash>"
    echo ""
    echo "💡 전체 반영 (주의해서 사용):"
    echo "   git cherry master upstream-master | grep '^+' | cut -d' ' -f2 | xargs git cherry-pick -x"
fi
```

### 6.2 일반적인 작업 흐름

#### 기능 개발

```bash
# 1. 기능 브랜치 생성
git checkout master
git pull origin master
git checkout -b feature/new-okr-widget

# 2. 개발 및 커밋
git add .
git commit -m "feat: OKR 위젯 추가"

# 3. master 최신화 및 rebase
git fetch origin master
git rebase origin/master

# 4. 푸시 및 PR 생성
git push origin feature/new-okr-widget

# 5. GitHub에서 Pull Request 생성
# - Base: master
# - Compare: feature/new-okr-widget
# - PR 제목과 설명 작성
# - 리뷰어 지정

# 6. 리뷰 후 GitHub에서 병합
# - "Rebase and merge" 버튼 사용 (권장)

# 7. 병합 후 브랜치 정리
git checkout master
git pull origin master
git branch -d feature/new-okr-widget
git push origin --delete feature/new-okr-widget
```

#### Upstream 동기화

```bash
# 1. 동기화 브랜치 생성
git checkout master
git pull origin master
git checkout -b sync/upstream-$(date +%Y%m%d)

# 2. 동기화 확인
./scripts/sync-upstream.sh

# 3. 필요한 커밋 cherry-pick
git cherry-pick -x abc123
git cherry-pick -x def456

# 4. 동기화 완료 태그 (형식: upstream-sync/YYYYMMDD/해시8자리)
git tag upstream-sync/$(date +%Y%m%d)/$(git rev-parse --short=8 HEAD)

# 5. 푸시 및 PR 생성
git push origin sync/upstream-$(date +%Y%m%d) --tags

# 6. GitHub에서 Pull Request 생성
# - Base: master
# - Compare: sync/upstream-YYYYMMDD
# - PR 제목: "Upstream 동기화: YYYY-MM-DD"
# - 설명에 cherry-pick한 커밋 목록 포함

# 7. 리뷰 후 GitHub에서 병합
# - "Rebase and merge" 버튼 사용 (권장)

# 8. 병합 후 브랜치 정리
git checkout master
git pull origin master
git branch -d sync/upstream-$(date +%Y%m%d)
git push origin --delete sync/upstream-$(date +%Y%m%d)
```

### 6.3 충돌 해결

```bash
# Cherry-pick 중 충돌 발생
git cherry-pick -x abc123

# 충돌 파일 확인
git status

# 충돌 해결 후
git add <resolved-files>
git cherry-pick --continue

# 커밋 메시지 수정 (충돌 해결 내용 명시)
# ---
# fix: 버그 수정
#
# Backported from upstream with conflict resolution.
# Original commit: abc123def456
# Conflicts resolved in: src/main/app.ts
#
# (cherry picked from commit abc123def456)
# ---
```

---

## 7. GitHub/GitLab 설정

### 7.1 Branch Protection Rules (GitHub)

```yaml
# master 브랜치 보호 규칙
master:
  # 필수 설정
  - Require pull request reviews before merging: true # PR 필수!
  - Required number of approvals: 1 # 최소 1명 승인 필요
  - Require status checks to pass: true
  - Require linear history: true # 핵심!
  - Require branches to be up to date before merging: true

  # 병합 방식
  - Allow merge commits: false # 비활성화!
  - Allow squash merging: false # 비활성화!
  - Allow rebase merging: true # 권장

  # 직접 푸시 방지
  - Restrict pushes that create files: true
  - Block force pushes: true
  - Block deletions: true
```

### 7.2 Merge Request Settings (GitLab)

```yaml
# 프로젝트 설정 > Merge Requests
merge_method: "ff" # Fast-forward merge
squash_option: "default_on" # 기본적으로 squash
```

### 7.3 PR 템플릿

```markdown
## 변경 사항

<!-- 변경 내용을 설명해주세요 -->

## 변경 유형

- [ ] 새 기능 (feat)
- [ ] 버그 수정 (fix)
- [ ] 문서 (docs)
- [ ] 리팩토링 (refactor)
- [ ] Upstream 동기화 (upstream)

## Upstream 관련 (해당 시)

- [ ] 이 PR은 upstream 변경을 포함합니다
- 원본 커밋: <!-- abc123 -->
- Upstream 버전: <!-- v6.2.0 -->

## 체크리스트

- [ ] 코드 스타일 준수
- [ ] 테스트 통과
- [ ] 문서 업데이트 (필요시)
```

---

## 8. GitHub CLI 활용

GitHub CLI (gh)를 사용하면 터미널에서 직접 Pull Request를 생성하고 관리할 수 있습니다.

### 8.1 GitHub CLI 설치

#### Linux (Ubuntu/Debian)

```bash
# GitHub 공식 저장소 추가

type -p curl >/dev/null || sudo apt install curl -y

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |

sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 설치
sudo apt update
sudo apt install gh -y
```

#### macOS

```bash
# Homebrew 사용
brew install gh
```

#### Windows

```powershell
# winget 사용
winget install --id GitHub.cli

# 또는 scoop 사용
scoop install gh
```

### 8.2 GitHub CLI 인증 설정

```bash
# 인증 시작
gh auth login

# 대화형 프롬프트 선택:
# 1. GitHub.com 또는 GitHub Enterprise Server 선택
# 2. 인증 방식 선택: HTTPS (권장) 또는 SSH
# 3. 웹 브라우저로 인증 또는 토큰 입력
```

**인증 확인:**

```bash
# 인증 상태 확인
gh auth status

# 출력 예시:
# github.com
#   ✓ Logged in to github.com as username
#   ✓ Git operations for github.com configured to use https protocol.
#   ✓ Token: gho_************************************
```

**추가 설정:**

```bash
# 기본 에디터 설정
gh config set editor "code --wait"  # VS Code
gh config set editor "vim"          # Vim

# 기본 브라우저 설정
gh config set browser "firefox"

# 기본 프로토콜 설정
gh config set git_protocol https    # HTTPS (권장)
gh config set git_protocol ssh      # SSH
```

### 8.3 푸시와 PR 생성 (기본)

#### 단계별 명령어

```bash
# 1. 변경사항 스테이징 및 커밋
git add .
git commit -m "feat: OKR 목표 달성률 위젯 추가"

# 2. 기능 브랜치 푸시 (첫 푸시 시 upstream 설정)
git push -u origin feature/okr-widget

# 3. Pull Request 생성
gh pr create --base master --head feature/okr-widget
```

#### 대화형 PR 생성

```bash
gh pr create
```

**대화형 프롬프트:**

```
? Where should we push the 'feature/okr-widget' branch? origin

Creating pull request for feature/okr-widget into master in okrbest/okrbest-desktop

? Title feat: OKR 목표 달성률 위젯 추가
? Body <커밋 메시지 본문 또는 직접 입력>
? What's next? Submit
```

### 8.4 커밋 메시지를 PR 내용으로 자동 사용

#### 방법 1: `--fill` 옵션 (가장 간편)

```bash
# 마지막 커밋 메시지를 PR 제목/본문으로 사용
gh pr create --fill

# 예시:
# 커밋 메시지가 "feat: OKR 위젯 추가\n\n상세 설명..." 인 경우
# - PR 제목: feat: OKR 위젯 추가
# - PR 본문: 상세 설명...
```

#### 방법 2: `--fill-verbose` 옵션 (여러 커밋)

```bash
# 브랜치의 모든 커밋 메시지를 PR 본문에 포함
gh pr create --fill-verbose

# 결과:
# - PR 제목: 첫 번째 커밋의 제목
# - PR 본문: 모든 커밋 메시지 목록
```

#### 방법 3: 커밋 메시지 직접 추출

```bash
# 마지막 커밋 메시지의 제목 추출
COMMIT_TITLE=$(git log -1 --pretty=%s)

# 마지막 커밋 메시지의 본문 추출
COMMIT_BODY=$(git log -1 --pretty=%b)

# PR 생성
gh pr create \
  --title "$COMMIT_TITLE" \
  --body "$COMMIT_BODY" \
  --base master
```

### 8.5 완전 자동화 스크립트

#### 푸시 + PR 원스텝 스크립트

```bash
#!/bin/bash
# scripts/push-and-pr.sh
# 사용법: ./scripts/push-and-pr.sh [base-branch]

set -e

BASE_BRANCH=${1:-master}
CURRENT_BRANCH=$(git branch --show-current)

# 현재 브랜치 확인
if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "❌ 오류: $BASE_BRANCH 브랜치에서는 실행할 수 없습니다."
    echo "   기능 브랜치로 이동 후 실행하세요."
    exit 1
fi

# 커밋되지 않은 변경 확인
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ 오류: 커밋되지 않은 변경사항이 있습니다."
    echo "   먼저 변경사항을 커밋하세요."
    exit 1
fi

echo "=== Push & PR 자동화 ==="
echo ""
echo "📌 현재 브랜치: $CURRENT_BRANCH"
echo "📌 대상 브랜치: $BASE_BRANCH"
echo ""

# 1. 최신 base 브랜치로 리베이스
echo "🔄 $BASE_BRANCH 브랜치 최신화 중..."
git fetch origin $BASE_BRANCH
git rebase origin/$BASE_BRANCH

# 2. 푸시 (force-with-lease로 안전하게)
echo "📤 브랜치 푸시 중..."
git push -u origin $CURRENT_BRANCH --force-with-lease

# 3. 기존 PR 확인
EXISTING_PR=$(gh pr list --head $CURRENT_BRANCH --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ]; then
    echo ""
    echo "✅ 기존 PR #$EXISTING_PR이 업데이트되었습니다."
    echo "🔗 $(gh pr view $EXISTING_PR --json url --jq '.url')"
else
    # 4. 새 PR 생성 (커밋 메시지로 자동 채우기)
    echo ""
    echo "📝 Pull Request 생성 중..."
    gh pr create --fill --base $BASE_BRANCH
fi

echo ""
echo "✅ 완료!"
```

**사용 방법:**

```bash
# 실행 권한 부여
chmod +x scripts/push-and-pr.sh

# 사용
./scripts/push-and-pr.sh         # master로 PR
./scripts/push-and-pr.sh develop # develop으로 PR
```

#### 커밋 + 푸시 + PR 올인원 스크립트

```bash
#!/bin/bash
# scripts/commit-push-pr.sh
# 사용법: ./scripts/commit-push-pr.sh "커밋 메시지"

set -e

if [ -z "$1" ]; then
    echo "❌ 사용법: $0 \"커밋 메시지\""
    exit 1
fi

COMMIT_MSG="$1"
BASE_BRANCH=${2:-master}
CURRENT_BRANCH=$(git branch --show-current)

# 현재 브랜치 확인
if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "❌ 오류: $BASE_BRANCH 브랜치에서는 실행할 수 없습니다."
    exit 1
fi

echo "=== Commit + Push + PR 자동화 ==="
echo ""

# 1. 스테이징된 파일 확인
if [ -z "$(git diff --cached --name-only)" ]; then
    # 스테이징된 파일이 없으면 모든 변경사항 스테이징
    echo "📁 모든 변경사항 스테이징..."
    git add -A
fi

# 2. 커밋
echo "💾 커밋 중..."
git commit -m "$COMMIT_MSG"

# 3. Push & PR
./scripts/push-and-pr.sh $BASE_BRANCH
```

### 8.6 유용한 gh pr 명령어

#### PR 생성 옵션

```bash
# 기본 PR 생성
gh pr create --fill

# Draft PR 생성
gh pr create --fill --draft

# 특정 리뷰어 지정
gh pr create --fill --reviewer "user1,user2"

# 라벨 추가
gh pr create --fill --label "enhancement,okr"

# 마일스톤 지정
gh pr create --fill --milestone "v1.0.0"

# Assignee 지정
gh pr create --fill --assignee "@me"

# 모든 옵션 조합
gh pr create \
  --fill \
  --draft \
  --reviewer "tech-lead" \
  --label "feat,okr" \
  --assignee "@me"
```

#### PR 관리

```bash
# 내 PR 목록 보기
gh pr list --author "@me"

# PR 상태 확인
gh pr status

# PR 상세 정보
gh pr view 123

# PR 웹에서 열기
gh pr view 123 --web

# PR 체크아웃 (로컬에서 테스트)
gh pr checkout 123

# PR 병합
gh pr merge 123 --rebase  # Rebase and merge (권장)
gh pr merge 123 --squash  # Squash and merge
gh pr merge 123 --merge   # Merge commit (비권장)

# PR 병합 후 브랜치 삭제
gh pr merge 123 --rebase --delete-branch
```

#### PR 리뷰

```bash
# PR 리뷰 승인
gh pr review 123 --approve

# PR 리뷰 코멘트
gh pr review 123 --comment --body "LGTM!"

# PR 변경 요청
gh pr review 123 --request-changes --body "수정 필요한 부분이 있습니다."

# PR 코멘트 추가
gh pr comment 123 --body "테스트 완료했습니다."
```

### 8.7 워크플로우 예시

#### 기능 개발 전체 흐름

```bash
# 1. 기능 브랜치 생성
git checkout master
git pull origin master
git checkout -b feature/okr-dashboard

# 2. 개발 작업
# ... 코딩 ...

# 3. 커밋
git add .
git commit -m "feat: OKR 대시보드 추가

- 목표 진행률 차트 구현
- 핵심 결과 목록 표시
- 실시간 업데이트 지원"

# 4. 푸시 + PR 생성 (커밋 메시지로 자동 채움)
git push -u origin feature/okr-dashboard
gh pr create --fill

# 또는 한 줄로
git push -u origin feature/okr-dashboard && gh pr create --fill
```

#### Upstream 동기화 PR 생성

```bash
# 1. 동기화 브랜치 생성 및 cherry-pick
git checkout master && git pull
git checkout -b sync/upstream-20260114
git cherry-pick -x abc123 def456

# 2. 푸시 및 PR 생성 (상세 커밋 목록 포함)
git push -u origin sync/upstream-20260114
gh pr create \
  --title "upstream: Mattermost 최신 변경사항 동기화" \
  --body "$(cat << EOF
## Upstream 동기화

### 반영된 커밋
$(git log --oneline master..HEAD)

### 원본 커밋
$(git log --oneline --grep="cherry picked from" master..HEAD | sed 's/.*cherry picked from commit /- /')
EOF
)" \
  --label "upstream"
```

### 8.8 별칭(Alias) 설정

**Git 별칭:**

```bash
# ~/.gitconfig에 추가
git config --global alias.pushpr '!git push -u origin HEAD && gh pr create --fill'
git config --global alias.draftpr '!git push -u origin HEAD && gh pr create --fill --draft'
```

**Shell 별칭:**

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
alias gpr='git push -u origin HEAD && gh pr create --fill'
alias gprd='git push -u origin HEAD && gh pr create --fill --draft'
alias gprv='git push -u origin HEAD && gh pr create --fill-verbose'

# 사용
gpr   # 푸시 + PR 생성
gprd  # 푸시 + Draft PR 생성
gprv  # 푸시 + 상세 PR 생성
```

**gh 별칭:**

```bash
# gh 자체 별칭 설정
gh alias set prc 'pr create --fill'
gh alias set prcd 'pr create --fill --draft'
gh alias set prm 'pr merge --rebase --delete-branch'

# 사용
gh prc   # PR 생성
gh prcd  # Draft PR 생성
gh prm   # PR 병합 + 브랜치 삭제
```

---

## 9. 문제 해결

### 9.1 자주 발생하는 문제

#### Q: Cherry-pick 후에도 `git cherry`에서 + 표시됨

**원인**: 충돌 해결 시 코드가 변경되어 Patch-ID가 달라짐

**해결**:

```bash
# 커밋 메시지로 추적
git log --grep="cherry picked from commit abc123"

# 또는 수동으로 기록 유지
# docs/UPSTREAM_SYNC.md 파일에 기록
```

#### Q: Rebase 중 충돌이 너무 많음

**해결**:

```bash
# 작은 단위로 rebase
git rebase -i origin/master

# 또는 충돌이 많으면 merge 고려 (예외적, 개인 브랜치에서만)
# 주의: 이 merge는 개인 브랜치 내부에서만 사용하며,
#       최종적으로는 PR을 통해 병합해야 함
git merge origin/master
```

#### Q: 잘못된 커밋을 cherry-pick 했음

**해결**:

```bash
# 아직 push 전이라면
git reset --hard HEAD~1

# 이미 push 했다면
git revert <commit-hash>
```

#### Q: gh 명령어가 인증 오류 발생

**원인**: 토큰 만료 또는 권한 부족

**해결**:

```bash
# 인증 상태 확인
gh auth status

# 재인증
gh auth logout
gh auth login

# 특정 스코프 추가 (필요시)
gh auth refresh -s repo,read:org
```

#### Q: gh pr create 실행 시 "no commits between" 오류

**원인**: 기능 브랜치와 base 브랜치 사이에 차이가 없음

**해결**:

```bash
# 브랜치 상태 확인
git log --oneline master..HEAD

# base 브랜치 최신화 후 다시 확인
git fetch origin master
git rebase origin/master
```

### 9.2 유용한 명령어 모음

```bash
# Upstream에서 가져온 커밋 찾기
git log --grep="cherry picked from commit"

# 특정 파일의 upstream 변경 확인
git log --cherry-pick --oneline upstream-master ^master -- path/to/file

# 동기화 상태 요약
git rev-list --count master..upstream-master  # upstream이 앞선 커밋 수
git rev-list --count upstream-master..master  # master가 앞선 커밋 수

# Patch-ID 직접 확인
git show <commit> | git patch-id
```

### 9.3 동기화 기록 관리

동기화 이력을 문서로 관리하는 것을 권장합니다:

```markdown
# UPSTREAM_SYNC.md

## 동기화 이력

### 2024-01-15: v6.2.0 동기화

- 태그: upstream-sync/20240115/def45678
- 반영 커밋:
  - abc123 → def456 (fix: 알림 버그)
  - 789abc → 012def (feat: 새 기능)
- 충돌 해결: src/main/app.ts

### 2024-01-01: v6.1.0 동기화

- 태그: upstream-sync/20240101/abc12345
- ...
```

---

## 부록: 명령어 요약

### 일상 작업

```bash
# 기능 브랜치 시작
git checkout -b feature/xxx

# 작업 완료 후 PR 생성
git rebase origin/master
git push origin feature/xxx

# GitHub에서 Pull Request 생성 후 리뷰 및 병합
# ❌ 직접 병합 금지: 항상 PR을 통해서만 병합
```

### Upstream 동기화

```bash
# 1. 동기화 브랜치 생성
git checkout master
git pull origin master
git checkout -b sync/upstream-YYYYMMDD

# 2. 새 커밋 확인
git fetch upstream
git cherry -v master upstream-master | grep "^+"

# 3. 선택적 반영
git cherry-pick -x <hash>

# 4. 푸시 및 PR 생성
git push origin sync/upstream-YYYYMMDD

# 5. GitHub에서 Pull Request 생성 후 리뷰 및 병합
# ❌ 직접 병합 금지: 항상 PR을 통해서만 병합
```

### 추적 및 확인

```bash
# 가져올 커밋 목록
git cherry -v master upstream-master

# Upstream에서 온 커밋 찾기
git log --grep="cherry picked from"

# 동기화 상태
git log --oneline --graph master upstream-master
```

---

_문서 작성일: 2026-01-14_
