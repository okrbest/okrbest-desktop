# OKR Best 병합 전략 가이드

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
8. [문제 해결](#8-문제-해결)

---

## 1. 개요

### 1.1 요구사항

| 요구사항 | 설명 |
|----------|------|
| **선형 히스토리** | 머지 커밋 없이 개별 작업 커밋만 유지 |
| **Upstream 추적** | 원본 오픈소스(Mattermost) 변경 추적 가능 |
| **깔끔한 히스토리** | 각 커밋이 논리적 단위로 구성 |

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

- **기능 브랜치 → master**: Rebase and Merge (선형 유지)
- **upstream → master**: Cherry-pick -x (메타데이터 보존)
- **Upstream 추적**: Patch-ID 기반 비교 (`git cherry`)

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
│  master (OKR Best 메인)                                     │
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

| 브랜치 | 유형 | 용도 | 관리 방식 |
|--------|------|------|-----------|
| `upstream/master` | Remote | Mattermost 원본 | 읽기 전용 |
| `upstream-master` | Local | Upstream 동기화 추적 | Fast-forward only |
| `master` | Local/Remote | OKR Best 메인 개발 | 선형 유지 |
| `feature/*` | Local | 기능 개발 | → master로 rebase |
| `hotfix/*` | Local | 긴급 수정 | → master로 rebase |

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

**방식: Rebase and Merge**

```bash
# 로컬에서 수행
git checkout feature/new-feature
git fetch origin master
git rebase origin/master

# 충돌 해결 후
git checkout master
git merge --ff-only feature/new-feature
git push origin master

# 브랜치 정리
git branch -d feature/new-feature
```

**GitHub PR 설정:**
- "Rebase and merge" 버튼 사용
- 또는 "Squash and merge" (하나의 논리적 커밋으로)

### 3.2 병합 규칙

| 상황 | 병합 방식 | 이유 |
|------|-----------|------|
| 기능 브랜치 (커밋 1-2개) | Rebase and Merge | 커밋별 추적 용이 |
| 기능 브랜치 (커밋 다수) | Squash and Merge | 깔끔한 히스토리 |
| Hotfix | Rebase and Merge | 빠른 반영 |
| Upstream 변경 | Cherry-pick -x | 원본 추적 |

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
│  $ git tag upstream-sync-v6.2.0  # 버전 태그               │
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
│  Step 5: 동기화 완료 태그                                   │
│  ─────────────────────────                                  │
│  $ git tag okrbest-sync-v6.2.0                             │
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

### 4.4 동기화 주기

| 유형 | 주기 | 대상 |
|------|------|------|
| **정기 동기화** | 월 1회 | 모든 변경 검토 |
| **보안 패치** | 즉시 | 보안 관련 커밋만 |
| **주요 버전** | 릴리스 시 | 특정 버전 태그 기준 |

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

| 기호 | 의미 |
|------|------|
| `-` | master에 **이미 반영됨** (Patch-ID 일치) |
| `+` | master에 **없음** (가져와야 함) |

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

| 상황 | Patch-ID 결과 | 해결 방법 |
|------|---------------|-----------|
| 동일한 변경 | 일치 ✓ | 자동 인식 |
| 충돌 해결 시 수정 | 불일치 ✗ | 커밋 메시지에 원본 명시 |
| 컨텍스트 변경 | 불일치 ✗ | 수동 추적 |
| 백포트 시 코드 조정 | 불일치 ✗ | 커밋 메시지에 원본 명시 |

---

## 6. 실용 워크플로우

### 6.1 동기화 스크립트

```bash
#!/bin/bash
# scripts/sync-upstream.sh

set -e

echo "=== OKR Best Upstream 동기화 ==="
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

# 4. PR 생성 또는 직접 병합
git checkout master
git merge --ff-only feature/new-okr-widget
git push origin master

# 5. 브랜치 정리
git branch -d feature/new-okr-widget
```

#### Upstream 동기화

```bash
# 1. 동기화 확인
./scripts/sync-upstream.sh

# 2. 필요한 커밋 cherry-pick
git cherry-pick -x abc123
git cherry-pick -x def456

# 3. 동기화 완료 태그
git tag okrbest-sync-$(date +%Y%m%d)

# 4. 푸시
git push origin master --tags
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
  - Require pull request reviews before merging: true
  - Require status checks to pass: true
  - Require linear history: true  # 핵심!
  
  # 병합 방식
  - Allow merge commits: false    # 비활성화!
  - Allow squash merging: true
  - Allow rebase merging: true    # 권장
```

### 7.2 Merge Request Settings (GitLab)

```yaml
# 프로젝트 설정 > Merge Requests
merge_method: "ff"  # Fast-forward merge
squash_option: "default_on"  # 기본적으로 squash
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

## 8. 문제 해결

### 8.1 자주 발생하는 문제

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

# 또는 충돌이 많으면 merge 고려 (예외적)
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

### 8.2 유용한 명령어 모음

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

### 8.3 동기화 기록 관리

동기화 이력을 문서로 관리하는 것을 권장합니다:

```markdown
# UPSTREAM_SYNC.md

## 동기화 이력

### 2024-01-15: v6.2.0 동기화
- 태그: okrbest-sync-20240115
- 원본: upstream-sync-v6.2.0
- 반영 커밋:
  - abc123 → def456 (fix: 알림 버그)
  - 789abc → 012def (feat: 새 기능)
- 충돌 해결: src/main/app.ts

### 2024-01-01: v6.1.0 동기화
- 태그: okrbest-sync-20240101
- ...
```

---

## 부록: 명령어 요약

### 일상 작업

```bash
# 기능 브랜치 시작
git checkout -b feature/xxx

# 작업 완료 후 master에 병합
git rebase origin/master
git checkout master
git merge --ff-only feature/xxx
```

### Upstream 동기화

```bash
# 새 커밋 확인
git fetch upstream
git cherry -v master upstream-master | grep "^+"

# 선택적 반영
git cherry-pick -x <hash>
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

*문서 작성일: 2026-01-04*
