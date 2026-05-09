# 배포 환경 설정 가이드

OKRBEST Desktop (Electron) 앱을 빌드·서명·공증·배포하기 위해 필요한 모든 환경 변수, 시크릿, 인증서, 계정, 설정 파일을 항목별로 정리한 체크리스트다. 신규 메인테이너가 GitHub Secrets를 새로 구성하거나 로컬에서 릴리즈 빌드를 재현할 때 참고하기 위함이다.

참고 소스: [electron-builder.ts](../electron-builder.ts), [.github/workflows/](../.github/workflows/), [scripts/](../scripts/), [webpack.config.base.js](../webpack.config.base.js), [APPLE_DEVELOPER_ACCOUNT_SETUP.md](APPLE_DEVELOPER_ACCOUNT_SETUP.md), [Certum-SimplySign.md](Certum-SimplySign.md), [CI_CD.md](CI_CD.md)

---

## 1. macOS 일반 배포 (Developer ID — DMG/ZIP, 자동업데이트용)

Apple Developer Program 멤버십($99/년)이 필요하다. 상세 가이드는 [APPLE_DEVELOPER_ACCOUNT_SETUP.md](APPLE_DEVELOPER_ACCOUNT_SETUP.md) 참고.

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` | Developer ID Application 인증서 (.p12, base64) |
| `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` | 위 .p12 비밀번호 |
| `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` | DMG용 provisioning profile (base64, 선택) |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` | App Store Connect API Key ID (notarization 공유) |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` | API Key 본문 (.p8 raw) |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` | API Issuer ID |

Entitlements: [resources/mac/entitlements.mac.plist](../resources/mac/entitlements.mac.plist), [resources/mac/entitlements.mac.inherit.plist](../resources/mac/entitlements.mac.inherit.plist)

소비 워크플로: [release.yaml](../.github/workflows/release.yaml), [build-for-pr.yml](../.github/workflows/build-for-pr.yml), [nightly-main.yml](../.github/workflows/nightly-main.yml)

---

## 2. Mac App Store (MAS) 배포

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` | Mac App Distribution 인증서 (.p12, base64) |
| `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` | 위 .p12 비밀번호 |
| `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` | MAS provisioning profile (base64) |

위 1번의 App Store Connect API Key 시크릿도 함께 필요(업로드/공증).

Entitlements: [resources/mac/entitlements.mas.plist](../resources/mac/entitlements.mas.plist), [resources/mac/entitlements.mas.inherit.plist](../resources/mac/entitlements.mas.inherit.plist)

빌드 명령: `npm run package:mas` → `build-prod-mas` + `electron-builder --mac mas --universal`. 빌드 시 `IS_MAC_APP_STORE=true` 환경변수 필요.

소비 워크플로:
- [release-mas.yaml](../.github/workflows/release-mas.yaml) — 태그 `v*-mas.*` 또는 `v*-rc.*` 푸시 시 실제 MAS 빌드/업로드
- [nightly-main.yml](../.github/workflows/nightly-main.yml) — `mac-app-store-preflight` job이 nightly에서 MAS 빌드 가능 여부를 사전 검증 (업로드는 하지 않음)

---

## 3. Windows 코드 서명 (Certum)

`electron-builder.ts`에서 `win.sign = false`로 두고, [scripts/certum-sign.ps1](../scripts/certum-sign.ps1)이 빌드 후 `release/win*-unpacked/*.exe`와 `release/*.msi`를 외부 서명한다. 상세: [Certum-SimplySign.md](Certum-SimplySign.md).

| GitHub Secret | 용도 |
|---|---|
| `CERTUM_OTP_URI` | Certum 코드 서명 OTP seed (TOTP) |
| `CERTUM_USERID` | Certum 계정 사용자 ID |

조건부 실행: `if: ${{ secrets.CERTUM_OTP_URI != '' && secrets.CERTUM_USERID != '' }}` — 시크릿 미설정 시 서명 단계를 자동으로 건너뛴다.

산출물: x64/ARM64용 zip + MSI. GPO 템플릿(adml/admx) 동봉.

소비 워크플로: [release.yaml](../.github/workflows/release.yaml), [build-for-pr.yml](../.github/workflows/build-for-pr.yml), [nightly-main.yml](../.github/workflows/nightly-main.yml), [nightly-rainforest.yml](../.github/workflows/nightly-rainforest.yml)

---

## 4. Linux 배포

별도 시크릿 없음. 산출물: tar.gz, deb, rpm, AppImage, Flatpak.

Flatpak 빌드 환경변수(선택, 기본값 있음):
- `FLATPAK_BASE_VERSION` (기본 `25.08`)
- `FLATPAK_RUNTIME_VERSION` (기본 `25.08`)

[scripts/afterpack.js](../scripts/afterpack.js)에서 chrome-sandbox 권한 설정.

---

## 5. 자동 업데이트 / S3 배포

정식 릴리즈 경로는 OIDC 기반 AWS 인증을 사용하고, nightly 경로는 별도의 정적 IAM 사용자 키를 사용한다 — **두 자격 증명 쌍을 모두 준비해야 한다.**

### 5-1. 정식 릴리즈 (OIDC)

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | OIDC로 assume할 IAM Role ARN |
| `OKRBEST_DESKTOP_RELEASE_BUCKET` | 정식 릴리즈 아티팩트 업로드 대상 S3 버킷 |

[release.yaml](../.github/workflows/release.yaml)은 `id-token: write` 퍼미션과 `aws-actions/configure-aws-credentials`의 `role-to-assume` 입력으로 OIDC 인증을 수행한다. [scripts/generate_latest_version.sh](../scripts/generate_latest_version.sh)가 `latest.txt` / `latest-rc.txt` / `latest-mas.txt`를 생성하여 `s3://{RELEASE_BUCKET}/desktop/`에 업로드한다.

### 5-2. Nightly 빌드 (정적 IAM 키)

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | nightly 업로드용 IAM 사용자 Access Key ID |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | nightly 업로드용 IAM 사용자 Secret Access Key |

[nightly-rainforest.yml:144-145](../.github/workflows/nightly-rainforest.yml)에서 정적 키로 인증한 뒤, 빌드 산출물을 `s3://okrbest-desktop-daily-builds/`에 업로드한다. **버킷 이름은 워크플로에 하드코딩되어 있으므로** 변경 시 YAML을 직접 수정해야 한다. 이 경로는 `OKRBEST_DESKTOP_RELEASE_BUCKET` 시크릿을 사용하지 않는다.

---

## 6. GitHub 릴리즈 & 알림

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_BUILD_GH_TOKEN` | `gh release create`로 draft Release 생성 |
| `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL` | 릴리즈 시작/완료 시 Mattermost 알림 |
| `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL` | nightly 빌드 완료 알림 |

릴리즈 노트 생성: [scripts/generate_release_markdown.sh](../scripts/generate_release_markdown.sh)

릴리즈 플로우: `release-X.Y` 브랜치 → `scripts/release.sh start|rc|pre-final|final|patch` → 태그 푸시 → 워크플로 트리거.

---

## 6-1. Repository Variables (Git Identity)

`run-release-script` 워크플로가 [scripts/release.sh](../scripts/release.sh)를 실행하며 커밋을 생성할 때 사용하는 Git 작성자 정보다. **Secrets가 아니라 Repository Variables**로 등록한다 — GitHub에서 Settings → Secrets and variables → Actions → **Variables** 탭 → New repository variable.

| Variable 이름 | 용도 |
|---|---|
| `UNIFIED_CI_USERNAME` | `git config user.name` 값 (예: `okrbest-ci`) |
| `UNIFIED_CI_EMAIL` | `git config user.email` 값 (예: `ci@okrbest.com`) |

소비 워크플로: [run-release-script.yml:50-51](../.github/workflows/run-release-script.yml#L50-L51)

설정하지 않으면 해당 워크플로의 Git commit이 빈 저자 정보로 생성되거나 실패한다.

---

## 7. 빌드 타임 컴파일 상수 (webpack DefinePlugin)

[webpack.config.base.js](../webpack.config.base.js)에서 환경변수 → 전역 상수로 주입한다.

| 환경변수 | 전역 상수 | 용도 |
|---|---|---|
| `OKRBEST_DESKTOP_BUILD_SENTRYDSN` | `__SENTRY_DSN__` | Sentry 에러 리포팅 DSN. **현재 어떤 워크플로에서도 주입되지 않음** — CI 빌드에 Sentry를 활성화하려면 해당 워크플로의 빌드 step에 `env:` 블록으로 추가해야 한다 |
| `OKRBEST_DESKTOP_BUILD_SKIPONBOARDINGSCREENS` | `__SKIP_ONBOARDING_SCREENS__` | 온보딩 스킵 (테스트용) |
| `OKRBEST_DESKTOP_BUILD_DISABLEGPU` | `__DISABLE_GPU__` | GPU 가속 비활성화 |
| `IS_MAC_APP_STORE` | `__IS_MAC_APP_STORE__` | MAS 빌드 분기 |
| `NODE_ENV` | — | webpack mode (production/test) |
| `CI_MAC_ZIP_ONLY` | — | CI에서 DMG 생성 스킵 |

신규 추가 시 `package.json`의 jest `globals`에도 동일하게 등록할 것.

---

## 8. E2E 테스트 (배포 필수 아님, CI용)

| GitHub Secret | 용도 |
|---|---|
| `OKRBEST_DESKTOP_E2E_USER_NAME` | 테스트 계정 아이디 |
| `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | 테스트 계정 비밀번호 |
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | 리포트 업로드용 정적 키 (Access Key ID) |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | 리포트 업로드용 정적 키 (Secret Access Key) |
| `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | 테스트 사이클 URL prefix |
| `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | 결과 알림 |
| `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr 테스트 관리 연동 |

---

## 9. 워크플로별 트리거 요약

| 워크플로 | 트리거 | 역할 |
|---|---|---|
| [ci.yaml](../.github/workflows/ci.yaml) | 모든 PR | 서명 없는 zip/tar.gz, lint, 타입체크, 유닛테스트 |
| [build-for-pr.yml](../.github/workflows/build-for-pr.yml) | `Build Apps for PR` 라벨 | 서명된 전체 빌드 (수동 QA용). macOS 서명 + Certum 시크릿 사용 |
| [release.yaml](../.github/workflows/release.yaml) | 태그 `v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?` | 전 플랫폼 서명 빌드, `OKRBEST_DESKTOP_RELEASE_BUCKET` 업로드, draft Release |
| [release-mas.yaml](../.github/workflows/release-mas.yaml) | 태그 `v*-rc.*` 또는 `v*-mas.*` | Mac App Store 빌드 및 업로드 |
| [nightly-builds.yaml](../.github/workflows/nightly-builds.yaml) | cron `0 4 * * 0-5` (일~금 04:00 UTC) + `workflow_dispatch` | nightly 태그 생성 후 `nightly-main`/`nightly-rainforest`를 `workflow_call`로 호출하는 엔트리포인트 |
| [nightly-main.yml](../.github/workflows/nightly-main.yml) | `workflow_call` (from `nightly-builds`) | Linux/Windows/macOS nightly 빌드 + `mac-app-store-preflight` job으로 MAS 빌드 사전 검증 (업로드 없음) |
| [nightly-rainforest.yml](../.github/workflows/nightly-rainforest.yml) | `workflow_call` (from `nightly-builds`) | Rainforest QA용 Windows MSI 등 빌드 후 하드코딩된 `okrbest-desktop-daily-builds` S3 버킷 업로드 |

---

## 10. 사전 준비 체크리스트 (신규 환경 구성 시)

1. Apple Developer Program 가입 — [APPLE_DEVELOPER_ACCOUNT_SETUP.md](APPLE_DEVELOPER_ACCOUNT_SETUP.md) 참고
2. macOS Developer ID Application 인증서 발급 → .p12 export → base64 인코딩
3. App Store Connect API Key (.p8) 발급 → Key ID / Issuer ID 기록
4. (MAS) Mac App Distribution 인증서 + MAS provisioning profile 준비
5. Certum 코드 서명 계정 + OTP seed 발급 — [Certum-SimplySign.md](Certum-SimplySign.md) 참고
6. AWS 자격 증명 2종 구성:
   - 정식 릴리즈용: IAM Role + GitHub OIDC trust policy + `OKRBEST_DESKTOP_RELEASE_BUCKET` S3 버킷
   - Nightly용: 별도 IAM 사용자 + 정적 Access/Secret Key + `okrbest-desktop-daily-builds` 버킷 (버킷명 하드코딩)
7. GitHub PAT 발급 (`repo` 권한) → `OKRBEST_DESKTOP_BUILD_GH_TOKEN`
8. Mattermost 알림 채널 webhook URL 2개 (release / nightly)
9. Repository Variables 2개 등록: `UNIFIED_CI_USERNAME`, `UNIFIED_CI_EMAIL` (run-release-script 워크플로의 git identity, §6-1 참고)
10. (선택) Sentry 프로젝트 생성 → DSN 확보
11. 위 모든 시크릿과 variables를 GitHub repository Settings → Secrets and variables → Actions에 등록 (Secrets 탭과 Variables 탭을 구분)

---

## 검증 방법

- 각 시크릿이 실제 워크플로에서 참조되는지: `grep -r "secrets\." .github/workflows/`로 교차 확인
- macOS 서명 상태: `codesign -dv --verbose=4 <app>` / `spctl -a -vvv <app>`
- macOS 공증 상태: `xcrun stapler validate <app>`
- Windows 서명 상태: 우클릭 → 속성 → 디지털 서명 탭, 또는 `signtool verify /pa /v <exe>`
- 자동 업데이트: 빌드 후 S3에 `latest.txt`가 갱신되는지, 구버전 앱이 업데이트를 인식하는지 확인
- 로컬 빌드 재현: `npm run package:mac` / `package:windows` / `package:linux` / `package:mas`
