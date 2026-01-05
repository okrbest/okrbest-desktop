# OKR Best CI/CD 리브랜딩 체크리스트

> GitHub CI/CD를 OKR Best로 리브랜딩하기 위한 단계별 체크리스트입니다.

---

## 사전 준비

### 필수 준비 사항

- [ ] AWS 계정 및 S3 버킷 준비
- [ ] Windows 코드 서명 인증서 준비
- [ ] macOS 코드 서명 인증서 및 Apple Developer 계정 준비
- [ ] GitHub Personal Access Token 생성
- [ ] OKR Best 도메인 및 업데이트 서버 URL 확정

---

## Phase 1: 워크플로우 파일 수정

### 작업 1: release.yaml 수정

- [ ] **Line 15**: 환경 변수 이름 변경
  ```yaml
  OKRBEST_WIN_INSTALLERS: 1  # MM_WIN_INSTALLERS → OKRBEST_WIN_INSTALLERS
  ```

- [ ] **Line 29-35**: Mattermost 알림 제거 또는 OKR Best 알림으로 변경
  - [ ] Mattermost 웹훅 액션 제거 또는 교체
  - [ ] 알림 메시지 텍스트 변경

- [ ] **Line 101-105**: Windows Secrets 이름 변경
  ```yaml
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}
  ```

- [ ] **Line 147-154**: macOS Secrets 이름 변경
  ```yaml
  APPLE_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  APPLE_API_KEY_RAW: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  APPLE_API_ISSUER: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK }}
  MAC_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE }}
  ```

- [ ] **Line 183-184**: AWS Secrets 이름 변경
  ```yaml
  aws-access-key-id: ${{ secrets.OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID }}
  aws-secret-access-key: ${{ secrets.OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY }}
  ```

- [ ] **Line 198**: S3 경로 변경
  ```bash
  aws s3 cp ./aws-s3-dist/ s3://releases.okrbest.com/desktop/ ...
  ```

- [ ] **Line 222**: GitHub Token 이름 변경
  ```yaml
  GITHUB_TOKEN: ${{ secrets.OKRBEST_BUILD_GH_TOKEN }}
  ```

- [ ] **Line 247-254**: 완료 알림 제거 또는 변경

**파일**: `.github/workflows/release.yaml`

---

### 작업 2: ci.yaml 수정

- [ ] **Line 102**: 환경 변수 이름 변경 (있는 경우)
  ```yaml
  OKRBEST_WIN_INSTALLERS: 1
  ```

- [ ] **Line 124-128**: Windows Secrets 이름 변경 (PR 빌드 시 코드 서명 사용하는 경우)
  ```yaml
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}
  ```

**파일**: `.github/workflows/ci.yaml`

---

### 작업 3: build-for-pr.yml 수정

- [ ] **Line 124-128**: Windows Secrets 이름 변경
  ```yaml
  PFX_KEY: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD }}
  PFX: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_PFX }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK }}
  ```

- [ ] **Line 166-174**: macOS Secrets 이름 변경
  ```yaml
  APPLE_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  APPLE_API_KEY_RAW: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  APPLE_API_ISSUER: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK }}
  MAC_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE }}
  ```

**파일**: `.github/workflows/build-for-pr.yml`

---

### 작업 4: release-mas.yaml 수정

- [ ] **Line 21-27**: macOS App Store Secrets 이름 변경
  ```yaml
  MAS_PROFILE: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE }}
  MACOS_API_KEY_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID }}
  MACOS_API_KEY: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY }}
  MACOS_API_ISSUER_ID: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID }}
  CSC_KEY_PASSWORD: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD }}
  CSC_LINK: ${{ secrets.OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK }}
  ```

**파일**: `.github/workflows/release-mas.yaml`

---

## Phase 2: 스크립트 파일 수정

### 작업 5: generate_release_markdown.sh 수정

- [ ] **Line 15**: 다운로드 URL 변경
  ```bash
  BASE_URL="https://releases.okrbest.com/desktop/${VERSION}"
  ```

- [ ] **Line 18-20**: 제품명 변경
  ```bash
  ### OKR Best Desktop v${VERSION} has been released!
  ```

- [ ] **Line 20**: 문서 링크 변경
  ```bash
  Release notes can be found here: https://docs.okrbest.com/install/desktop-app-changelog.html
  ```

- [ ] **Line 25-51**: 파일명 변경 (mattermost-desktop → okrbest-desktop)
  - [ ] Windows MSI 파일명
  - [ ] Windows ZIP 파일명
  - [ ] macOS DMG 파일명
  - [ ] Linux TAR.GZ 파일명
  - [ ] Linux DEB 파일명
  - [ ] Linux RPM 파일명
  - [ ] Linux AppImage 파일명

**파일**: `scripts/generate_release_markdown.sh`

---

### 작업 6: generate_release_post.sh 수정

- [ ] **Line 14**: GitHub 저장소 URL 변경
  ```bash
  ### [v$VERSION](https://github.com/okrbest/okrbest-desktop/releases/tag/v$VERSION) :tada:
  ```

- [ ] **Line 16**: Pull Request 링크 URL 변경
  ```bash
  # GitHub 저장소 URL 변경
  ```

- [ ] **Line 16**: 이슈 트래커 변경 (선택)
  ```bash
  # Jira 사용 시: OKR-1234 형식으로 변경
  # GitHub Issues 사용 시: 해당 부분 제거
  ```

**파일**: `scripts/generate_release_post.sh`

---

## Phase 3: 인프라 설정

### 작업 7: AWS S3 버킷 생성 및 설정

- [ ] **S3 버킷 생성**
  ```bash
  aws s3 mb s3://releases.okrbest.com
  ```

- [ ] **버킷 정책 설정** (공개 읽기)
  - [ ] 정책 JSON 작성
  - [ ] 버킷에 정책 적용

- [ ] **CORS 설정**
  - [ ] CORS 설정 JSON 작성
  - [ ] 버킷에 CORS 적용

- [ ] **정적 웹사이트 호스팅 설정** (선택)
  - [ ] 인덱스 문서 설정
  - [ ] 오류 문서 설정

**확인**: `aws s3 ls s3://releases.okrbest.com/desktop/` 명령으로 접근 가능한지 확인

---

### 작업 8: GitHub Secrets 설정

**위치**: GitHub 저장소 → Settings → Secrets and variables → Actions

#### Windows 코드 서명 (4개)

- [ ] `OKRBEST_DESKTOP_WIN_INSTALLER_PFX_KEY`
  - 설명: PFX 키 (Base64 인코딩)
  - 값: Base64로 인코딩된 키

- [ ] `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_KEY_PASSWORD`
  - 설명: 인증서 비밀번호
  - 값: 인증서 비밀번호

- [ ] `OKRBEST_DESKTOP_WIN_INSTALLER_PFX` (선택)
  - 설명: PFX 파일 경로
  - 값: 파일 경로 (있는 경우)

- [ ] `OKRBEST_DESKTOP_WIN_INSTALLER_CSC_LINK`
  - 설명: 인증서 파일 경로
  - 값: 인증서 파일 경로

#### macOS 코드 서명 (3개)

- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD`
  - 설명: 인증서 비밀번호
  - 값: 인증서 비밀번호

- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK`
  - 설명: 인증서 파일 경로
  - 값: 인증서 파일 경로

- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE`
  - 설명: 프로비저닝 프로파일 (Base64)
  - 값: Base64로 인코딩된 프로파일

#### macOS App Store (6개)

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID`
  - 설명: Apple API 키 ID
  - 값: API 키 ID

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY`
  - 설명: Apple API 키 (Base64)
  - 값: Base64로 인코딩된 API 키

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID`
  - 설명: Apple API Issuer ID
  - 값: Issuer ID

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE`
  - 설명: Mac App Store 프로비저닝 프로파일 (Base64)
  - 값: Base64로 인코딩된 프로파일

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD`
  - 설명: Mac App Store 인증서 비밀번호
  - 값: 인증서 비밀번호

- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK`
  - 설명: Mac App Store 인증서 파일 경로
  - 값: 인증서 파일 경로

#### AWS S3 (2개)

- [ ] `OKRBEST_DESKTOP_RELEASE_AWS_ACCESS_KEY_ID`
  - 설명: AWS Access Key ID
  - 값: Access Key ID

- [ ] `OKRBEST_DESKTOP_RELEASE_AWS_SECRET_ACCESS_KEY`
  - 설명: AWS Secret Access Key
  - 값: Secret Access Key

**IAM 권한 확인**:
- [ ] `s3:PutObject`
- [ ] `s3:PutObjectAcl`
- [ ] `s3:ListBucket`

#### GitHub (1개)

- [ ] `OKRBEST_BUILD_GH_TOKEN`
  - 설명: GitHub Personal Access Token
  - 값: `ghp_xxxxxxxxxxxx`
  - 권한: `repo` (전체 권한)

#### 알림 (1개, 선택)

- [ ] `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL`
  - 설명: 알림 웹훅 URL (Slack, Discord 등)
  - 값: 웹훅 URL

---

## Phase 4: 테스트 및 검증

### 작업 9: 테스트 배포

- [ ] **테스트 태그 생성**
  ```bash
  git tag -a v1.0.0-test -m "Test release v1.0.0-test"
  git push origin v1.0.0-test
  ```

- [ ] **워크플로우 실행 확인**
  - [ ] GitHub Actions 탭에서 워크플로우 실행 확인
  - [ ] 각 단계가 성공적으로 완료되는지 확인

- [ ] **빌드 결과 확인**
  - [ ] Linux 빌드 성공
  - [ ] Windows 빌드 성공
  - [ ] macOS 빌드 성공

- [ ] **S3 업로드 확인**
  ```bash
  aws s3 ls s3://releases.okrbest.com/desktop/1.0.0-test/
  ```
  - [ ] 파일이 업로드되었는지 확인
  - [ ] 공개 접근 가능한지 확인

- [ ] **GitHub Releases 확인**
  - [ ] 드래프트 릴리스가 생성되었는지 확인
  - [ ] 릴리스 노트가 올바르게 생성되었는지 확인
  - [ ] 다운로드 링크가 정상 작동하는지 확인

- [ ] **다운로드 링크 테스트**
  - [ ] Windows MSI 다운로드 테스트
  - [ ] macOS DMG 다운로드 테스트
  - [ ] Linux TAR.GZ 다운로드 테스트

- [ ] **자동 업데이트 확인** (선택)
  - [ ] `latest.yml` 파일 확인
  - [ ] 이전 버전 앱에서 업데이트 체크 테스트

---

## Phase 5: 프로덕션 배포 준비

### 작업 10: 최종 확인

- [ ] **모든 워크플로우 파일 수정 완료**
  - [ ] release.yaml
  - [ ] ci.yaml
  - [ ] build-for-pr.yml
  - [ ] release-mas.yaml

- [ ] **모든 스크립트 파일 수정 완료**
  - [ ] generate_release_markdown.sh
  - [ ] generate_release_post.sh

- [ ] **모든 Secrets 설정 완료**
  - [ ] Windows 코드 서명 (4개)
  - [ ] macOS 코드 서명 (3개)
  - [ ] macOS App Store (6개)
  - [ ] AWS S3 (2개)
  - [ ] GitHub (1개)
  - [ ] 알림 (1개, 선택)

- [ ] **S3 버킷 설정 완료**
  - [ ] 버킷 생성
  - [ ] 정책 설정
  - [ ] CORS 설정

- [ ] **테스트 배포 성공**
  - [ ] 빌드 성공
  - [ ] S3 업로드 성공
  - [ ] GitHub Releases 생성 성공
  - [ ] 다운로드 링크 정상 작동

---

## 배포 실행

### 프로덕션 배포

```bash
# 1. 버전 업데이트
# package.json에서 version 수정

# 2. 커밋 및 푸시
git add package.json package-lock.json
git commit -m "Bump version to 1.0.0"
git push origin main

# 3. 태그 생성 및 푸시
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 4. GitHub Actions에서 워크플로우 실행 확인
# 5. 완료 후 GitHub Releases에서 발행
```

---

## 문제 해결

### 빌드 실패 시

1. **GitHub Actions 로그 확인**
   - 실패한 단계의 로그 확인
   - 에러 메시지 확인

2. **Secrets 확인**
   - Secrets 이름이 올바른지 확인
   - Secrets 값이 올바른지 확인

3. **파일 경로 확인**
   - S3 버킷 경로 확인
   - 스크립트 파일 경로 확인

### S3 업로드 실패 시

1. **AWS 자격 증명 확인**
   - Access Key ID 및 Secret 확인
   - IAM 권한 확인

2. **버킷 설정 확인**
   - 버킷 이름 확인
   - 버킷 정책 확인
   - CORS 설정 확인

### GitHub Releases 실패 시

1. **GitHub Token 확인**
   - Token 권한 확인 (`repo` 권한 필요)
   - Token 만료 확인

2. **스크립트 확인**
   - `generate_release_markdown.sh` 실행 가능한지 확인
   - 파일 경로 확인

---

## 완료 체크리스트

- [ ] 모든 워크플로우 파일 수정 완료
- [ ] 모든 스크립트 파일 수정 완료
- [ ] 모든 Secrets 설정 완료
- [ ] S3 버킷 설정 완료
- [ ] 테스트 배포 성공
- [ ] 프로덕션 배포 준비 완료

---

*문서 작성일: 2026-01-04*

