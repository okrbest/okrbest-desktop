# Apple 개발자 계정 작업 가이드 (macOS 초보자용)

> 이 문서는 **개인 Apple 개발자 계정(유료 가입 완료)** 상태에서, OKR Best Desktop 빌드에 필요한 Apple 관련 작업을 처음부터 끝까지 수행하는 방법을 설명합니다.

---

## 0. 이 문서로 완료되는 것

이 문서를 끝까지 따라 하면 아래를 완료합니다.

1. Apple Developer 포털에서 팀/권한 상태 확인
2. Developer ID Application 인증서 발급
3. `.p12` 인증서 파일 생성
4. App Store Connect API Key(`.p8`) 생성
5. GitHub Actions Secrets 등록
6. 워크플로우 실행으로 서명/노터리 정상 동작 확인

---

## 1. 먼저 알아둘 핵심

### 1.1 개인 계정이면 팀을 새로 만들 필요가 있나요?

아니요. 개인 유료 가입을 완료했다면 보통 **개인 Team이 이미 존재**합니다.

- 개인 Team으로도 Developer ID 인증서 발급 가능
- 회사 팀이 필요한 경우만 Organization 전환/신규 등록 진행

### 1.2 이 저장소에서 실제로 쓰는 Apple 관련 Secret

`Repository Settings -> Secrets and variables -> Actions`에 등록합니다.

#### Developer ID (macOS 설치형 빌드)

- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD`
- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK`
- `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE`

참고 워크플로우: [release.yaml](../.github/workflows/release.yaml), [build-for-pr.yml](../.github/workflows/build-for-pr.yml), [nightly-main.yml](../.github/workflows/nightly-main.yml), [nightly-rainforest.yml](../.github/workflows/nightly-rainforest.yml)

#### Notarization / MAS 공통 API Key

- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID`
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY`
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID`

#### MAS 전용

- `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE`
- `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_KEY_PASSWORD`
- `OKRBEST_DESKTOP_MAC_APP_STORE_CSC_LINK`

---

## 2. 사전 준비물

### 2.1 계정/권한

- Apple Developer Program 유료 가입 완료
- Apple ID 2단계 인증(2FA) 활성화
- `developer.apple.com` 로그인 가능

### 2.2 로컬(Mac)

- Keychain Access(키체인 접근) 실행 가능
- 터미널 사용 가능
- 보안 저장용 폴더 1개 생성 권장

예시:

```bash
mkdir -p ~/secure/apple-signing
chmod 700 ~/secure/apple-signing
```

---

## 3. Apple 포털에서 팀/권한 확인

1. `https://developer.apple.com/account` 접속
2. 로그인 후 우상단 프로필/팀 표시 확인
3. 팀이 여러 개라면 현재 사용할 Team 선택
4. `Membership` 페이지에서 상태 확인

체크 포인트:

- Program 상태가 Active인지
- Team Name / Team ID 확인
- 개인 계정이면 본인이 사실상 Account Holder 역할

### 3.1 Bundle ID(App ID) 준비 확인

처음 설정하는 계정이라면 앱 식별자도 같이 점검해야 합니다.

이 프로젝트 기준 권장 Bundle ID:

- `com.OKRBest.Desktop` (macOS)

확인/생성 순서:

1. `https://developer.apple.com/account/resources/identifiers/list` 이동
2. `Identifiers` 우측 상단 `+` 클릭
3. `App IDs` 선택 -> `Continue`
4. `App` 선택 -> `Continue`
5. Description 입력 (예: `OKR Best Desktop`)
6. Bundle ID 선택
- `Explicit` 선택
- 값 입력: `com.OKRBest.Desktop`
7. Capabilities 기본값 유지(초기에는 최소 설정 권장)
8. `Continue` -> `Register`

주의:

- Bundle ID를 나중에 바꾸면 인증서/프로파일/배포 설정이 연쇄적으로 깨질 수 있습니다.
- 이미 운영 중이면 기존 Bundle ID와 완전히 일치시켜야 합니다.

### 3.2 Developer ID와 MAS의 차이 (헷갈림 방지)

- **Developer ID Application**: 웹 배포(DMG/ZIP)용 코드서명
- **MAS( Mac App Store )**: App Store 제출용 별도 인증서/프로파일 체계

즉, Developer ID 발급과 MAS 준비는 별도 작업입니다.

---

## 4. CSR 생성 (Keychain Access)

Developer ID 인증서 발급 전에 CSR 파일을 만듭니다.

1. `Command + Space` -> `키체인 접근` 검색 후 실행
2. 왼쪽에서 `로그인` 선택
3. 상단 메뉴바에서 `키체인 접근` -> `인증서 지원` -> `인증 기관에서 인증서 요청...`
4. 팝업 입력

- User Email Address: Apple ID 이메일
- Common Name: 식별 가능한 이름 (예: `OKRBest Mac Signing`)
- CA Email Address: 비워도 됨
- `디스크에 저장(Saved to disk)` 선택

5. `계속` -> `.certSigningRequest` 저장

권장 저장 위치:

```text
~/secure/apple-signing/okrbest-developer-id.csr
```

---

## 5. Developer ID Application 인증서 발급

1. `https://developer.apple.com/account/resources/certificates/list` 이동
2. `Certificates` 우측 상단 `+` 클릭
3. 유형에서 `Developer ID Application` 선택
4. `Continue`
5. `Choose File`로 CSR 업로드
6. `Continue`
7. `Download`로 `.cer` 파일 저장

권장 파일명:

```text
DeveloperID_Application_OKRBest.cer
```

---

## 6. 인증서 설치 + p12 내보내기

### 6.1 설치

1. `.cer` 파일 더블클릭
2. Keychain Access 열리면 왼쪽 `로그인`, 상단 `내 인증서` 선택
3. `Developer ID Application: ...` 항목 확인
4. 항목 왼쪽 화살표를 펼쳐 **개인키(키 아이콘)** 함께 있는지 확인

중요:

- 인증서만 있고 개인키가 없으면 `.p12` 내보내기 실패
- CSR을 만든 **같은 Mac 사용자 계정**에서 설치/내보내기 해야 안전

### 6.2 p12 내보내기

1. `Developer ID Application: ...` 항목 우클릭
2. `내보내기...`
3. 포맷: `Personal Information Exchange (.p12)`
4. 파일 저장 + 암호 설정

권장:

- 파일: `~/secure/apple-signing/DeveloperID_Application_OKRBest.p12`
- 암호: 강한 암호 (이 값이 `CSC_KEY_PASSWORD`)

---

## 7. App Store Connect API Key(.p8) 생성

노터리/일부 배포 단계에 사용됩니다.

1. `https://appstoreconnect.apple.com` 로그인
2. `Users and Access` 클릭
3. 상단 `Integrations` 탭 클릭
4. `App Store Connect API`에서 `Team Keys` 선택
5. `+` 클릭하여 새 Key 생성
6. 이름 입력 (예: `OKRBest-Desktop-Notary`)
7. 권한(Role) 선택 (`App Manager` 이상 권장)
8. `Generate`
9. 생성 직후 `.p8` 다운로드 (재다운로드 불가)

기록할 값 3개:

- Key ID
- Issuer ID
- `.p8` 파일 내용

권장 저장:

```text
~/secure/apple-signing/AuthKey_<KEYID>.p8
```

---

## 8. GitHub Secrets 등록 (초보자용 클릭 순서)

1. GitHub 저장소 열기
2. `Settings`
3. 왼쪽 `Secrets and variables` -> `Actions`
4. `New repository secret`
5. `Name` / `Secret` 입력 후 저장

### 8.1 Developer ID 인증서(p12) 등록

#### A) p12를 Base64 문자열로 변환

```bash
cd ~/secure/apple-signing
base64 -i DeveloperID_Application_OKRBest.p12 | tr -d '\n' > csc_link_base64.txt
```

`csc_link_base64.txt` 내용을 복사해서 아래 Secret에 넣습니다.

- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_LINK` = Base64 문자열
- `OKRBEST_DESKTOP_MAC_INSTALLER_CSC_KEY_PASSWORD` = p12 내보낼 때 설정한 암호

### 8.2 Apple API Key 등록

- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY_ID` = Key ID
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_ISSUER_ID` = Issuer ID
- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY` = `.p8` 파일 텍스트 원문

주의:

- `OKRBEST_DESKTOP_MAC_APP_STORE_MACOS_API_KEY`는 **Base64가 아니라 .p8 원문 텍스트**를 넣어야 합니다.
- 워크플로우가 이 값을 그대로 `./key.p8` 파일로 씁니다.

### 8.3 프로비저닝 프로파일 등록

이 저장소 워크플로우는 현재 `MAC_PROFILE`/`MAS_PROFILE`를 복원하는 단계를 포함합니다.

#### 먼저: 프로파일 파일 구하기

##### A) MAS 프로파일(`mas.provisionprofile`) 생성

1. `https://developer.apple.com/account/resources/profiles/list` 이동
2. `Profiles` 우측 상단 `+` 클릭
3. `Distribution` -> `Mac App Store` 선택 -> `Continue`
4. App ID에서 `com.OKRBest.Desktop` 선택
5. 배포 인증서(MAS용) 선택
6. Profile Name 입력 (예: `OKRBest MAS Profile`)
7. `Generate` -> `Download`

##### B) DMG 프로파일(`mac.provisionprofile`) 관련

- 일반적으로 Developer ID 배포(DMG/ZIP)는 별도 provisioning profile이 필수가 아닙니다.
- 다만 이 저장소 워크플로우는 `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE`를 복원하는 단계를 포함합니다.
- 따라서 현재 운영 중인 값이 있으면 **기존 프로파일을 그대로 재사용**하는 방식이 가장 안전합니다.
- 신규 생성이 필요한 경우, 프로젝트 운영자와 정책(실제로 필요한지, 어떤 타입을 쓰는지)을 먼저 확정한 뒤 진행하세요.

#### Developer ID용 DMG 프로파일

```bash
base64 -i mac.provisionprofile | tr -d '\n'
```

- 결과값 -> `OKRBEST_DESKTOP_MAC_INSTALLER_DMG_PROFILE`

#### MAS용 프로파일

```bash
base64 -i mas.provisionprofile | tr -d '\n'
```

- 결과값 -> `OKRBEST_DESKTOP_MAC_APP_STORE_MAS_PROFILE`

---

## 9. 로컬 상태 점검 명령어

### 9.1 코드서명 인증서 인식 확인

```bash
security find-identity -v -p codesigning
```

정상 예시(유사 문구):

```text
Developer ID Application: <Your Name or Org>
```

### 9.2 Keychain에서 인증서/개인키 페어 확인

- 키체인 접근 -> 로그인 -> 내 인증서
- `Developer ID Application` 항목 아래에 키 아이콘이 있어야 함

---

## 10. GitHub Actions 검증 순서

### 10.1 가장 안전한 검증 순서

1. PR 생성
2. PR에 `Build Apps for PR` 라벨 추가
3. `build-for-pr.yml` 실행 확인
4. macOS build job 로그에서 서명/패키징 성공 확인

### 10.2 정식/나이틀리 검증

- `nightly-main.yml` 또는 릴리스 태그 기반 `release.yaml` 실행
- macOS job 성공 + artifacts 생성 + 업로드 성공 확인

---

## 11. 자주 발생하는 문제와 해결

### 11.1 "No identity found" / 서명 인증서를 못 찾음

원인:

- 인증서 설치는 됐지만 개인키 없음
- 다른 Mac/다른 사용자 계정에서 CSR 생성

해결:

- CSR 생성한 동일 계정에서 다시 발급/설치
- 내 인증서에서 개인키 포함 여부 확인

### 11.2 `CSC_LINK` 관련 오류

원인:

- Base64 문자열에 줄바꿈/공백 포함
- 잘못된 p12 파일 업로드

해결:

- `tr -d '\n'`로 한 줄 문자열 생성
- p12 재내보내기 후 다시 등록

### 11.3 API Key 관련 노터리 실패

원인:

- Key ID/Issuer ID/키 내용 불일치
- `.p8` 내용이 손상(복사 중 누락)

해결:

- 3개 값을 같은 키 세트로 재입력
- `.p8` 전체 원문(헤더/본문/푸터) 재복사

### 11.4 프로비저닝 프로파일 디코드 실패

원인:

- Base64 값 누락
- 잘못된 프로파일 파일

해결:

- 원본 파일로 다시 Base64 생성 후 Secret 업데이트

---

## 12. 보안 운영 수칙 (중요)

1. 인증서 원본 파일(.p12/.p8)은 Git에 절대 커밋 금지
2. 로컬 보안 폴더(`~/secure/apple-signing`) 권한 제한 유지
3. 팀원 공유는 Secret Manager(1Password/Vault)로만 전달
4. 인력 변경 시 인증서/키 폐기 및 재발급
5. 만료 30일 전 갱신 일정 등록

---

## 13. 운영 체크리스트

### 최초 1회

- [ ] 개인 Team/멤버십 Active 확인
- [ ] CSR 생성
- [ ] Developer ID Application 발급
- [ ] p12 내보내기 + 암호 생성
- [ ] App Store Connect API Key 발급(.p8)
- [ ] GitHub Secrets 등록
- [ ] PR 빌드로 macOS 서명 검증

### 정기 점검(월 1회 권장)

- [ ] 인증서 만료일 확인
- [ ] API Key 접근 권한 검토
- [ ] Actions 실패 로그에서 서명 관련 경고 확인

---

## 14. 참고 문서

- [CI/CD 가이드](./CI_CD.md)
- [개발 환경 설정](./DEVELOPMENT_SETUP.md)
- Apple Developer: https://developer.apple.com
- App Store Connect: https://appstoreconnect.apple.com
