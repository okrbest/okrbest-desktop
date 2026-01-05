# OKR Best Desktop 빌드 및 배포 가이드

> OKR Best Desktop 애플리케이션의 빌드 환경 구성부터 배포까지의 전체 과정을 안내합니다.

---

## 목차

1. [환경 구성](#1-환경-구성)
2. [의존성 설치](#2-의존성-설치)
3. [개발 빌드](#3-개발-빌드)
4. [프로덕션 빌드](#4-프로덕션-빌드)
5. [플랫폼별 패키징](#5-플랫폼별-패키징)
6. [테스트](#6-테스트)
7. [배포](#7-배포)
8. [트러블슈팅](#8-트러블슈팅)

---

## 1. 환경 구성

### 1.1 필수 요구사항

#### 공통 요구사항
- **Node.js**: >= 18.0.0
- **npm**: Node.js에 포함 (또는 yarn)
- **Git**: 버전 관리

#### 플랫폼별 추가 요구사항

##### Windows
- **Visual Studio Build Tools** 또는 **Visual Studio Community**
  - C++ 빌드 도구 포함
  - Windows SDK
- **7-Zip**: 패키징에 필요 (electron-builder가 자동 설치)
- **WiX Toolset**: MSI 패키지 생성 시 필요 (선택사항)

##### macOS
- **Xcode Command Line Tools**
  ```bash
  xcode-select --install
  ```
- **코드 서명 인증서** (프로덕션 배포 시)
  - Apple Developer 계정 필요
  - `mac.provisionProfile` 파일 필요 (Mac App Store 배포 시)
- **iconutil**: 아이콘 생성 도구 (기본 포함)

##### Linux
- **빌드 도구**:
  ```bash
  # Ubuntu/Debian
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates \
    libxtst-dev \
    libpng++-dev \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    jq \
    icnsutils \
    graphicsmagick \
    tzdata \
    dpkg-sig \
    gpg

  # Fedora/RHEL
  sudo dnf install -y \
    gcc-c++ \
    make \
    libXScrnSaver-devel \
    alsa-lib-devel
  ```

### 1.2 환경 변수 설정

#### 개발 환경
```bash
# .env 파일 또는 환경 변수
NODE_ENV=development
```

#### 프로덕션 빌드
```bash
NODE_ENV=production
```

#### 코드 서명 (Windows)
```bash
# Windows 코드 서명 인증서 경로
CSC_LINK=path/to/certificate.pfx
CSC_KEY_PASSWORD=your_password
```

#### 코드 서명 (macOS)
```bash
# Apple Developer 인증서
APPLE_ID=your@email.com
APPLE_APP_SPECIFIC_PASSWORD=your_app_specific_password
```

#### Sentry 설정 (선택)
```bash
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project
SENTRY_ORG=your-org
SENTRY_PROJECT=your-project
SENTRY_AUTH_TOKEN=your-auth-token
```

---

## 2. 의존성 설치

### 2.1 저장소 클론

```bash
git clone <repository-url>
cd okrbest-desktop
```

### 2.2 npm 의존성 설치

```bash
# 전체 의존성 설치
npm install

# 또는 CI 환경에서 (package-lock.json 기반)
npm ci

# Playwright 브라우저 다운로드 스킵 (CI 환경)
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install
```

### 2.3 설치 후 자동 실행 작업

`postinstall` 스크립트가 자동으로 실행됩니다:
- `patch-package`: 패치 파일 적용
- `electron-builder install-app-deps`: 네이티브 모듈 의존성 설치

### 2.4 설치 확인

```bash
# 버전 확인
node --version  # >= 18.0.0
npm --version

# 의존성 확인
npm list --depth=0
```

---

## 3. 개발 빌드

### 3.1 개발 빌드 실행

```bash
# 개발 빌드 (빠른 빌드, 소스맵 포함)
npm run build

# 또는 개별 빌드
npm run build:main      # Main 프로세스
npm run build:preload   # Preload 스크립트
npm run build:renderer  # Renderer 프로세스
```

### 3.2 개발 모드 실행

```bash
# 빌드 후 실행
npm run start

# 또는 빌드와 실행을 한 번에
npm run restart

# 파일 변경 감시 모드 (Hot Reload)
npm run watch
```

### 3.3 빌드 출력

- **출력 디렉터리**: `dist/`
- **구조**:
  ```
  dist/
  ├── index.js          # Main 프로세스 진입점
  ├── preload.js        # Preload 스크립트
  └── renderer/         # Renderer 프로세스 파일들
      ├── index.html
      └── ...
  ```

---

## 4. 프로덕션 빌드

### 4.1 프로덕션 빌드 실행

```bash
# 기본 프로덕션 빌드
npm run build-prod

# 자동 업데이트 지원 포함
npm run build-prod-upgrade

# Mac App Store용 빌드
npm run build-prod-mas
```

### 4.2 빌드 설정 검증

```bash
# 빌드 설정 파일 검증
npm run check-build-config
```

### 4.3 빌드 환경 변수

프로덕션 빌드 시 다음 환경 변수가 설정됩니다:

- `NODE_ENV=production`: 프로덕션 모드
- `CAN_UPGRADE=true`: 자동 업데이트 활성화 (build-prod-upgrade)
- `IS_MAC_APP_STORE=true`: Mac App Store 빌드 (build-prod-mas)

---

## 5. 플랫폼별 패키징

### 5.1 전체 플랫폼 패키징

```bash
# 모든 플랫폼 패키징 (시간이 오래 걸림)
npm run package
```

### 5.2 Windows 패키징

#### 전체 Windows 패키지
```bash
npm run package:windows
```

#### 개별 패키지 타입
```bash
# ZIP 아카이브 (x64, arm64)
npm run package:windows-zip

# 설치 프로그램 (NSIS, MSI) - 자동 업데이트 지원
npm run package:windows-installers
```

#### 출력 파일
- `release/{version}/okrbest-desktop-{version}-win-x64.zip`
- `release/{version}/okrbest-desktop-{version}-win-arm64.zip`
- `release/{version}/okrbest-desktop-setup-{version}-win.exe` (NSIS)
- `release/{version}/okrbest-desktop-{version}-win-x64.msi` (MSI)

#### Windows 코드 서명

코드 서명을 위해서는 `electron-builder.json`에 인증서 정보를 설정하거나 환경 변수를 사용합니다:

```bash
# 환경 변수로 설정
export CSC_LINK=path/to/certificate.pfx
export CSC_KEY_PASSWORD=your_password

npm run package:windows-installers
```

### 5.3 macOS 패키징

#### 기본 패키징
```bash
# DMG 및 ZIP (x64, arm64)
npm run package:mac

# Universal 바이너리 포함
npm run package:mac-with-universal
```

#### Mac App Store 패키징
```bash
# Mac App Store용 빌드
npm run package:mas

# 개발용 빌드
npm run package:mas-dev
```

#### 출력 파일
- `release/{version}/okrbest-desktop-{version}-mac-x64.dmg`
- `release/{version}/okrbest-desktop-{version}-mac-arm64.dmg`
- `release/{version}/okrbest-desktop-{version}-mac-universal.dmg`
- `release/{version}/okrbest-desktop-{version}-mac-x64.zip`

#### macOS 코드 서명

```bash
# Apple Developer 인증서 필요
# 프로비저닝 프로파일: mac.provisionProfile
# Mac App Store용: mas.provisionProfile
```

### 5.4 Linux 패키징

#### 전체 Linux 패키지
```bash
npm run package:linux
```

#### 개별 패키지 타입
```bash
# TAR.GZ 아카이브 (x64, arm64)
npm run package:linux-tar

# DEB/RPM 패키지 (x64, arm64)
npm run package:linux-pkg

# AppImage (자동 업데이트 지원, x64, arm64)
npm run package:linux-appImage
```

#### 출력 파일
- `release/{version}/okrbest-desktop-{version}-linux-x64.tar.gz`
- `release/{version}/okrbest-desktop-{version}-linux-arm64.tar.gz`
- `release/{version}/okrbest-desktop_{version}-1_x64.deb`
- `release/{version}/okrbest-desktop-{version}-1.x86_64.rpm`
- `release/{version}/okrbest-desktop-{version}-linux-x64.AppImage`

#### Linux 패키지 서명 (선택)

```bash
# DEB 패키지 서명
make sign-linux-deb GPG_KEY_ID=your-gpg-key-id

# 또는 수동으로
dpkg-sig -k ${GPG_KEY_ID} --sign builder release/{version}/*.deb
```

### 5.5 패키징 출력 디렉터리

모든 패키지는 `release/` 디렉터리에 생성됩니다:

```
release/
└── {version}/
    ├── okrbest-desktop-{version}-win-x64.zip
    ├── okrbest-desktop-{version}-win-arm64.zip
    ├── okrbest-desktop-setup-{version}-win.exe
    ├── okrbest-desktop-{version}-win-x64.msi
    ├── okrbest-desktop-{version}-mac-x64.dmg
    ├── okrbest-desktop-{version}-mac-arm64.dmg
    ├── okrbest-desktop-{version}-mac-universal.dmg
    ├── okrbest-desktop-{version}-linux-x64.tar.gz
    ├── okrbest-desktop-{version}-linux-arm64.tar.gz
    ├── okrbest-desktop_{version}-1_x64.deb
    └── ...
```

---

## 6. 테스트

### 6.1 코드 검증

```bash
# 전체 검증 (린트 + 타입체크 + 유닛테스트)
npm run check

# 개별 검증
npm run lint:js          # ESLint 실행
npm run lint:js-quiet    # 조용한 모드
npm run fix:js           # 자동 수정
npm run check-types      # TypeScript 타입 체크
npm run check-build-config # 빌드 설정 검증
```

### 6.2 유닛 테스트

```bash
# 유닛 테스트 실행
npm run test:unit

# 커버리지 포함
npm run test:unit-coverage
```

### 6.3 E2E 테스트

```bash
# E2E 테스트 실행 (빌드 필요)
npm run e2e
```

### 6.4 수동 테스트 체크리스트

#### Windows
- [ ] 앱 정상 실행
- [ ] 설치 프로그램 정상 작동
- [ ] 자동 업데이트 확인 (설정된 경우)
- [ ] 프로토콜 핸들러 (`okrbest://`) 작동
- [ ] 트레이 아이콘 표시
- [ ] 알림 정상 작동

#### macOS
- [ ] 앱 정상 실행
- [ ] DMG 마운트 및 설치
- [ ] 코드 서명 확인 (`spctl --assess --verbose`)
- [ ] 자동 업데이트 확인
- [ ] 프로토콜 핸들러 작동
- [ ] 메뉴바 아이콘 표시

#### Linux
- [ ] 앱 정상 실행
- [ ] DEB/RPM 패키지 설치
- [ ] AppImage 실행
- [ ] 데스크톱 파일 생성 확인
- [ ] 프로토콜 핸들러 등록 확인

---

## 7. 배포

### 7.1 버전 관리

#### 버전 업데이트

```bash
# package.json에서 버전 수정
# 또는 스크립트 사용 (release.sh 참고)
```

#### Git 태그 생성

```bash
git tag -a "v{version}" -m "Desktop Version {version}"
git push origin "v{version}"
```

### 7.2 자동 업데이트 서버 설정

#### 업데이트 서버 구조

```
https://releases.okrbest.com/desktop/
├── latest.yml              # Windows 최신 버전 정보
├── latest-mac.yml          # macOS 최신 버전 정보
├── latest-linux.yml        # Linux 최신 버전 정보
└── {version}/
    ├── okrbest-desktop-{version}-win-x64.zip
    ├── okrbest-desktop-{version}-mac-x64.dmg
    └── ...
```

#### 업데이트 파일 생성

빌드 후 `latest.yml` 파일이 자동 생성됩니다. 이를 업데이트 서버에 업로드해야 합니다.

```bash
# 스크립트를 사용하여 업데이트 파일 패치
bash scripts/patch_updater_yml.sh

# 아티팩트 복사
bash scripts/cp_artifacts.sh release ./build/linux
```

### 7.3 배포 프로세스

#### 1. 빌드 및 패키징

```bash
# 프로덕션 빌드
npm run build-prod-upgrade

# 플랫폼별 패키징
npm run package:windows
npm run package:mac-with-universal
npm run package:linux-appImage
```

#### 2. 업데이트 파일 생성

```bash
# 업데이트 YAML 파일 패치
bash scripts/patch_updater_yml.sh
```

#### 3. 업데이트 서버 업로드

```bash
# 업데이트 서버에 파일 업로드
# 방법 1: S3, GitHub Releases, 또는 자체 서버
# 방법 2: electron-builder의 publish 기능 사용

# electron-builder.json에서 publish 설정 확인
# publish:never로 설정되어 있으면 수동 업로드 필요
```

#### 4. 릴리스 노트 작성

```bash
# 릴리스 노트 생성 (스크립트 사용 가능)
bash scripts/generate_release_markdown.sh
bash scripts/generate_release_post.sh
```

#### 5. GitHub Releases (선택)

```bash
# GitHub CLI 사용
gh release create v{version} \
  release/{version}/*.zip \
  release/{version}/*.dmg \
  release/{version}/*.deb \
  --title "v{version}" \
  --notes-file RELEASE_NOTES.md
```

### 7.4 CI/CD 파이프라인

#### GitHub Actions 예시

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build-prod-upgrade
      - run: npm run package:${{ matrix.package }}
      - uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.os }}-builds
          path: release/
```

### 7.5 배포 체크리스트

- [ ] 버전 번호 업데이트
- [ ] 변경 이력 업데이트 (CHANGELOG.md)
- [ ] 프로덕션 빌드 성공
- [ ] 모든 플랫폼 패키징 완료
- [ ] 코드 서명 완료 (Windows, macOS)
- [ ] 업데이트 파일 생성 및 업로드
- [ ] 업데이트 서버 설정 확인
- [ ] 릴리스 노트 작성
- [ ] Git 태그 생성 및 푸시
- [ ] 배포 후 테스트 (자동 업데이트 확인)

---

## 8. 트러블슈팅

### 8.1 빌드 오류

#### 네이티브 모듈 빌드 실패

```bash
# 의존성 재설치
npm run clean-install

# 또는
rm -rf node_modules package-lock.json
npm install
```

#### 메모리 부족

```bash
# Node.js 메모리 제한 증가
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build-prod
```

### 8.2 패키징 오류

#### Windows 코드 서명 실패

- 인증서 경로 확인
- 인증서 비밀번호 확인
- 인증서 유효기간 확인

#### macOS 코드 서명 실패

```bash
# 인증서 확인
security find-identity -v -p codesigning

# 프로비저닝 프로파일 확인
security cms -D -i mac.provisionProfile
```

#### Linux 패키지 빌드 실패

- 빌드 도구 설치 확인
- 크로스 컴파일러 설정 확인 (arm64 빌드 시)

### 8.3 자동 업데이트 문제

#### 업데이트 파일 형식 오류

- `latest.yml` 파일 형식 확인
- 파일 경로 및 URL 확인
- 서버 CORS 설정 확인

#### 업데이트 다운로드 실패

- 네트워크 연결 확인
- 서버 접근성 확인
- 파일 권한 확인

### 8.4 일반적인 문제

#### 빌드 캐시 문제

```bash
# 빌드 산출물 정리
npm run clean

# 또는 수동으로
rm -rf dist/ release/ node_modules/
npm install
```

#### 타입 오류

```bash
# TypeScript 타입 체크
npm run check-types

# 타입 정의 파일 확인
ls -la node_modules/@types/
```

#### 의존성 충돌

```bash
# 의존성 트리 확인
npm ls

# 특정 패키지 확인
npm ls <package-name>
```

---

## 부록: 주요 명령어 참조

### 개발 명령어

| 명령어 | 설명 |
|--------|------|
| `npm run build` | 개발 빌드 |
| `npm run start` | 앱 실행 |
| `npm run watch` | 파일 변경 감시 모드 |
| `npm run check` | 코드 검증 (린트 + 타입 + 테스트) |

### 빌드 명령어

| 명령어 | 설명 |
|--------|------|
| `npm run build-prod` | 프로덕션 빌드 |
| `npm run build-prod-upgrade` | 자동 업데이트 포함 빌드 |
| `npm run build-prod-mas` | Mac App Store 빌드 |

### 패키징 명령어

| 명령어 | 설명 |
|--------|------|
| `npm run package` | 전체 플랫폼 패키징 |
| `npm run package:windows` | Windows 패키징 |
| `npm run package:mac` | macOS 패키징 |
| `npm run package:linux` | Linux 패키징 |

### 유틸리티 명령어

| 명령어 | 설명 |
|--------|------|
| `npm run clean` | 빌드 산출물 정리 |
| `npm run clean-install` | 완전 재설치 |
| `npm run lint:js` | ESLint 실행 |
| `npm run fix:js` | ESLint 자동 수정 |
| `npm run test:unit` | 유닛 테스트 |
| `npm run e2e` | E2E 테스트 |

---

## 참고 자료

- [Electron 공식 문서](https://www.electronjs.org/docs)
- [electron-builder 문서](https://www.electron.build/)
- [Node.js 공식 문서](https://nodejs.org/docs)
- [프로젝트 README](../README.md)
- [리브랜딩 가이드](./REBRAND.md)

---

*문서 작성일: 2026-01-04*

