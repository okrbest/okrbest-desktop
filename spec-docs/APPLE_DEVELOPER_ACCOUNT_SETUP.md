# Apple 개발자 계정 작업 가이드 (macOS 초보자용)

> 이 문서는 **개인 Apple 개발자 계정(유료 가입 완료)** 상태에서, OKR Best Desktop 빌드에 필요한 Apple 관련 작업을 처음부터 끝까지 수행하는 방법을 설명합니다. 2026-04 기준 Apple Developer Portal / App Store Connect UI와 이 저장소 코드 기준값에 맞춰 작성되었습니다.

---

## 0. 이 문서로 완료되는 것

이 문서를 끝까지 따라 하면 아래가 완료됩니다.

1. Apple Developer 포털에서 팀/권한 상태 확인 + Team ID 확인
2. App ID(`OKRBest.Desktop`) 등록
3. 인증서 3종 발급: Developer ID Application, Developer ID Installer, Mac App Distribution
4. `.p12` 인증서 파일 2개 생성 (Developer ID용 1개 + MAS용 1개)
5. App Store Connect API Key(`.p8`) 생성
6. MAS provisioning profile 생성
7. GitHub Actions Secrets 등록 (9개)
8. 워크플로우 실행으로 서명/노터리/MAS 제출 정상 동작 확인

---

## 1. 먼저 알아둘 핵심

### 1.1 개인 계정이면 팀을 새로 만들 필요가 있나요?

아니요. 개인 유료 가입을 완료했다면 보통 **개인 Team이 이미 존재**합니다.

- 개인 Team으로도 Developer ID/MAS 인증서 발급 모두 가능.
- 회사 팀이 필요한 경우만 Organization 전환/신규 등록을 진행하세요.

### 1.2 이 저장소가 쓰는 인증서 3종 개요

이 프로젝트는 **두 가지 배포 경로**를 지원하므로, 서로 다른 인증서 3종이 필요합니다.

| 인증서 | 용도 | 배포 경로 | 들어갈 `.p12` |
|--------|------|---------|--------------|
| **Developer ID Application** | DMG/ZIP의 `.app` 서명 | 외부 배포 (웹사이트 다운로드) | Developer ID용 `.p12` (Installer와 같은 파일) |
| **Developer ID Installer** | DMG/PKG 인스톨러 서명 | 외부 배포 | Developer ID용 `.p12` (Application과 같은 파일) |
| **Mac App Distribution** | MAS 제출용 `.app` 서명 | Mac App Store | MAS용 `.p12` (별도) |

**실무 팁**: Developer ID Application + Installer 두 인증서를 Keychain에서 **동시에 선택해 하나의 `.p12`로 export**하면 GitHub Secret 한 개(`OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK`)로 둘 다 커버됩니다. MAS용은 별도 `.p12`.

### 1.3 이 저장소가 쓰는 GitHub Secret 목록

`Repository Settings → Secrets and variables → Actions`에 등록합니다.

**Developer ID (외부 배포 / DMG)**
- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` — Developer ID App+Installer `.p12` base64
- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` — 위 `.p12` 암호
- `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` — 선택 (9.2 참조)

**MAS (Mac App Store)**
- `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` — Mac App Distribution `.p12` base64
- `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` — 위 `.p12` 암호
- `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` — MAS `.provisionprofile` base64

**공통 (notarization / App Store Connect API)**
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID`
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` — `.p8` 텍스트 원문
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID`

참고 워크플로: [release.yaml](../.github/workflows/release.yaml), [release-mas.yaml](../.github/workflows/release-mas.yaml), [build-for-pr.yml](../.github/workflows/build-for-pr.yml), [nightly-main.yml](../.github/workflows/nightly-main.yml), [nightly-rainforest.yml](../.github/workflows/nightly-rainforest.yml)

---

## 2. 사전 준비물

### 2.1 계정/권한

- Apple Developer Program 유료 가입 완료
- Apple ID 2단계 인증(2FA) 활성화
- `developer.apple.com` 로그인 가능
- Account Holder 또는 Admin 역할 (Developer ID/Distribution 인증서 발급은 이 역할만 가능)

### 2.2 로컬(Mac)

- Keychain Access(`/Applications/Utilities/Keychain Access.app`) 실행 가능
- 터미널 사용 가능
- 보안 저장용 폴더 1개 생성 권장:
  ```bash
  mkdir -p ~/secure/apple-signing
  chmod 700 ~/secure/apple-signing
  ```

---

## 3. 팀/권한 확인 + App ID 등록

### 3.1 Team ID 확인 — ⚠️ 가장 먼저 확인

이 저장소의 [resources/mac/entitlements.mas.plist:25,28,30](../resources/mac/entitlements.mas.plist)에 Team ID **`72EQ97MVJ8`**이 하드코딩되어 있습니다. 이 값이 **여러분의 Apple Team ID와 반드시 같아야** MAS 서명이 통과됩니다.

**Team ID 확인 방법:**

1. `https://developer.apple.com/account` 접속
2. 좌측 메뉴의 `Membership Details` (이전 명칭: `Membership`) 클릭
3. `Team ID` 필드의 10자 영숫자 값 확인 (예: `ABCDE12345`)

**Team ID가 `72EQ97MVJ8`과 같으면**: 건드릴 것 없음. 다음 단계로 진행.

**다르면**: 아래 파일의 `72EQ97MVJ8`을 실제 Team ID로 치환한 뒤 커밋합니다.

```bash
# 저장소 루트에서
grep -rn 72EQ97MVJ8 resources/ src/ electron-builder.ts 2>/dev/null
# → 현재는 resources/mac/entitlements.mas.plist 3군데만 해당
# 실제 Team ID로 교체 (macOS sed 기준)
sed -i '' 's/72EQ97MVJ8/<YOUR_TEAM_ID>/g' resources/mac/entitlements.mas.plist
```

치환 후 반드시 diff 확인. 이 값이 틀리면 나중에 codesign 단계에서 *"The executable was signed with invalid entitlements"* 등으로 실패합니다.

### 3.2 App ID 등록

> **이 프로젝트의 macOS Bundle ID는 `OKRBest.Desktop`입니다** ([electron-builder.ts:25](../electron-builder.ts#L25), [resources/mac/entitlements.mas.plist:28](../resources/mac/entitlements.mas.plist#L28)).
> `com.OKRBest.Desktop`은 Linux 전용 오버라이드이므로 혼동하지 마세요.

등록 순서 (2026-04 기준 공식 UI):

1. `https://developer.apple.com/account/resources` 접속 → `Certificates, Identifiers & Profiles`로 이동
2. 좌측 사이드바에서 `Identifiers` 클릭
3. 우상단 `+` 버튼 클릭
4. `App IDs` 선택 → `Continue`
5. Type 선택 화면에서 `App` 선택 → `Continue`
6. `Description` 입력 (예: `OKR Best Desktop`)
7. **Bundle ID** 섹션에서 `Explicit` 선택, 값 입력: **`OKRBest.Desktop`**
8. **Capabilities** 체크박스 활성화 — App ID 포털에서 켜야 하는 건 다음 2개뿐입니다:
   - **App groups** *(체크만 함 — `Configure` 버튼은 누르지 말 것. 이유는 3.3 참조)*
   - **Communication Notifications**

   > **왜 App Sandbox와 Hardened Runtime은 여기 없는가**: 이 두 가지는 App ID 포털이 아니라 빌드 설정 / entitlements 파일에서 관리됩니다. 이미 [electron-builder.ts:132](../electron-builder.ts#L132)의 `hardenedRuntime: true`와 [resources/mac/entitlements.mas.plist:21-22](../resources/mac/entitlements.mas.plist#L21-L22)의 `com.apple.security.app-sandbox` 키로 자동 적용되므로 추가 조치 불필요. Apple 공식 문서도 *"The App Sandbox entitlement does not have an Xcode checkbox"*라고 명시하고 있고, 포털 체크박스도 존재하지 않습니다.
   >
   > `com.apple.security.device.*`, `.network.*`, `.files.*` 같은 entitlement들은 App Sandbox의 하위 리소스 옵션이라 포털에 별도 체크박스가 없고 entitlements 파일에서만 관리됩니다. `com.apple.security.cs.allow-jit` 역시 Hardened Runtime의 하위 옵션이라 entitlements에서만 관리됩니다.
9. `Continue` → 요약 확인 → `Register`

### 3.3 App Group 처리 — 포털 등록 안 함 (macOS 전통 스타일)

[resources/mac/entitlements.mas.plist:25](../resources/mac/entitlements.mas.plist#L25)가 참조하는 `72EQ97MVJ8.OKRBest.Desktop`은 **macOS 전통 스타일 App Group**(Team ID prefix 방식)입니다. Apple 공식 문서:

> *"On macOS App Groups are not mediated by the developer web site and don't need to be allowlisted by a provisioning profile. For this reason, group IDs must be prefixed by your Team ID."*

즉 이 스타일은 Team ID prefix 자체가 격리 경계 역할을 하므로 **포털 등록/프로비저닝 프로파일 연결이 모두 불필요**합니다.

**해야 할 것**:
- 3.2 단계 8에서 **App groups capability 체크박스만 켜두기** (켜둔 상태로 `Continue` → `Register`).

**하지 말아야 할 것**:
- ❌ `Identifiers` → 드롭다운을 `App Groups`로 바꿔서 새 그룹을 **만들지 말 것**. 현 포털 UI는 iOS 스타일(`group.*`)만 받으므로 `72EQ97MVJ8.OKRBest.Desktop` 입력 시 자동으로 `group.72EQ97MVJ8.OKRBest.Desktop`으로 접두사가 붙어버려 entitlements와 일치하지 않습니다.
- ❌ App ID의 `Capabilities` 행에서 `App groups`의 **`Configure` 버튼을 누르지 말 것**. 이 버튼은 iOS 스타일 그룹을 선택하는 용도라 macOS 전통 스타일에선 의미가 없고 오히려 빈 목록이 저장돼 혼란을 일으킵니다.

**entitlements 파일 수정도 불필요** — `72EQ97MVJ8.OKRBest.Desktop` 그대로 유지합니다(3.1에서 Team ID를 바꿨으면 새 Team ID로 치환된 값을 유지).

> 향후 iOS 앱 / Mac Catalyst 앱과 App Group을 공유할 필요가 생기면 iOS 스타일(`group.com.okrbest.shared` 등)로 마이그레이션이 필요합니다. 그땐 포털에 App Group을 정식 등록하고 `Configure`로 연결해야 합니다. 현 데스크톱 단독 구성에선 전통 스타일 그대로가 맞습니다.

---

## 4. CSR 생성 (Keychain Access)

Apple 인증서 발급 전 CSR 파일을 만듭니다.

> ⚠️ **CSR은 인증서마다 따로 만들어야 합니다.** Apple 공식 문서: *"A unique CSR is required for each certificate."* 동일 CSR을 다시 업로드하면 *"The uploaded CSR file has already been used to generate another certificate"* 에러가 납니다. 특히 Developer ID Application과 Developer ID Installer는 서로 다른 public key를 요구합니다. 따라서 이 프로젝트 기준으로 **CSR을 총 3번 생성**해야 합니다 (5장·6장·7장용). CSR을 만든 동일 Mac 사용자 계정의 로그인 키체인에서만 개인키에 접근 가능함도 기억하세요.
>
> (예외: 기존 **같은 종류** 인증서를 갱신할 때는 이전 CSR 재사용 가능.)

각 인증서 발급 직전에 아래 단계를 **한 번씩** 수행하세요.

1. `Command + Space` → `키체인 접근` 실행 (영문 메뉴: `Keychain Access`)
2. 상단 메뉴바: `키체인 접근` → `인증서 지원` → `인증 기관에서 인증서 요청...`
   (영문: `Keychain Access` → `Certificate Assistant` → `Request a Certificate from a Certificate Authority...`)
3. 팝업 입력:
   - **사용자 이메일 주소** / User Email Address: Apple ID 이메일
   - **일반 이름** / Common Name: 식별용 이름. **CSR마다 다른 값 권장** — 예: `OKRBest DevID App`, `OKRBest DevID Installer`, `OKRBest MAS Distribution`
   - **CA 이메일 주소** / CA Email Address: 비워둠
   - **요청 방식**: `디스크에 저장` (Saved to disk)
4. `계속` → `.certSigningRequest` 저장 — 파일명에 용도를 명시하면 혼동을 줄일 수 있습니다:
   ```text
   ~/secure/apple-signing/okrbest-devid-app.certSigningRequest       # 5장에서 사용
   ~/secure/apple-signing/okrbest-devid-installer.certSigningRequest # 6장에서 사용
   ~/secure/apple-signing/okrbest-mas.certSigningRequest             # 7장에서 사용
   ```
   필요 시점마다 이 단계를 재실행해 해당 CSR을 만들면 됩니다. 모두 미리 만들어 두고 순서대로 업로드해도 됩니다.

---

## 5. Developer ID Application 인증서 발급

1. `https://developer.apple.com/account/resources` → `Certificates, Identifiers & Profiles`
2. 좌측 사이드바 `Certificates` 클릭
3. 우상단 `+` 클릭
4. 현재 포털은 모든 인증서 타입이 라디오 버튼 평탄 목록으로 나옵니다. `Software` 섹션에서 **`Developer ID Application`**을 직접 선택 → `Continue`
   > 구버전 UI(2023년 이전)에서는 `Software` → `Developer ID` → `Continue` → Application/Installer 중 선택이라는 2단계였지만, 현재 UI에서는 단일 단계입니다. 포털 렌더링에 따라 2단계로 보일 수 있는데, 그 경우 상위에서 `Developer ID`를 고른 뒤 하위에서 `Developer ID Application`을 고르면 됩니다.
5. (`G2 Sub-CA (Xcode 11.4.1 or later)` 옵션이 보이면 기본값 그대로 → `Continue`)
6. `Choose File`로 4장에서 만든 **`okrbest-devid-app.certSigningRequest`** 업로드 → `Continue`
7. `Download`로 `.cer` 파일 저장

권장 저장 파일명:
```text
~/secure/apple-signing/DeveloperID_Application_OKRBest.cer
```

8. 다운로드한 `.cer` 더블클릭 → Keychain Access에 설치됨
9. Keychain Access → 왼쪽 `로그인` → 상단 `내 인증서` → `Developer ID Application: ...` 항목 왼쪽 ▶를 펼쳐 **개인키(키 아이콘)가 함께 있는지 확인**

---

## 6. Developer ID Installer 인증서 발급

DMG/PKG 인스톨러 서명에 필요합니다.

> ⚠️ Developer ID Application 발급에 쓴 CSR은 **재사용할 수 없습니다**. 4장을 다시 실행해 **새 CSR**(`okrbest-devid-installer.certSigningRequest`)을 먼저 만드세요. 재사용 시 포털이 *"The uploaded CSR file has already been used to generate another certificate"* 에러를 냅니다.

1. `Certificates` → `+`
2. `Software` 섹션에서 **`Developer ID Installer`** 선택 → `Continue`
   > (구버전 UI가 나오면 `Developer ID` → `Continue` → `Developer ID Installer` 2단계)
3. 새로 만든 **`okrbest-devid-installer.certSigningRequest`** 업로드 → `Download` → 설치

권장 파일명:
```text
~/secure/apple-signing/DeveloperID_Installer_OKRBest.cer
```

설치 후 Keychain Access의 `내 인증서`에 **두 인증서(Application + Installer)가 모두 개인키와 함께 있는지 확인**.

### 6.1 Developer ID용 `.p12` export (두 인증서를 한 파일로)

1. Keychain Access → `로그인` → `내 인증서`
2. `Developer ID Application: ...` 와 `Developer ID Installer: ...` **두 항목을 Cmd-클릭으로 동시 선택**
3. 우클릭 → `내보내기 2개 항목... (Export 2 items...)`
4. 포맷: `개인 정보 교환(.p12)` (Personal Information Exchange)
5. 저장:
   ```text
   ~/secure/apple-signing/DeveloperID_OKRBest.p12
   ```
6. **암호 설정** — 이 값이 `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` 시크릿이 됩니다. 강한 암호 사용.

---

## 7. Mac App Distribution 인증서 발급 (MAS용)

MAS 제출용 `.app` 서명에 필요합니다.

> ⚠️ 5·6장에서 쓴 CSR은 **재사용할 수 없습니다**. 4장을 다시 실행해 **세 번째 CSR**(`okrbest-mas.certSigningRequest`)을 만드세요.

1. `Certificates` → `+`
2. `Software` 섹션에서 **`Mac App Distribution`** 선택 → `Continue`
3. 새로 만든 **`okrbest-mas.certSigningRequest`** 업로드 → `Download` → 설치

권장 파일명:
```text
~/secure/apple-signing/MacAppDistribution_OKRBest.cer
```

> **참고**: 최근 포털에는 "Apple Distribution"이라는 iOS/macOS 통합 인증서 옵션도 있지만, `electron-builder`의 `mas` 타깃이 내부적으로 `3rd Party Mac Developer Application:`로 시작하는 인증서 subject를 기대하므로 **MAS 전용 `Mac App Distribution`을 쓰는 쪽이 안전**합니다. (Apple Distribution으로도 동작하지만 일부 빌드 로직에서 오판 여지가 있음.)

### 7.1 MAS용 `.p12` export

1. Keychain Access → `내 인증서` → `3rd Party Mac Developer Application: ...` 항목 (위에서 설치된 것) 우클릭
2. `내보내기...`
3. 포맷: `.p12`
4. 저장:
   ```text
   ~/secure/apple-signing/MAS_Distribution_OKRBest.p12
   ```
5. 암호 설정 — `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD`로 사용될 값.

> MAS 인스톨러(`.pkg`) 서명을 위한 별도 `Mac Installer Distribution` 인증서는 **이 프로젝트에서는 필요 없습니다** — `electron-builder`가 `mas` 타깃에서 pkg 생성 시 자동으로 productbuild 쪽 서명을 처리하며, 추가 인스톨러 인증서를 요구하지 않는 구성입니다. 혹시 향후 빌드 로그에 *"No 3rd Party Mac Developer Installer certificate"* 경고가 뜨면 그때 추가 발급하세요.

---

## 8. App Store Connect API Key(.p8) 생성

notarization 및 MAS 업로드(fastlane) 공통으로 사용됩니다.

1. `https://appstoreconnect.apple.com` 로그인
2. `Users and Access` 클릭
3. 상단 탭에서 **`Integrations`** 선택
4. 좌측에서 **`Team Keys`** 선택 (Individual Keys 아님 — CI 용도는 Team Keys)
5. `Generate API Key` 또는 `+` 클릭
6. `Name`: `OKRBest-Desktop-CI` 등
7. **`Access`**: `App Manager` 이상 (notarization만 쓸 거라면 `Developer`도 가능하나 MAS 업로드까지 쓰려면 App Manager 권장)
8. `Generate`
9. **생성 직후 `.p8` 즉시 다운로드** (재다운로드 불가)

저장:
```text
~/secure/apple-signing/AuthKey_<KEYID>.p8
```

**기록할 값 3개:**
- **Key ID** (목록의 10자 영숫자)
- **Issuer ID** (Team Keys 페이지 상단 UUID 형태)
- **`.p8` 파일 텍스트 원문** (`-----BEGIN PRIVATE KEY-----`부터 `-----END PRIVATE KEY-----`까지 전체)

---

## 9. Provisioning Profile 생성

### 9.1 MAS용 Provisioning Profile (필수)

1. `https://developer.apple.com/account/resources/profiles/list` 이동
2. 우상단 `+` 클릭
3. `Distribution` 그룹에서 **`Mac App Store`** 선택 → `Continue`
4. **App ID**에서 3.2에서 만든 `OKRBest.Desktop` 선택 → `Continue`
5. **Certificate**에서 7장에서 만든 `Mac App Distribution` 인증서 선택 → `Continue`
6. **Profile Name**: `OKRBest MAS Profile` 등
7. `Generate` → `Download`

저장:
```text
~/secure/apple-signing/mas.provisionprofile
```

### 9.2 DMG용 Provisioning Profile 정책

이 저장소 워크플로는 `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` 시크릿을 항상 `base64 -D`로 디코드해 `./mac.provisionprofile`로 씁니다 ([nightly-main.yml:189](../.github/workflows/nightly-main.yml#L189), [release.yaml:166](../.github/workflows/release.yaml#L166) 등).

하지만:
- [electron-builder.ts](../electron-builder.ts)의 `mac` 블록은 `provisioningProfile` 필드를 **사용하지 않습니다** (`mas` 블록만 사용). 즉 `./mac.provisionprofile` 파일은 **실제로 codesign/electron-builder에 전달되지 않습니다**.
- 또한 **Developer ID 외부 배포는 provisioning profile이 원래 필수가 아닙니다** (Apple 정책).

**권장 처리**:
- **A (가장 간단)**: 시크릿을 등록하지 않고 비워둠. 워크플로의 `echo $MAC_PROFILE | base64 -D > ./mac.provisionprofile`이 빈 파일을 만드는데, electron-builder가 이 파일을 참조하지 않으므로 무해.
- **B (결벽적)**: 워크플로에서 해당 디코드 스텝을 삭제. 단 여러 워크플로를 건드려야 하므로 별도 커밋 필요.

당장은 **A로 진행**해도 빌드가 통과합니다.

---

## 10. GitHub Secrets 등록

1. GitHub 저장소 → `Settings` → 왼쪽 `Secrets and variables` → `Actions`
2. `New repository secret` 클릭 → 이름/값 입력 → `Add secret`

### 10.1 `.p12` 파일을 base64 문자열로 변환

```bash
cd ~/secure/apple-signing

# Developer ID용 (App + Installer 합본)
base64 -i DeveloperID_OKRBest.p12 | tr -d '\n' | pbcopy
# → 클립보드에 있는 값을 OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK에 붙여넣기

# MAS용
base64 -i MAS_Distribution_OKRBest.p12 | tr -d '\n' | pbcopy
# → OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK
```

`pbcopy` 대신 파일로 저장하고 싶으면 `> csc_link.txt`처럼 리다이렉트하세요.

### 10.2 Provisioning Profile base64 변환

```bash
base64 -i mas.provisionprofile | tr -d '\n' | pbcopy
# → OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE
```

DMG profile은 9.2 권장안 A에 따라 등록 생략.

### 10.3 최종 시크릿 체크리스트

Settings → Secrets and variables → Actions에서:

- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` — Developer ID `.p12` base64
- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` — 6.1에서 설정한 암호
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK` — MAS `.p12` base64
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD` — 7.1에서 설정한 암호
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE` — MAS profile base64
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` — 8장 Key ID
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` — `.p8` **텍스트 원문** (base64 변환 금지)
- [ ] `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` — 8장 Issuer ID
- [ ] `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE` — 9.2 권장안 A면 등록 안 함

> ⚠️ `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY`는 **base64가 아니라 `.p8` 원문 텍스트**를 넣어야 합니다. 워크플로가 이 값을 그대로 `./key.p8` 파일로 씁니다 ([nightly-main.yml:190](../.github/workflows/nightly-main.yml#L190) `zsh -c 'echo -n $APPLE_API_KEY_RAW > ./key.p8'`).

---

## 11. 로컬 상태 점검 명령어

### 11.1 코드서명 인증서 인식 확인

```bash
security find-identity -v -p codesigning
```

정상 출력 예시(3개 모두 보여야 함):
```text
  1) XXXXXXXXXXXX "Developer ID Application: <Your Name> (72EQ97MVJ8)"
  2) YYYYYYYYYYYY "Developer ID Installer: <Your Name> (72EQ97MVJ8)"
  3) ZZZZZZZZZZZZ "3rd Party Mac Developer Application: <Your Name> (72EQ97MVJ8)"
     3 valid identities found
```

Team ID 괄호 부분이 여러분의 실제 Team ID와 일치하는지 확인.

### 11.2 `.p12` 자체 무결성 확인

```bash
openssl pkcs12 -in ~/secure/apple-signing/DeveloperID_OKRBest.p12 -info -noout -passin pass:"<암호>"
```

에러 없이 끝나면 파일 정상.

### 11.3 Provisioning Profile 내용 확인

```bash
security cms -D -i ~/secure/apple-signing/mas.provisionprofile | grep -A1 "AppIDName\|application-identifier\|TeamIdentifier"
```

`application-identifier`가 `<TEAM_ID>.OKRBest.Desktop`이어야 함.

---

## 12. GitHub Actions 검증 순서

### 12.1 가장 안전한 검증 순서 (PR 먼저)

1. 작업 브랜치에 PR 생성
2. PR에 `Build Apps for PR` 라벨 추가
3. [build-for-pr.yml](../.github/workflows/build-for-pr.yml) 실행 확인
4. macOS build job 로그에서 `codesign` / `signing app bundle` 성공 메시지 확인

### 12.2 Nightly / Release 검증

- `workflow_dispatch`로 [nightly-builds.yaml](../.github/workflows/nightly-builds.yaml) 수동 트리거 또는 릴리스 태그로 [release.yaml](../.github/workflows/release.yaml) 실행
- macOS job 성공 + `.dmg` / `.pkg` 산출 + S3 업로드까지 모두 녹색 확인
- Notarization은 비동기이므로 로그에 `Notarization done` 까지 보이는지 체크

---

## 13. 자주 발생하는 문제와 해결

### 13.1 "No identity found" / 서명 인증서를 못 찾음

원인:
- `.p12` 내보내기 시 개인키 누락
- 다른 Mac/다른 macOS 사용자 계정에서 CSR 생성 → 개인키 없는 환경에서 내보내기

해결:
- CSR 생성한 동일 macOS 사용자 계정의 Keychain Access에서 다시 내보내기
- `내 인증서` 목록에서 인증서 펼쳤을 때 키 아이콘이 함께 있는지 확인

### 13.2 `CSC_LINK` 관련 오류 / "not a file"

원인:
- Base64 문자열에 줄바꿈/공백 포함
- 시크릿이 빈 문자열 → electron-builder가 리포 루트로 경로 해석 → `⨯ ... not a file`

해결:
- `base64 -i ... | tr -d '\n'` 로 한 줄 문자열 생성
- 시크릿이 실제로 등록됐는지 GitHub Settings에서 다시 확인 (이름 오타 포함)

### 13.3 "The executable was signed with invalid entitlements" / MAS 검증 실패

원인:
- 3.1의 Team ID 치환 누락: entitlements.mas.plist의 Team ID prefix가 실제 인증서 Team ID와 다름
- App groups capability 체크박스가 꺼져 있음
- (iOS 스타일로 마이그레이션한 경우) 포털의 App Group identifier와 entitlements 값이 불일치

해결:
- `resources/mac/entitlements.mas.plist`의 Team ID 세 군데를 실제 값으로 수정
- App ID → Capabilities → **App groups 체크박스가 켜져 있는지** 확인 (단 `Configure`는 누르지 말 것 — 3.3 참조)

### 13.4 API Key 관련 notarization 실패

원인:
- Key ID / Issuer ID / `.p8` 본문 중 하나가 다른 세트 값
- `.p8` 복사 중 `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` 라인 누락

해결:
- 세 값을 **같은 키에서 한 번에 다시** 복사해 시크릿 재등록
- `.p8` 원문 전체(헤더/본문/푸터/개행 포함) 그대로 붙여넣기

### 13.5 Provisioning Profile 디코드 실패

원인:
- Base64 변환 시 줄바꿈/공백 혼입
- 프로파일 파일이 실제로 `.provisionprofile` 바이너리가 아님(잘못된 파일)

해결:
- 원본 프로파일 파일로 다시 `base64 -i ... | tr -d '\n'` 실행 후 시크릿 갱신
- `security cms -D -i <file>` 로 파일 내용이 유효한 plist인지 검증

---

## 14. 보안 운영 수칙

1. 인증서 원본 파일(`.p12`, `.p8`)은 **Git에 절대 커밋 금지** ([.gitignore:26](../.gitignore#L26)에서 `*.provisionprofile`은 이미 제외됨)
2. `~/secure/apple-signing` 권한을 700으로 유지
3. 팀원 공유는 Secret Manager(1Password, HashiCorp Vault 등)로만
4. 인력 변경 시 관련 인증서·키 즉시 폐기 및 재발급
5. 인증서 만료 **30일 전 갱신** 일정 등록 (Developer ID는 5년, Mac App Distribution은 1년, CA/Browser Forum 규정에 따라 단축될 수 있음)
6. App Store Connect API Key는 **Revoke** 버튼으로 즉시 비활성화 가능 — 유출 의심 시 바로 Revoke 후 재발급

---

## 15. 운영 체크리스트

### 최초 1회

- [ ] Apple Developer Membership Active + Team ID 확인
- [ ] `resources/mac/entitlements.mas.plist`의 Team ID가 실제 값과 일치
- [ ] App ID `OKRBest.Desktop` 등록 + Capabilities 활성화 (App groups 체크만, Configure는 누르지 않음)
- [ ] CSR 3개 생성 (App ID Application / Installer / MAS 각각)
- [ ] Developer ID Application 인증서 발급 및 설치
- [ ] Developer ID Installer 인증서 발급 및 설치
- [ ] Mac App Distribution 인증서 발급 및 설치
- [ ] Developer ID용 `.p12` export (App+Installer 합본)
- [ ] MAS용 `.p12` export
- [ ] App Store Connect API Key(`.p8`) 생성 + Key ID/Issuer ID 기록
- [ ] MAS Provisioning Profile 생성
- [ ] GitHub Secrets 8~9개 등록
- [ ] PR 빌드로 macOS 서명 검증

### 정기 점검 (월 1회 권장)

- [ ] 인증서 만료일 확인 (Keychain Access에서 각 인증서 Info 창)
- [ ] API Key 접근 권한 / 활성 상태 검토
- [ ] Actions 실패 로그에서 `codesign` / `notarization` 관련 경고 확인

---

## 16. 참고 문서

- [CI/CD 가이드](./CI_CD.md)
- [개발 환경 설정](./DEVELOPMENT_SETUP.md)
- [배포 환경 설정](./DEPLOYMENT_ENVIRONMENT_SETUP.md)
- [Certum SimplySign 가이드](./Certum-SimplySign.md) — Windows 코드 서명
- Apple Developer Portal: <https://developer.apple.com>
- App Store Connect: <https://appstoreconnect.apple.com>
- Apple 공식 — [App ID 등록](https://developer.apple.com/help/account/identifiers/register-an-app-id/)
- Apple 공식 — [CSR 생성](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request/)
- Apple 공식 — [Developer ID 인증서 생성](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- Apple 공식 — [App Store Connect API Key 생성](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
