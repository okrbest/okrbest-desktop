# Certum SimplySign – Windows 코드 서명 가이드

> **기준**: Certum 공식 기술문서 (files.certum.eu, support.certum.eu)  
> **제품**: Standard Code Signing in the Cloud (SimplySign)

---

## 1. 전체 구조

### 1.1 아키텍처

```
GitHub Actions
      ↓
Windows Runner (Hosted 또는 Self-hosted)
      ↓
SimplySign Desktop (가상 스마트카드 에뮬레이터)
      ↓
Windows Certificate Store
      ↓
signtool.exe
      ↓
Certum Cloud HSM (private key 저장)
```

**핵심**: 인증서 private key는 **Certum HSM**에 있고, SimplySign Desktop이 Windows에서 **가상 스마트카드**처럼 인증서를 노출합니다.

### 1.2 필수 구성 요소

| 구성 요소 | 역할 |
|----------|------|
| **SimplySign Mobile** (Android/iOS) | TOTP 생성. 활성화 시 QR 스캔. 운영 정책상 1기기 사용 권장 |
| **SimplySign Desktop** (Windows) | 가상 스마트카드. 클라우드 인증서를 Windows 인증서 저장소에 노출. 로그인 시 TOTP 입력 |
| **Windows SDK (signtool)** | 코드 서명 도구 |

**다운로드**:
- SimplySign Desktop: [support.certum.eu](https://support.certum.eu/en/cert-offer-software-and-libraries/) 또는 [simplysign.certum.eu](https://simplysign.certum.eu/)
- SimplySign Mobile: [Android](https://play.google.com/store/apps/details?id=com.assecods.certum.simplysign) / [iOS](https://itunes.apple.com/pl/app/certum-simplysign/id1244415465)

### 1.3 초보자 빠른 시작 (GitHub Hosted 기준)

아래 순서만 따라 하면 `Self-hosted` 없이도 첫 자동 서명까지 확인할 수 있습니다.

1. Certum에서 `Standard Code Signing in the Cloud` 인증서를 활성화하고 SimplySign Mobile 활성화 완료
2. 활성화 QR 코드를 1Password로 스캔해서 `otpauth://...` URI 확보
3. GitHub 저장소에서 Secrets 등록  
   `Settings -> Secrets and variables -> Actions`
   - `CERTUM_OTP_URI`: `otpauth://totp/...` 전체 URI
   - `CERTUM_USERID`: SimplySign 계정 이메일
4. 워크플로우 실행 (릴리스 태그 푸시 또는 수동 실행)
5. Actions 로그에서 아래 3개 문구 확인
   - `TOTP code generated.`
   - `Using signtool:`
   - `Successfully signed:`
6. 아티팩트 다운로드 후 서명 검증

```powershell
signtool verify /pa path\to\okrbest-desktop.exe
signtool verify /pa path\to\okrbest-desktop.msi
```

> 위 5단계 로그가 없거나 `Failing code signing step`/`No files found matching pattern` 오류가 보이면, 서명이 수행되지 않은 상태입니다.

## 2. 인증서 활성화 (Certum)

Certum에서 **Standard Code Signing in the Cloud** 인증서 구매 후:

1. Certum 계정 로그인: https://www.certum.eu
2. **My Account → Data security products → Activate certificate**
3. 인증자 정보 입력, 조직/개인 인증, Key pair 생성, 인증서 발급
4. Certum에서 **3통 이메일** 발송:
   - Secret code (활성화 코드)
   - Activation link (활성화 링크)
   - Welcome email

Cloud 인증서는 **키가 SimplySign cloud의 가상 암호 카드에 저장**됩니다.

---

## 3. SimplySign 활성화

### 3.1 공식 절차 (Certum 매뉴얼 기준)

1. 활성화 링크 이메일에서 링크 클릭
2. 웹 페이지에서 **QR 코드** 표시
3. **SimplySign Mobile** 앱으로 QR 코드 스캔
4. 이메일의 **Secret code** 입력
5. SimplySign 계정 활성화 완료 → TOTP 생성 가능

### 3.2 TOTP 자동화용 otpauth URI 추출

QR 코드에는 표준 **`otpauth://totp/...`** URI가 포함되어 있습니다.  
SimplySign Mobile 대신 **1Password** 등 TOTP 지원 앱으로 스캔하면 URI를 추출할 수 있습니다.

**추출 방법**:
1. 활성화 웹 페이지의 QR 코드를 **1Password**로 스캔
2. 1Password에서 해당 항목 **편집** → `otpauth://totp/...?secret=...&period=30` URI 확인/복사
3. GitHub Secrets 등에 `CERTUM_OTP_URI`로 등록

> SimplySign Mobile으로만 스캔하면 URI 추출이 어렵습니다. CI 자동화 시 1Password 사용을 권장합니다.  
> 참고: [Certum SimplySign 자동화 가이드](https://www.devas.life/how-to-automate-signing-your-windows-app-with-certum/)

---

## 4. SimplySign Desktop 사용

### 4.1 설치

- [support.certum.eu](https://support.certum.eu/en/cert-offer-software-and-libraries/)에서 Windows용 SimplySign Desktop 다운로드
- 설치 후 트레이 아이콘 표시

### 4.2 로그인 (공식 매뉴얼)

1. 트레이 아이콘 우클릭 → **Connect to SimplySign**
2. **Username** (이메일) + **Token** (SimplySign Mobile에서 생성한 TOTP 6자리) 입력
3. 로그인 성공 시 가상 카드/인증서가 Windows 인증서 저장소에 노출

### 4.3 인증서 확인

```powershell
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
```

---

## 5. signtool 서명

### 5.1 설치

- [Windows SDK](https://developer.microsoft.com/windows/downloads/windows-sdk) 설치
- **Signing Tools for Desktop Apps** 선택
- 예: `C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe`

### 5.2 서명 명령

**Timestamp 서버**: `http://time.certum.pl` (Certum 공식 문서 명시)

**Certum 공식 예시** (thumbprint 지정):

```powershell
signtool sign /sha1 "<thumbprint>" /tr http://time.certum.pl /td sha256 /fd sha256 /v "myapp.exe"
```

thumbprint는 SimplySign Desktop → Manage certificates → 인증서 Details → Thumbprint에서 확인합니다.

**대안** (인증서 자동 선택):

```powershell
signtool sign /fd SHA256 /tr http://time.certum.pl /td SHA256 /a myapp.exe
```

| 옵션 | 의미 |
|------|------|
| /sha1 | 인증서 thumbprint (공식 예시) |
| /fd | 파일 해시 알고리즘 |
| /tr | Timestamp 서버 URL |
| /td | Timestamp 해시 알고리즘 |
| /a | 인증서 자동 선택 (편의용) |

### 5.3 검증

```powershell
signtool verify /pa myapp.exe
```

---

## 6. Runner 환경: Hosted vs Self-hosted

### 6.1 비교

| 방식 | TOTP | 동작 |
|------|------|------|
| **GitHub Hosted** (windows-2022) | 매 빌드마다 필요 | `certum-sign.ps1`로 TOTP 자동 생성·입력 후 서명 |
| **Self-hosted Windows Runner** | 세션당 1회 | SimplySign Desktop 로그인 세션 유지 중일 때 TOTP 없이 서명 가능 (세션 만료·재연결 시 재인증 필요) |

### 6.2 GitHub Hosted (TOTP 자동화)

- `certum-sign.ps1`가 `CERTUM_OTP_URI`에서 TOTP 생성
- SimplySign Desktop 창에 TOTP 자동 입력 (SendKeys)
- 매 빌드마다 설치·로그인·서명 수행
- 현재 스크립트는 `CERTUM_USERID`를 UI에 자동 입력하지 않고, 값 존재 여부만 확인
- **장점**: 별도 Runner 불필요  
- **단점**: UI 자동화 의존, 빌드 시간 증가

### 6.3 Self-hosted Runner (로그인 유지)

- Runner 서버에 SimplySign Desktop **로그인 세션 유지**
- 로그인 세션이 유효한 동안 CI 실행 시 TOTP 없이 서명 가능 (세션 만료·재연결 시 재인증 필요)
- **장점**: 안정적, 빠름  
- **단점**: 전용 Windows 서버 필요

---

## 7. CI/CD 설정 (OKRBEST Desktop)

### 7.1 필요한 GitHub Secrets

| Secret | 용도 |
|--------|------|
| `CERTUM_OTP_URI` | `otpauth://totp/...?secret=...&period=30` 전체 URI |
| `CERTUM_USERID` | SimplySign 계정 이메일 |

> 현재 워크플로우 조건식은 `CERTUM_OTP_URI`와 `CERTUM_USERID`를 모두 검사합니다.  
> 두 Secret 중 하나라도 없으면 서명 단계는 실행되지 않습니다.

### 7.2 TOTP 파라미터

| 항목 | 값 | 비고 |
|------|-----|------|
| period | 30 | RFC 6238 표준 |
| algorithm | SHA1 또는 SHA256 | otpauth URI의 `algorithm` 파라미터. certum-sign.ps1가 자동 인식 |
| 인증서 만료 | 365일 | 만료 60일 전부터 갱신 가능 |
| otpauth URI | 만료 없음 | 인증서 갱신 시에도 동일 URI 유지 |

### 7.3 certum-sign.ps1 흐름

```
1. SimplySign Desktop 설치 (없는 경우)
2. CERTUM_OTP_URI에서 TOTP 코드 자동 생성
3. SimplySign Desktop 실행 → TOTP 자동 입력 (SendKeys)
4. signtool.exe로 .exe/.msi 서명 (timestamp: http://time.certum.pl)
```

### 7.4 첫 실행 성공 판정 (초보자용)

실행 후 아래를 순서대로 확인합니다.

1. Actions 로그에 경고가 없는지 확인
   - 실패 신호: `CERTUM_OTP_URI not set. Failing code signing step.`
   - 실패 신호: `CERTUM_USERID not set. Failing code signing step.`
2. 로그에서 `Successfully signed:`가 `.exe`, `.msi` 각각 1회 이상 출력되는지 확인
3. 아티팩트 다운로드 후 로컬에서 검증

```powershell
signtool verify /pa .\okrbest-desktop-*.exe
signtool verify /pa .\okrbest-desktop-*.msi
```

4. Windows 파일 속성 -> `디지털 서명` 탭에서 `OKRBEST Inc.` 인증서 확인

---

## 8. 실무 권장 사항

### 8.1 Best Practice

- **Dedicated Windows Signing Server** + Self-hosted Runner
- SimplySign Desktop 로그인 유지
- 코드 서명 인증서 = 회사 identity → 보안 관리 중요

### 8.2 인증서 갱신

- 갱신 권장: 만료 **14일 전** (추가 비용 방지)
- 갱신 시 SimplySign 계정·TOTP(otpauth URI) 그대로 사용 가능
- [Certum 인증서 갱신 가이드](https://support.certum.eu/en/how-to-renew-code-signing/)

### 8.3 자주 발생하는 문제

| 문제 | 원인 | 해결 |
|------|------|------|
| 인증서 없음 | GitHub Hosted에서 SimplySign 미로그인 | TOTP 자동화 또는 Self-hosted 사용 |
| SimplySign 로그인 실패 | TOTP 만료(30초) | certum-sign.ps1가 실행 직전 생성 |
| 워크플로우 서명 단계 실패 | `CERTUM_USERID`/`CERTUM_OTP_URI` 누락 또는 파일 패턴 불일치 | 두 Secret 모두 등록, 산출물 경로 확인 후 재실행 |
| SmartScreen 경고 | Timestamp 없음 | `/tr http://time.certum.pl` 사용 |

---

## 9. 참고 자료

| 문서 | URL |
|------|-----|
| Certum Code Signing 매뉴얼 (활성화) | [files.certum.eu](https://files.certum.eu/documents/manual_en/CS-Standard_Code_Signing_in_the_cloud_Certificate_activation.pdf) |
| Certum Code Signing 매뉴얼 (signtool/jarsigner) | [files.certum.eu](https://files.certum.eu/documents/manual_en/CS-Code_Signing_in_the_Cloud_Signtool_jarsigner_signing.pdf) |
| SimplySign 소프트웨어 다운로드 | [support.certum.eu](https://support.certum.eu/en/cert-offer-software-and-libraries/) |
| TOTP 자동화 가이드 | [devas.life](https://www.devas.life/how-to-automate-signing-your-windows-app-with-certum/) |

---

*문서 작성일: 2026-03-04 (Certum 공식 문서 기준 정리)*
