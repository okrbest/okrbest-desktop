# OKR Best Desktop GitHub CI/CD 가이드

> GitHub Actions를 이용한 OKR Best Desktop의 CI/CD 파이프라인 구성 및 리브랜딩 가이드입니다.

---

## 목차

0. [초보자를 위한 시작 가이드](#0-초보자를-위한-시작-가이드)
1. [CI/CD 파이프라인 개요](#1-cicd-파이프라인-개요)
2. [워크플로우 구성](#2-워크플로우-구성)
3. [필수 Secrets 설정](#3-필수-secrets-설정)
4. [배포 프로세스](#4-배포-프로세스)
5. [OKR Best 리브랜딩 수정 작업](#5-okr-best-리브랜딩-수정-작업)
6. [트러블슈팅](#6-트러블슈팅)

---

## 0. 초보자를 위한 시작 가이드

> GitHub Actions를 처음 사용하는 분들을 위한 단계별 설정 가이드입니다.

### 0.1 GitHub Actions란?

GitHub Actions는 GitHub 저장소에서 자동화된 워크플로우를 실행할 수 있는 CI/CD 플랫폼입니다. 코드를 푸시하거나, Pull Request를 생성하거나, 태그를 생성할 때 자동으로 빌드, 테스트, 배포 작업을 수행할 수 있습니다.

### 0.2 사전 준비

#### 필수 사항
- [ ] GitHub 계정
- [ ] GitHub 저장소 (이미 생성되어 있어야 함)
- [ ] 저장소에 대한 관리자 권한 (워크플로우 파일 생성 및 Secrets 설정)

#### 확인 사항
- [ ] 저장소가 GitHub에 푸시되어 있는지 확인
- [ ] 로컬에서 저장소를 클론할 수 있는지 확인

### 0.3 GitHub Actions 활성화 확인

1. **GitHub 저장소 페이지 접속**
   - 브라우저에서 저장소 URL로 이동
   - 예: `https://github.com/okrbest/okrbest-desktop`

2. **Actions 탭 확인**
   - 저장소 상단 메뉴에서 **Actions** 탭 클릭
   - 처음 사용하는 경우 "Get started with GitHub Actions" 메시지가 표시될 수 있음
   - **"I understand my workflows, go ahead and enable them"** 클릭하여 활성화

3. **워크플로우 파일 확인**
   - Actions 탭에서 기존 워크플로우가 있는지 확인
   - 왼쪽 사이드바에 워크플로우 목록이 표시됨

### 0.4 워크플로우 파일 위치 이해

GitHub Actions 워크플로우는 특정 디렉터리에 YAML 파일로 저장됩니다:

```
프로젝트 루트/
└── .github/
    └── workflows/
        ├── release.yaml          # 릴리스 배포 워크플로우
        ├── ci.yaml               # CI 파이프라인
        ├── build-for-pr.yml      # PR 빌드
        └── ...
```

**중요**: 
- `.github/workflows/` 디렉터리가 반드시 필요합니다
- 파일 확장자는 `.yml` 또는 `.yaml` 모두 가능합니다
- 파일명은 자유롭게 지정할 수 있지만, 의미있는 이름을 사용하는 것이 좋습니다

### 0.5 첫 번째 워크플로우 실행 테스트

#### 방법 1: 간단한 테스트 워크플로우 생성

1. **로컬에서 워크플로우 파일 생성**

```bash
# 프로젝트 루트에서 실행
mkdir -p .github/workflows

# 테스트 워크플로우 파일 생성
cat > .github/workflows/test.yml << 'EOF'
name: Test Workflow

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:  # 수동 실행 가능

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Print message
        run: echo "Hello, GitHub Actions!"
      
      - name: Show current directory
        run: pwd
      
      - name: List files
        run: ls -la
EOF
```

2. **커밋 및 푸시**

```bash
# 파일 추가
git add .github/workflows/test.yml

# 커밋
git commit -m "Add test workflow"

# 푸시
git push origin main  # 또는 master
```

3. **워크플로우 실행 확인**

- GitHub 저장소의 **Actions** 탭으로 이동
- 왼쪽 사이드바에서 **"Test Workflow"** 클릭
- 최근 실행 목록에서 실행 중인 워크플로우 확인
- 워크플로우 이름을 클릭하여 상세 로그 확인

#### 방법 2: 수동 실행 (workflow_dispatch 사용)

1. **GitHub 저장소의 Actions 탭으로 이동**
2. 왼쪽 사이드바에서 **"Test Workflow"** 선택
3. 오른쪽 상단의 **"Run workflow"** 버튼 클릭
4. 브랜치 선택 후 **"Run workflow"** 클릭
5. 워크플로우 실행 확인

### 0.6 워크플로우 실행 결과 확인

#### 실행 상태 확인

워크플로우 실행 상태는 다음 아이콘으로 표시됩니다:

- 🟡 **노란색 원**: 실행 중
- ✅ **초록색 체크**: 성공
- ❌ **빨간색 X**: 실패
- ⚪ **회색 원**: 취소됨

#### 로그 확인 방법

1. **Actions 탭에서 워크플로우 선택**
2. **실행 목록에서 특정 실행 클릭**
3. **왼쪽 사이드바에서 Job 선택** (예: "test")
4. **각 Step을 클릭하여 로그 확인**

#### 로그에서 확인할 수 있는 정보

- 각 단계의 실행 시간
- 출력된 메시지 및 에러
- 환경 변수 값
- 파일 시스템 상태

### 0.7 기존 워크플로우 이해하기

프로젝트에 이미 있는 워크플로우를 이해하는 방법:

#### 1. 워크플로우 파일 읽기

```bash
# 로컬에서 워크플로우 파일 확인
cat .github/workflows/ci.yaml
```

#### 2. 주요 구성 요소 이해

**트리거 (on)**:
```yaml
on:
  push:              # 코드 푸시 시 실행
  pull_request:      # PR 생성/업데이트 시 실행
  workflow_dispatch: # 수동 실행
```

**Job (작업)**:
```yaml
jobs:
  build:            # Job 이름
    runs-on: ubuntu-latest  # 실행 환경
    steps:          # 실행할 단계들
      - name: Step 1
        run: echo "Hello"
```

**Step (단계)**:
- 각 Step은 순차적으로 실행됩니다
- 하나의 Step이 실패하면 전체 Job이 실패합니다

### 0.8 일반적인 문제 해결

#### 문제 1: 워크플로우가 실행되지 않음

**원인 및 해결**:
- [ ] `.github/workflows/` 디렉터리가 올바른 위치에 있는지 확인
- [ ] 파일 확장자가 `.yml` 또는 `.yaml`인지 확인
- [ ] YAML 문법 오류가 없는지 확인 (들여쓰기 주의)
- [ ] 트리거 조건이 맞는지 확인 (예: 브랜치 이름)

#### 문제 2: 워크플로우가 실패함

**확인 사항**:
1. **로그 확인**: 실패한 Step의 로그를 자세히 확인
2. **권한 확인**: 필요한 권한이 있는지 확인
3. **파일 경로 확인**: 파일 경로가 올바른지 확인
4. **환경 변수 확인**: 필요한 환경 변수가 설정되어 있는지 확인

#### 문제 3: Secrets를 찾을 수 없음

**해결 방법**:
- Secrets는 저장소 Settings에서 설정해야 합니다
- 자세한 내용은 [3. 필수 Secrets 설정](#3-필수-secrets-설정) 섹션 참조

### 0.9 프로덕션 릴리스 배포하기

> 실제 사용자에게 배포할 수 있는 릴리스를 만드는 방법입니다.

#### 0.9.1 배포 전 준비사항

프로덕션 릴리스를 배포하기 전에 다음 사항을 확인해야 합니다:

- [ ] **코드 서명 인증서 준비**
  - Windows: 코드 서명 인증서 (PFX 파일)
  - macOS: Apple Developer 인증서 및 프로비저닝 프로파일
  - 자세한 내용은 [3. 필수 Secrets 설정](#3-필수-secrets-설정) 참조

- [ ] **GitHub Secrets 설정 완료**
  - Windows 코드 서명 Secrets
  - macOS 코드 서명 Secrets
  - AWS S3 자격 증명 (배포 서버용)
  - GitHub Personal Access Token

- [ ] **배포 서버 준비**
  - AWS S3 버킷 생성 및 설정
  - 또는 다른 배포 서버 준비

- [ ] **버전 번호 결정**
  - `package.json`의 `version` 필드 확인
  - 시맨틱 버저닝 규칙 준수 (예: 1.0.0, 1.0.1, 1.1.0)

#### 0.9.2 릴리스 배포 단계별 가이드

##### 1단계: 버전 번호 확인 및 업데이트

```bash
# package.json 파일 열기
# "version" 필드 확인
# 예: "version": "1.0.0"

# 필요시 버전 업데이트
# 예: 1.0.0 → 1.0.1
```

**버전 번호 규칙** (시맨틱 버저닝):
- **Major** (1.0.0): 큰 변경사항, 하위 호환성 깨짐
- **Minor** (0.1.0): 새로운 기능 추가, 하위 호환성 유지
- **Patch** (0.0.1): 버그 수정, 하위 호환성 유지

##### 2단계: 변경사항 커밋 및 푸시

```bash
# 변경사항 확인
git status

# package.json이 변경되었다면 커밋
git add package.json package-lock.json
git commit -m "Bump version to 1.0.0"

# main 브랜치에 푸시
git push origin main
```

**주의**: 
- 버전 업데이트는 main 브랜치에 직접 커밋하거나, 별도 브랜치에서 PR을 통해 머지합니다
- 프로덕션 릴리스는 보통 main 브랜치에서 진행합니다

##### 3단계: Git 태그 생성

Git 태그는 릴리스 버전을 표시하는 마커입니다. 태그를 푸시하면 자동으로 배포 워크플로우가 실행됩니다.

```bash
# 주석이 있는 태그 생성 (권장)
git tag -a v1.0.0 -m "Release v1.0.0"

# 또는 간단한 태그 생성
git tag v1.0.0

# 태그 확인
git tag -l

# 태그를 원격 저장소에 푸시
git push origin v1.0.0

# 모든 태그 푸시 (필요시)
git push origin --tags
```

**태그 형식**:
- 정식 릴리스: `v1.0.0`
- RC (Release Candidate): `v1.0.0-rc.1`
- 베타: `v1.0.0-beta.1`
- 알파: `v1.0.0-alpha.1`

**중요**: 
- 태그 이름은 `v`로 시작해야 합니다 (예: `v1.0.0`)
- 태그를 푸시하면 즉시 배포 워크플로우가 시작됩니다
- 태그는 삭제하기 어려우므로 신중하게 생성하세요

##### 4단계: GitHub Actions에서 워크플로우 확인

1. **GitHub 저장소 페이지로 이동**
   - 브라우저에서 저장소 URL 열기
   - 예: `https://github.com/okrbest/okrbest-desktop`

2. **Actions 탭 클릭**
   - 저장소 상단 메뉴에서 **Actions** 탭 선택

3. **워크플로우 실행 확인**
   - 왼쪽 사이드바에서 **"release"** 워크플로우 선택
   - 최근 실행 목록에서 방금 시작된 워크플로우 확인
   - 워크플로우 이름을 클릭하여 상세 정보 확인

4. **실행 상태 모니터링**
   - 🟡 노란색 원: 실행 중
   - ✅ 초록색 체크: 성공
   - ❌ 빨간색 X: 실패

**예상 소요 시간**:
- 전체 빌드 및 배포: 약 20-30분
- Linux 빌드: 약 5-10분
- Windows 빌드: 약 10-15분 (코드 서명 포함)
- macOS 빌드: 약 10-15분 (코드 서명 및 공증 포함)

##### 5단계: 빌드 결과 확인

각 플랫폼별 빌드가 완료되면:

1. **빌드 아티팩트 확인**
   - 워크플로우 실행 페이지에서 각 Job 클릭
   - "Artifacts" 섹션에서 빌드된 파일 확인
   - 다운로드하여 로컬에서 테스트 가능

2. **S3 업로드 확인** (설정된 경우)
   ```bash
   # AWS CLI로 확인
   aws s3 ls s3://releases.okrbest.com/desktop/1.0.0/
   ```
   - 또는 AWS 콘솔에서 S3 버킷 확인

3. **GitHub Releases 확인**
   - 저장소의 **Releases** 탭으로 이동
   - 드래프트(Draft) 상태의 릴리스 확인
   - 릴리스 노트 및 다운로드 파일 확인

##### 6단계: GitHub Releases 발행

배포가 완료되면 GitHub Releases를 발행해야 사용자가 다운로드할 수 있습니다:

1. **Releases 페이지로 이동**
   - 저장소 상단 메뉴에서 **Releases** 클릭
   - 또는 `https://github.com/okrbest/okrbest-desktop/releases` 직접 접속

2. **드래프트 릴리스 확인**
   - "Draft" 레이블이 있는 릴리스 찾기
   - 릴리스 제목 및 버전 확인

3. **릴리스 노트 검토**
   - 자동 생성된 릴리스 노트 확인
   - 필요시 수정 또는 추가 정보 입력

4. **릴리스 발행**
   - **"Publish release"** 버튼 클릭
   - 확인 대화상자에서 **"Publish release"** 클릭

**주의**: 
- 릴리스를 발행하면 모든 사용자가 다운로드할 수 있습니다
- 발행 전에 릴리스 노트와 파일을 꼼꼼히 확인하세요

#### 0.9.3 배포 후 확인사항

릴리스 발행 후 다음 사항을 확인합니다:

- [ ] **다운로드 링크 테스트**
  - Windows MSI/EXE 파일 다운로드 테스트
  - macOS DMG 파일 다운로드 테스트
  - Linux TAR.GZ/DEB 파일 다운로드 테스트

- [ ] **설치 테스트**
  - 각 플랫폼에서 설치 프로그램 실행
  - 앱이 정상적으로 설치되는지 확인
  - 앱이 정상적으로 실행되는지 확인

- [ ] **자동 업데이트 확인** (설정된 경우)
  - 이전 버전 앱에서 업데이트 체크
  - 새 버전이 감지되는지 확인
  - 자동 업데이트가 정상 작동하는지 확인

- [ ] **릴리스 노트 확인**
  - GitHub Releases 페이지에서 릴리스 노트가 올바르게 표시되는지 확인
  - 다운로드 링크가 정상 작동하는지 확인

#### 0.9.4 문제 발생 시 대응

##### 배포 실패 시

1. **워크플로우 로그 확인**
   - 실패한 Job의 로그를 자세히 확인
   - 에러 메시지 확인

2. **일반적인 실패 원인**
   - Secrets 설정 오류 (코드 서명 인증서 등)
   - 네트워크 문제
   - 빌드 스크립트 오류
   - 권한 문제

3. **재시도 방법**
   - 문제를 수정한 후 다시 태그 생성
   - 또는 GitHub Actions에서 "Re-run all jobs" 클릭

##### 태그 실수로 생성한 경우

```bash
# 로컬에서 태그 삭제
git tag -d v1.0.0

# 원격 저장소에서 태그 삭제
git push origin --delete v1.0.0

# 또는
git push origin :refs/tags/v1.0.0
```

**주의**: 
- 태그를 삭제해도 이미 시작된 워크플로우는 계속 실행됩니다
- 워크플로우를 취소하려면 GitHub Actions에서 수동으로 취소해야 합니다

#### 0.9.5 배포 체크리스트

프로덕션 릴리스 배포 전 최종 확인:

- [ ] 코드가 main 브랜치에 머지되었는가?
- [ ] 모든 테스트가 통과했는가?
- [ ] 버전 번호가 올바르게 설정되었는가?
- [ ] 모든 Secrets가 설정되었는가?
- [ ] 배포 서버(S3 등)가 준비되었는가?
- [ ] 릴리스 노트가 준비되었는가?
- [ ] 팀원들에게 배포 계획을 공유했는가?

#### 0.9.6 배포 예시 시나리오

**시나리오: v1.0.0 정식 릴리스 배포**

```bash
# 1. 최신 코드 확인
git checkout main
git pull origin main

# 2. 버전 확인 (package.json)
# "version": "1.0.0" 확인

# 3. 태그 생성
git tag -a v1.0.0 -m "Release v1.0.0 - Initial release"

# 4. 태그 푸시
git push origin v1.0.0

# 5. GitHub Actions에서 워크플로우 실행 확인
# 브라우저에서 https://github.com/okrbest/okrbest-desktop/actions 확인

# 6. 약 30분 후 워크플로우 완료 확인

# 7. GitHub Releases에서 드래프트 릴리스 확인
# https://github.com/okrbest/okrbest-desktop/releases

# 8. 릴리스 노트 검토 후 발행
```

**시나리오: v1.0.1 패치 릴리스 배포**

```bash
# 1. 버그 수정 완료 후 버전 업데이트
# package.json에서 "version": "1.0.1"로 변경

# 2. 커밋 및 푸시
git add package.json package-lock.json
git commit -m "Bump version to 1.0.1"
git push origin main

# 3. 태그 생성 및 푸시
git tag -a v1.0.1 -m "Release v1.0.1 - Bug fixes"
git push origin v1.0.1

# 4. 배포 프로세스 동일하게 진행
```

### 0.10 다음 단계

워크플로우가 정상적으로 실행되는 것을 확인했다면:

1. ✅ **기본 워크플로우 이해 완료**
2. ✅ **프로덕션 릴리스 배포 방법 학습 완료**
3. → [1. CI/CD 파이프라인 개요](#1-cicd-파이프라인-개요)로 이동하여 프로젝트의 워크플로우 구조 이해
4. → [3. 필수 Secrets 설정](#3-필수-secrets-설정)으로 이동하여 필요한 Secrets 설정
5. → [4. 배포 프로세스](#4-배포-프로세스)로 이동하여 상세한 배포 프로세스 학습

### 0.11 유용한 팁

#### 워크플로우 디버깅

1. **작은 단계부터 시작**: 복잡한 워크플로우를 한 번에 만들지 말고, 간단한 것부터 시작
2. **로그 확인**: 각 Step의 로그를 자세히 확인하여 문제 파악
3. **테스트 브랜치 사용**: main 브랜치에 직접 푸시하지 말고, 테스트 브랜치에서 먼저 확인

#### 워크플로우 최적화

1. **캐시 활용**: `actions/cache`를 사용하여 빌드 시간 단축
2. **병렬 실행**: 여러 Job을 병렬로 실행하여 전체 시간 단축
3. **조건부 실행**: `if` 조건을 사용하여 불필요한 실행 방지

#### 참고 자료

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [워크플로우 문법 가이드](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [사용 가능한 Actions 마켓플레이스](https://github.com/marketplace?type=actions)

---

## 1. CI/CD 파이프라인 개요

### 1.1 주요 워크플로우

| 워크플로우 파일 | 트리거 | 목적 |
|----------------|--------|------|
| `release.yaml` | Git 태그 (`v*.*.*`) | 프로덕션 릴리스 배포 |
| `ci.yaml` | Pull Request | PR 검증 (빌드 + 테스트) |
| `build-for-pr.yml` | PR 라벨 (`Build Apps for PR`) | PR용 빌드 아티팩트 생성 |
| `nightly-builds.yaml` | 스케줄/수동 | 나이틀리 빌드 |
| `release-mas.yaml` | Git 태그 (`v*.*.*-mas.*`) | Mac App Store 배포 |

### 1.2 빌드 플랫폼

- **Linux**: Ubuntu 22.04 (x64, arm64)
- **Windows**: Windows 2022 (x64, arm64)
- **macOS**: macOS 15 (x64, arm64, universal)

### 1.3 배포 대상

1. **S3 스토리지**: 자동 업데이트 서버 (`releases.okrbest.com/desktop/`)
2. **GitHub Releases**: 릴리스 노트 및 다운로드 파일

---

## 2. 워크플로우 구성

### 2.1 릴리스 배포 워크플로우 (`release.yaml`)

#### 트리거 조건
```yaml
on:
  push:
    tags:
      - "v[0-9]+.[0-9]+.[0-9]+"        # 정식 릴리스 (예: v1.0.0)
      - "v[0-9]+.[0-9]+.[0-9]+-rc.[0-9]+"  # RC 릴리스 (예: v1.0.0-rc.1)
```

#### 작업 흐름

```
begin-notification (알림 시작)
    ↓
┌─────────────────────────────────────┐
│ 병렬 빌드 작업                        │
├─────────────────────────────────────┤
│ build-linux                         │
│   - Ubuntu 22.04                    │
│   - Linux 패키지 빌드 (deb, rpm, tar.gz, AppImage) │
│                                     │
│ build-msi-installer                 │
│   - Windows 2022                    │
│   - Windows 설치 프로그램 빌드 (NSIS, MSI, ZIP) │
│   - 코드 서명 포함                   │
│                                     │
│ build-mac-installer                 │
│   - macOS 15                        │
│   - macOS DMG 빌드 (x64, arm64, universal) │
│   - 코드 서명 및 공증 포함           │
└─────────────────────────────────────┘
    ↓
upload-to-s3 (S3 업로드)
    ↓
github-release (GitHub Releases 생성)
    ↓
end-notification (완료 알림)
```

#### 주요 단계

**1. 빌드 단계**
- 의존성 설치
- 테스트 실행 (`.github/actions/test` 사용)
- 플랫폼별 패키징
- 업데이트 YAML 파일 패치 (`patch_updater_yml.sh`)
- 아티팩트 업로드

**2. S3 업로드 단계**
- 모든 플랫폼 빌드 다운로드
- S3 버킷에 업로드 (`s3://releases.okrbest.com/desktop/`)
- 공개 읽기 권한 설정

**3. GitHub Releases 단계**
- 릴리스 노트 생성 (`generate_release_markdown.sh`)
- GitHub Releases에 드래프트로 생성
- 모든 플랫폼 파일 첨부

### 2.2 CI 파이프라인 (`ci.yaml`)

#### 트리거 조건
```yaml
on:
  pull_request:  # PR 생성/업데이트 시 자동 실행
```

#### 작업
- Linux, Windows, macOS 빌드 및 테스트
- 테스트 결과를 PR에 코멘트로 표시
- 빌드 아티팩트 업로드 (10일 보관)

### 2.3 PR 빌드 (`build-for-pr.yml`)

#### 트리거 조건
```yaml
on:
  pull_request:
    types:
      - labeled
# PR에 "Build Apps for PR" 라벨 추가 시 실행
```

#### 용도
- PR에서 테스트할 수 있는 빌드 아티팩트 생성
- 수동으로 빌드를 트리거할 때 사용

### 2.4 나이틀리 빌드 (`nightly-builds.yaml`)

#### 트리거 조건
```yaml
on:
  workflow_dispatch:  # 수동 실행
  schedule:
    - cron: 0 4 * * 0-5  # 매주 월~토 오전 4시 (UTC)
```

#### 작업
- 버전 자동 패치 (나이틀리 버전)
- Git 태그 생성
- 빌드 실행

---

## 3. 필수 Secrets 설정

### 3.1 GitHub Secrets 설정 위치

**Settings → Secrets and variables → Actions → New repository secret**

### 3.2 Windows 코드 서명

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY` | PFX 키 (Base64 인코딩) | `base64 encoded key` |
| `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD` | 인증서 비밀번호 | `your_password` |
| `OKRBEST_DESKTOP_WIN_INSTALLER_PFX` | PFX 파일 경로 (선택) | - |
| `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK` | 인증서 파일 경로 | `path/to/certificate.pfx` |

**참고**: Windows 코드 서명 인증서는 EV (Extended Validation) 인증서를 권장합니다.

### 3.3 macOS 코드 서명 및 공증

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | 인증서 비밀번호 | `your_password` |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | 인증서 파일 경로 | `path/to/certificate.p12` |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | 프로비저닝 프로파일 (Base64) | `base64 encoded profile` |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | Apple API 키 ID | `ABC123DEF4` |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | Apple API 키 (Base64) | `base64 encoded key.p8` |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | Apple API Issuer ID | `12345678-1234-1234-1234-123456789012` |

**참고**: 
- Apple Developer 계정 필요
- API 키는 App Store Connect에서 생성
- 프로비저닝 프로파일은 Base64로 인코딩하여 저장

### 3.4 AWS S3 배포

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

**S3 버킷 설정**:
- 버킷 이름: `releases.okrbest.com` (또는 OKR Best 도메인)
- 경로: `/desktop/`
- 권한: 공개 읽기 (`public-read`)
- CORS 설정 필요

### 3.5 GitHub Releases

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `OKRBEST_BUILD_GH_TOKEN` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxx` |

**토큰 권한**:
- `repo` (전체 권한)
- `write:packages` (선택)

### 3.6 알림 (선택사항)

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 웹훅 URL (Slack, Discord 등) | `https://hooks.slack.com/...` |

**참고**: Mattermost 웹훅은 제거하거나 OKR Best 알림 시스템으로 교체해야 합니다.

---

## 4. 배포 프로세스

### 4.1 릴리스 배포 절차

#### 1단계: 버전 업데이트

```bash
# package.json에서 버전 수정
# 예: "version": "1.0.0"

# 커밋 및 푸시
git add package.json package-lock.json
git commit -m "Bump version to 1.0.0"
git push origin main
```

#### 2단계: Git 태그 생성

```bash
# 태그 생성
git tag -a v1.0.0 -m "Release v1.0.0"

# 태그 푸시
git push origin v1.0.0
```

**태그 형식**:
- 정식 릴리스: `v1.0.0`
- RC 릴리스: `v1.0.0-rc.1`
- Mac App Store: `v1.0.0-mas.1`

#### 3단계: 자동 배포 실행

태그 푸시 시 `release.yaml` 워크플로우가 자동 실행됩니다:

1. **빌드 단계** (약 20-30분)
   - Linux 빌드
   - Windows 빌드 (코드 서명 포함)
   - macOS 빌드 (코드 서명 및 공증 포함)

2. **배포 단계** (약 5분)
   - S3 업로드
   - GitHub Releases 생성

3. **완료 알림**

#### 4단계: GitHub Releases 확인 및 발행

1. GitHub 저장소의 **Releases** 탭 확인
2. 드래프트 릴리스 확인
3. 릴리스 노트 검토
4. **Publish release** 클릭하여 발행

### 4.2 배포 확인

#### S3 확인
```bash
# AWS CLI로 확인
aws s3 ls s3://releases.okrbest.com/desktop/1.0.0/
```

#### GitHub Releases 확인
- 저장소의 Releases 페이지에서 확인
- 다운로드 링크 테스트

#### 자동 업데이트 확인
- 이전 버전 앱에서 업데이트 체크
- `latest.yml` 파일 확인

---

## 5. OKR Best 리브랜딩 수정 작업

### 5.1 워크플로우 파일 수정

#### 작업 1: `.github/workflows/release.yaml` 수정

**수정 위치**: Line 15, 29-35, 101-105, 147-154, 183-184, 198, 222, 247-254

**수정 내용**:

```yaml
# Line 15: 환경 변수 이름 변경
env:
  TERM: xterm
  OKRBEST_WIN_INSTALLERS: 1  # MM_WIN_INSTALLERS → OKRBEST_WIN_INSTALLERS

# Line 29-35: Mattermost 알림 제거 또는 OKR Best로 변경
# 옵션 1: 알림 제거
# - name: release/notify-channel
#   ... (전체 제거)

# 옵션 2: OKR Best 알림으로 변경
- name: release/notify-channel
  uses: slackapi/slack-github-action@v1  # 또는 다른 알림 액션
  with:
    webhook-url: ${{ secrets.OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL }}
    payload: |
      {
        "text": "[${{ steps.calc.outputs.VERSION }}] OKR Best Desktop 릴리스가 시작되었습니다. 약 30분 소요됩니다."
      }

# Line 101-105: Windows Secrets 이름 변경
env:
  OKRBEST_WIN_INSTALLERS: 1
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}

# Line 147-154: macOS Secrets 이름 변경
env:
  APPLE_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  APPLE_API_KEY_RAW: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  APPLE_API_KEY: "./key.p8"
  APPLE_API_ISSUER: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_FOR_PULL_REQUEST: true
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK }}
  MAC_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE }}

# Line 183-184: AWS Secrets 이름 변경
aws-access-key-id: ${{ secrets.OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY }}

# Line 198: S3 경로 변경
run: aws s3 cp ./aws-s3-dist/ s3://releases.okrbest.com/desktop/ --acl public-read --cache-control "no-cache" --recursive

# Line 222: GitHub Token 이름 변경
GITHUB_TOKEN: ${{ secrets.OKRBEST_BUILD_GH_TOKEN }}

# Line 247-254: 알림 제거 또는 변경 (위와 동일)
```

#### 작업 2: `.github/workflows/ci.yaml` 수정

**수정 위치**: Line 102, 124-128

**수정 내용**:

```yaml
# Line 102: 환경 변수 이름 변경 (있는 경우)
env:
  OKRBEST_WIN_INSTALLERS: 1

# Line 124-128: Secrets 이름 변경 (PR 빌드 시 코드 서명 사용하는 경우)
env:
  OKRBEST_WIN_INSTALLERS: 1
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}
```

#### 작업 3: `.github/workflows/build-for-pr.yml` 수정

**수정 위치**: Line 124-128, 166-174

**수정 내용**:

```yaml
# Line 124-128: Windows Secrets 이름 변경
env:
  OKRBEST_WIN_INSTALLERS: 1
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}

# Line 166-174: macOS Secrets 이름 변경
env:
  APPLE_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  APPLE_API_KEY_RAW: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  APPLE_API_KEY: "./key.p8"
  APPLE_API_ISSUER: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_FOR_PULL_REQUEST: true
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK }}
  MAC_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE }}
```

#### 작업 4: `.github/workflows/release-mas.yaml` 수정

**수정 위치**: Line 21-27

**수정 내용**:

```yaml
# Line 21-27: macOS App Store Secrets 이름 변경
env:
  MACOS_NOTIFICATION_STATE_NO_SDK_CHECK: true
  MAS_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE }}
  MACOS_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  MACOS_API_KEY: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  MACOS_API_ISSUER_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_FOR_PULL_REQUEST: true
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK }}
```

### 5.2 스크립트 파일 수정

#### 작업 5: `scripts/generate_release_markdown.sh` 수정

**수정 위치**: Line 15, 18-20

**수정 내용**:

```bash
# Line 15: 다운로드 URL 변경
BASE_URL="https://releases.okrbest.com/desktop/${VERSION}"

# Line 18-20: 제품명 및 문서 링크 변경
cat <<-MD
### OKR Best Desktop v${VERSION} has been released!

Release notes can be found here: https://docs.okrbest.com/install/desktop-app-changelog.html

The download links can be found below.

#### Windows - installer files
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-win-x64.msi")
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-win-arm64.msi") (beta)

#### Windows - zip files
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-win-x64.zip")
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-win-arm64.zip") (beta)

#### Mac
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-mac-universal.dmg")
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-mac-x64.dmg")
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-mac-m1.dmg")

#### Linux
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-arm64.tar.gz") (beta)
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-x64.tar.gz")

#### Linux (Unofficial) - deb files
$(print_link "${BASE_URL}/okrbest-desktop_${VERSION}-1_arm64.deb") (beta)
$(print_link "${BASE_URL}/okrbest-desktop_${VERSION}-1_amd64.deb")

#### Linux (Unofficial) - rpm files (beta)
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-aarch64.rpm") (beta)
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-x86_64.rpm")

#### Linux (Unofficial) - AppImage files
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-arm64.AppImage") (beta)
$(print_link "${BASE_URL}/okrbest-desktop-${VERSION}-linux-x86_64.AppImage")
MD
```

#### 작업 6: `scripts/generate_release_post.sh` 수정

**수정 위치**: Line 14, 16

**수정 내용**:

```bash
# Line 14: GitHub 저장소 URL 변경
cat <<-MD
### [v$VERSION](https://github.com/okrbest/okrbest-desktop/releases/tag/v$VERSION) :tada:
Changes:
$(cat $TEMP_CHANGES_FILE | sed "s/^+\s[a-zA-Z0-9]\+\s/- /" | sed "s/\s(#\([0-9]\+\))$/ [(#\1)](https:\/\/github.com\/okrbest\/okrbest-desktop\/pull\/\1)/" | sed "s/\[\?OKR-\([0-9]\+\)\]\?/[[OKR-\1]](https:\/\/okrbest.atlassian.net\/browse\/OKR-\1)/")

The release will be available on GitHub shortly.
MD
```

**참고**: 이슈 트래커가 Jira인 경우 URL을 OKR Best Jira로 변경하거나, GitHub Issues를 사용하는 경우 해당 부분을 제거합니다.

### 5.3 S3 버킷 설정

#### 작업 7: AWS S3 버킷 생성 및 설정

**필수 설정**:

1. **버킷 생성**
   ```bash
   aws s3 mb s3://releases.okrbest.com
   ```

2. **버킷 정책 설정** (공개 읽기)
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::releases.okrbest.com/desktop/*"
       }
     ]
   }
   ```

3. **CORS 설정**
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "HEAD"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```

4. **정적 웹사이트 호스팅 설정** (선택)
   - 인덱스 문서: `index.html`
   - 오류 문서: `error.html`

### 5.4 GitHub Secrets 설정

#### 작업 8: GitHub Secrets 추가

**Settings → Secrets and variables → Actions → New repository secret**

다음 Secrets를 순서대로 추가:

1. **Windows 코드 서명**
   - `OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY`
   - `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD`
   - `OKRBEST_DESKTOP_WIN_INSTALLER_PFX` (선택)
   - `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK`

2. **macOS 코드 서명**
   - `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD`
   - `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK`
   - `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE`

3. **macOS App Store**
   - `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID`
   - `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY`
   - `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID`
   - `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` (Mac App Store용)
   - `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` (Mac App Store용)
   - `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` (Mac App Store용)

4. **AWS S3**
   - `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID`
   - `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY`

5. **GitHub**
   - `OKRBEST_BUILD_GH_TOKEN`

6. **알림** (선택)
   - `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL`

### 5.5 테스트 배포

#### 작업 9: 테스트 태그로 배포 검증

```bash
# 테스트 버전으로 태그 생성
git tag -a v1.0.0-test -m "Test release v1.0.0-test"
git push origin v1.0.0-test

# GitHub Actions에서 워크플로우 실행 확인
# 각 단계가 정상 완료되는지 확인
```

**확인 사항**:
- [ ] 빌드가 성공적으로 완료되는가?
- [ ] S3에 파일이 업로드되는가?
- [ ] GitHub Releases가 생성되는가?
- [ ] 릴리스 노트가 올바르게 생성되는가?
- [ ] 다운로드 링크가 정상 작동하는가?

---

## 6. 트러블슈팅

### 6.1 빌드 실패

#### Windows 빌드 실패

**문제**: 코드 서명 실패
- **원인**: 인증서 비밀번호 오류 또는 인증서 만료
- **해결**: Secrets 확인 및 인증서 갱신

**문제**: MSI 빌드 실패
- **원인**: WiX Toolset 미설치 또는 경로 오류
- **해결**: GitHub Actions 러너에 WiX Toolset이 포함되어 있는지 확인

#### macOS 빌드 실패

**문제**: 코드 서명 실패
- **원인**: 인증서 또는 프로비저닝 프로파일 오류
- **해결**: 
  - 인증서 유효기간 확인
  - 프로비저닝 프로파일 Base64 인코딩 확인
  - Apple Developer 계정 상태 확인

**문제**: 공증 실패
- **원인**: Apple API 키 오류 또는 네트워크 문제
- **해결**: API 키 및 Issuer ID 확인

#### Linux 빌드 실패

**문제**: 크로스 컴파일 실패 (arm64)
- **원인**: 크로스 컴파일러 미설치
- **해결**: 워크플로우에 `gcc-aarch64-linux-gnu`, `g++-aarch64-linux-gnu` 설치 확인

### 6.2 S3 업로드 실패

**문제**: 권한 오류
- **원인**: AWS 자격 증명 오류 또는 버킷 정책 오류
- **해결**: 
  - AWS Access Key ID 및 Secret 확인
  - 버킷 정책 확인
  - IAM 권한 확인 (`s3:PutObject`, `s3:PutObjectAcl` 필요)

**문제**: 경로 오류
- **원인**: 버킷 이름 또는 경로 오류
- **해결**: S3 버킷 경로 확인 (`s3://releases.okrbest.com/desktop/`)

### 6.3 GitHub Releases 실패

**문제**: 토큰 권한 오류
- **원인**: GitHub Token 권한 부족
- **해결**: Token에 `repo` 권한 확인

**문제**: 릴리스 노트 생성 실패
- **원인**: 스크립트 실행 오류 또는 파일 경로 오류
- **해결**: `generate_release_markdown.sh` 스크립트 확인

### 6.4 자동 업데이트 문제

**문제**: `latest.yml` 파일 형식 오류
- **원인**: `patch_updater_yml.sh` 스크립트 오류
- **해결**: 스크립트 실행 로그 확인

**문제**: 업데이트 서버 접근 불가
- **원인**: S3 버킷 CORS 설정 오류 또는 네트워크 문제
- **해결**: CORS 설정 확인 및 네트워크 연결 확인

---

## 부록: 빠른 참조

### 주요 파일 경로

```
워크플로우:
├── .github/workflows/release.yaml
├── .github/workflows/ci.yaml
├── .github/workflows/build-for-pr.yml
├── .github/workflows/nightly-builds.yaml
└── .github/workflows/release-mas.yaml

스크립트:
├── scripts/patch_updater_yml.sh
├── scripts/generate_release_markdown.sh
├── scripts/generate_release_post.sh
└── scripts/cp_artifacts.sh

커스텀 액션:
└── .github/actions/test/action.yaml
```

### 배포 명령어

```bash
# 버전 업데이트
# package.json 수정 후

# 태그 생성 및 푸시
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 배포 확인
# GitHub Actions 탭에서 워크플로우 실행 확인
```

### Secrets 체크리스트

- [ ] Windows 코드 서명 인증서 (4개)
- [ ] macOS 코드 서명 인증서 (3개)
- [ ] macOS App Store 인증서 (6개)
- [ ] AWS S3 자격 증명 (2개)
- [ ] GitHub Token (1개)
- [ ] 알림 웹훅 URL (1개, 선택)

---

*문서 작성일: 2026-01-04*

