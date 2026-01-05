# OKR Best Desktop Git 병합 전략 가이드

> 팀원들이 안전하고 일관되게 사용할 수 있는 Git 브랜치 병합 전략입니다.

---

## 목차

1. [기본 원칙](#1-기본-원칙)
2. [일반적인 워크플로우](#2-일반적인-워크플로우)
3. [상황별 가이드](#3-상황별-가이드)
4. [충돌 해결](#4-충돌-해결)
5. [주의사항 및 모범 사례](#5-주의사항-및-모범-사례)
6. [자주 묻는 질문](#6-자주-묻는-질문)

---

## 1. 기본 원칙

### 1.1 팀 전략: 안전성 우선

**핵심 원칙**:
- ✅ **안전성**: 작업 손실 방지
- ✅ **일관성**: 모든 팀원이 동일한 방식 사용
- ✅ **추적 가능성**: 언제 무엇이 병합되었는지 명확

### 1.2 권장 병합 전략

| 상황 | 전략 | 이유 |
|------|------|------|
| **개인 브랜치에 master 반영** | **Merge** | 가장 안전, 히스토리 보존 |
| **PR 병합 (GitHub)** | **Rebase and Merge** | 깔끔한 히스토리 (GitHub 자동 처리) |
| **공유 브랜치** | **Merge만 사용** | Rebase 절대 금지 |

### 1.3 절대 하지 말아야 할 것

- ❌ **공유 브랜치에서 Rebase 사용 금지**
- ❌ **Force push를 남용하지 않기**
- ❌ **master 브랜치에 직접 푸시 금지**

---

## 2. 일반적인 워크플로우

### 2.1 새 기능 개발 시작

```bash
# 1. master 브랜치 최신 상태로 업데이트
git checkout master
git fetch upstream
git merge upstream/master
git push origin master

# 2. 새 브랜치 생성
git checkout -b feature/my-feature-name

# 3. 작업 시작
# ... 코드 작성 ...
```

**브랜치 네이밍 규칙**:
- `feature/기능명`
- `fix/버그명`
- `docs/문서명`
- 예: `feature/okrbest-rebrand`, `fix/login-bug`

### 2.2 작업 중 master 변경사항 반영 (권장 방법)

**상황**: master에 다른 PR이 머지되어 최신 코드를 반영해야 함

```bash
# 1. 최신 변경사항 가져오기
git fetch upstream

# 2. 개인 브랜치로 전환 (이미 있는 경우)
git checkout feature/my-feature-name

# 3. master를 개인 브랜치에 병합 (Merge 사용)
git merge upstream/master

# 4. 충돌 없으면 자동 완료
# 충돌 있으면 해결 (아래 "충돌 해결" 섹션 참조)

# 5. 테스트 후 푸시
npm test  # 또는 프로젝트의 테스트 명령어
git push origin feature/my-feature-name
```

**결과**:
- 병합 커밋 생성: `"Merge branch 'master' into feature/my-feature-name"`
- 이 커밋은 PR에 포함되지만, GitHub에서 "Rebase and Merge"로 병합하면 최종적으로 깔끔해짐

### 2.3 작업 완료 후 PR 생성

```bash
# 1. 최종 확인
git status
git log --oneline -10

# 2. 푸시
git push origin feature/my-feature-name

# 3. GitHub에서 Pull Request 생성
# - Base: master
# - Compare: feature/my-feature-name
```

### 2.4 PR 병합 (GitHub에서)

**권장 방법**: **"Rebase and Merge"** 선택

- ✅ 깔끔한 선형 히스토리
- ✅ PR 번호가 커밋 메시지에 포함
- ✅ GitHub가 자동으로 처리

**다른 옵션**:
- "Create a merge commit": 병합 커밋 생성 (히스토리 복잡해짐)
- "Squash and merge": 모든 커밋을 하나로 합침 (개별 커밋 히스토리 손실)

---

## 3. 상황별 가이드

### 3.1 상황 A: 작업 시작 전 master 업데이트

```bash
# master 브랜치로 전환
git checkout master

# upstream 최신 상태 가져오기
git fetch upstream

# upstream/master를 로컬 master에 병합
git merge upstream/master

# origin에 푸시
git push origin master

# 이제 새 브랜치 생성
git checkout -b feature/new-feature
```

### 3.2 상황 B: 작업 중 master 변경사항 반영

**권장 방법: Merge 사용**

```bash
# 개인 브랜치에서
git fetch upstream
git merge upstream/master

# 충돌 해결 후
git push origin feature/my-feature
```

**대안: Rebase 사용 (고급, 주의 필요)**

```bash
# 개인 브랜치에서
git fetch upstream
git rebase upstream/master

# 충돌 해결 (각 커밋마다 발생 가능)
git add .
git rebase --continue

# Force push (주의!)
git push origin feature/my-feature --force-with-lease
```

**언제 Rebase를 사용하나요?**
- ✅ 개인 브랜치일 때만
- ✅ 다른 사람이 사용하지 않는 브랜치일 때만
- ✅ 선형 히스토리를 원할 때

**언제 Rebase를 사용하지 않나요?**
- ❌ 다른 사람과 공유하는 브랜치
- ❌ 이미 PR이 생성된 브랜치 (팀과 협의 후)
- ❌ 불확실할 때는 Merge 사용

### 3.3 상황 C: 여러 개인 브랜치 관리

```bash
# 브랜치 A에서 작업 중
git checkout feature/branch-a
# ... 작업 ...

# 브랜치 B로 전환하여 작업
git checkout feature/branch-b
# ... 작업 ...

# 브랜치 A에 master 반영
git checkout feature/branch-a
git fetch upstream
git merge upstream/master

# 브랜치 B에 master 반영
git checkout feature/branch-b
git fetch upstream
git merge upstream/master
```

### 3.4 상황 D: PR 전 브랜치 정리 (선택사항)

**병합 커밋을 제거하고 싶을 때**:

```bash
# PR 전에 rebase로 정리
git fetch upstream
git rebase upstream/master

# Force push (주의!)
git push origin feature/my-feature --force-with-lease
```

**주의**: 이미 PR이 생성되어 있고 다른 사람이 리뷰 중이면 팀과 협의 필요

---

## 4. 충돌 해결

### 4.1 충돌 발생 시

```bash
# Merge 또는 Rebase 중 충돌 발생
# Git이 자동으로 충돌 파일 표시

# 1. 충돌 파일 확인
git status

# 2. 충돌 파일 열기
# <<<<<<< HEAD
# 내 변경사항
# =======
# master의 변경사항
# >>>>>>> upstream/master

# 3. 충돌 해결
# - 필요한 코드만 남기기
# - 두 변경사항 모두 필요하면 합치기
# - 충돌 마커 제거 (<<<<<<<, =======, >>>>>>>)

# 4. 해결된 파일 스테이징
git add <resolved-file>

# 5. 병합 완료
# Merge의 경우:
git commit -m "Merge upstream/master into feature/my-feature"

# Rebase의 경우:
git rebase --continue
```

### 4.2 충돌 해결 팁

1. **IDE 도구 활용**: VS Code, IntelliJ 등은 시각적 병합 도구 제공
2. **작은 단위로 병합**: 자주 master를 병합하여 충돌 범위 최소화
3. **팀원과 협의**: 복잡한 충돌은 팀원과 논의

### 4.3 충돌 해결 취소

```bash
# Merge 취소 (아직 커밋 전)
git merge --abort

# Rebase 취소
git rebase --abort
```

---

## 5. 주의사항 및 모범 사례

### 5.1 안전한 작업 습관

#### ✅ 권장 사항

1. **작업 전 항상 최신 상태 확인**
   ```bash
   git fetch upstream
   git status
   ```

2. **작은 단위로 자주 커밋**
   - 의미 있는 단위로 커밋
   - 자주 master와 병합하여 충돌 최소화

3. **푸시 전 테스트**
   ```bash
   npm test
   git push
   ```

4. **명확한 커밋 메시지**
   ```
   [MM-12345] Add feature description
   Fix: resolve login issue
   Docs: update README
   ```

#### ❌ 피해야 할 것

1. **Force push 남용**
   - `--force-with-lease` 사용 (더 안전)
   - 공유 브랜치에서는 절대 사용 금지

2. **master에 직접 작업**
   - 항상 브랜치를 만들어서 작업

3. **충돌 무시**
   - 충돌을 제대로 해결하지 않고 커밋하지 않기

### 5.2 커밋 메시지 규칙

**형식**:
```
[이슈번호] 간단한 설명

상세 설명 (선택사항)
```

**예시**:
```
[OKR-123] Add OKR Best branding to settings page

- Replace Mattermost logo with OKR Best logo
- Update color scheme
- Add new icon assets
```

### 5.3 브랜치 관리

**브랜치 정리**:
```bash
# 머지된 브랜치 삭제
git branch -d feature/merged-feature

# 원격 브랜치 삭제
git push origin --delete feature/merged-feature

# 로컬에서 삭제된 원격 브랜치 정리
git fetch --prune
```

---

## 6. 자주 묻는 질문

### Q1: 개인 브랜치에 master를 수시로 merge하면 병합 커밋이 많이 생기는데 괜찮나요?

**A**: 네, 괜찮습니다.
- 병합 커밋이 있어도 기능적으로 문제없음
- GitHub PR에서 "Rebase and Merge"로 병합하면 최종적으로 깔끔해짐
- 안전성이 더 중요함

**대안**: Rebase 사용 (개인 브랜치일 때만)
```bash
git rebase upstream/master
```

### Q2: Rebase와 Merge 중 어떤 것을 사용해야 하나요?

**A**: 상황에 따라 다릅니다.

| 상황 | 권장 방법 |
|------|----------|
| 개인 브랜치에 master 반영 | **Merge** (안전) |
| PR 병합 (GitHub) | **Rebase and Merge** (GitHub 자동) |
| 공유 브랜치 | **Merge만 사용** |

**원칙**: 불확실하면 **Merge 사용**

### Q3: Force push를 해도 되나요?

**A**: 조건부로 가능합니다.

**가능한 경우**:
- ✅ 개인 브랜치일 때
- ✅ 다른 사람이 사용하지 않는 브랜치
- ✅ `--force-with-lease` 사용

**불가능한 경우**:
- ❌ master 브랜치
- ❌ 다른 사람과 공유하는 브랜치
- ❌ 이미 PR이 생성되어 리뷰 중인 브랜치 (팀 협의 필요)

### Q4: 충돌이 너무 복잡한데 어떻게 하나요?

**A**: 다음 순서로 진행하세요.

1. **작은 단위로 나누기**: 큰 충돌을 여러 작은 충돌로 분리
2. **팀원과 협의**: 복잡한 충돌은 팀원과 논의
3. **IDE 도구 활용**: VS Code, IntelliJ 등의 병합 도구 사용
4. **백업**: 복잡한 충돌 해결 전 브랜치 백업
   ```bash
   git branch backup/feature-name
   ```

### Q5: PR 전에 브랜치를 정리해야 하나요?

**A**: 선택사항입니다.

**정리하지 않아도 됨**:
- 병합 커밋이 있어도 PR 기능에 문제없음
- GitHub에서 "Rebase and Merge"로 병합하면 깔끔해짐

**정리하고 싶다면**:
```bash
git rebase upstream/master
git push --force-with-lease
```

**주의**: 이미 PR이 생성되어 있으면 팀과 협의 필요

### Q6: master에 직접 커밋해도 되나요?

**A**: 절대 안 됩니다.

- 항상 브랜치를 만들어서 작업
- PR을 통해서만 master에 병합
- 예외 없음

---

## 7. 실전 예시

### 예시 1: 일반적인 기능 개발

```bash
# 1. 시작
git checkout master
git fetch upstream
git merge upstream/master
git checkout -b feature/add-new-feature

# 2. 작업 및 커밋
git add .
git commit -m "[OKR-123] Add new feature"
git push origin feature/add-new-feature

# 3. master에 변경사항 발생 시
git fetch upstream
git merge upstream/master  # 충돌 없으면 자동 완료

# 4. 계속 작업
git add .
git commit -m "[OKR-123] Fix bug in new feature"
git push origin feature/add-new-feature

# 5. PR 생성 (GitHub에서)
# 6. 리뷰 후 "Rebase and Merge"로 병합
```

### 예시 2: 장기간 개발되는 기능

```bash
# 주기적으로 master 반영 (예: 매일)
git fetch upstream
git merge upstream/master

# 충돌 해결
# ... 충돌 해결 ...
git add .
git commit -m "Merge upstream/master into feature/long-term-feature"
git push origin feature/long-term-feature
```

### 예시 3: 긴급 버그 수정

```bash
# 1. master에서 긴급 브랜치 생성
git checkout master
git fetch upstream
git merge upstream/master
git checkout -b hotfix/critical-bug

# 2. 빠르게 수정 및 커밋
git add .
git commit -m "[OKR-456] Fix critical bug"
git push origin hotfix/critical-bug

# 3. 즉시 PR 생성 및 병합
```

---

## 8. 체크리스트

### 작업 시작 전
- [ ] master 브랜치 최신 상태 확인
- [ ] 새 브랜치 생성
- [ ] 브랜치 이름 규칙 준수

### 작업 중
- [ ] 의미 있는 단위로 커밋
- [ ] 명확한 커밋 메시지 작성
- [ ] 주기적으로 master 변경사항 반영 (Merge 사용)

### PR 생성 전
- [ ] 최신 master 반영 확인
- [ ] 테스트 통과 확인
- [ ] 커밋 메시지 검토

### PR 병합 시
- [ ] "Rebase and Merge" 선택 (권장)
- [ ] 병합 후 브랜치 정리

---

## 9. 문제 해결

### 문제: Merge 후 히스토리가 복잡해짐

**해결**: PR 병합 시 "Rebase and Merge" 사용하면 최종적으로 깔끔해짐

### 문제: Rebase 중 충돌이 너무 많음

**해결**: 
1. Rebase 취소: `git rebase --abort`
2. Merge 사용: `git merge upstream/master`
3. 충돌을 한 번에 해결

### 문제: 실수로 잘못된 브랜치에 커밋

**해결**:
```bash
# 커밋만 다른 브랜치로 이동
git log --oneline -5  # 커밋 해시 확인
git checkout correct-branch
git cherry-pick <commit-hash>
git checkout wrong-branch
git reset --hard HEAD~1  # 잘못된 브랜치에서 커밋 제거
```

---

## 10. 요약

### 핵심 원칙

1. **안전성 우선**: Merge 사용이 가장 안전
2. **일관성**: 모든 팀원이 동일한 방식 사용
3. **명확성**: 커밋 메시지와 브랜치명 명확하게

### 권장 워크플로우

```
1. master 업데이트 → 2. 브랜치 생성 → 3. 작업 → 4. master 병합 (Merge) → 5. PR 생성 → 6. Rebase and Merge로 병합
```

### 기억할 것

- ✅ **개인 브랜치에 master 반영**: Merge 사용
- ✅ **PR 병합**: Rebase and Merge 사용
- ❌ **공유 브랜치에서 Rebase 금지**
- ❌ **master에 직접 푸시 금지**

---

*문서 작성일: 2026-01-04*  
*적용 대상: OKR Best Desktop 프로젝트 전체 팀원*
