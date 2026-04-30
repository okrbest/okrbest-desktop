# Self-hosted Windows 러너 + Certum SimplySign 영구 세션 구축 가이드

> 이 문서는 **Windows 11 Pro 1대를 GitHub Actions self-hosted 러너로 구축**해 OKR Best Desktop의 nightly Windows 빌드와 Certum SimplySign 코드 서명을 24/7 자동화하는 방법을 처음부터 끝까지 안내합니다. 2026-04 기준 GitHub Actions 호스트 러너에서 SimplySign Desktop GUI 인증이 동작하지 않는 한계를 우회하기 위한 패턴입니다.

## 0. 이 문서로 완료되는 것

1. 24/7 운영되는 Windows 11 Pro 머신 1대 셋업 (자동 로그인, 절전 차단)
2. 빌드 도구 일괄 설치 (Node.js, Visual Studio Build Tools, Windows SDK, Git, Chocolatey)
3. SimplySign Desktop 설치 + 1회 모바일 OTP 인증
4. Task Scheduler 기반 SimplySign 세션 자동 갱신 (매 1시간 50분)
5. GitHub Actions self-hosted runner 등록 + Windows 서비스 영구 실행
6. 워크플로 수정 — Windows 잡을 self-hosted로 라우팅, 서명 스텝 단순화
7. 운영·트러블슈팅·보안 체크리스트

---

## 1. 사전 준비

### 1.1 하드웨어/네트워크

| 항목 | 권장 사양 |
|------|---------|
| OS | Windows 11 Pro (Home은 자동 로그인/Group Policy 제약 있음) |
| CPU | 4코어 이상 (Electron 빌드 + 서명 동시 처리) |
| RAM | 8 GB 이상 (16 GB 권장) |
| 저장소 | SSD 80 GB 이상 (Electron 캐시 + Windows SDK + Node 의존성으로 30~40 GB 사용) |
| 네트워크 | 인터넷 아웃바운드 항시 가능. 인바운드는 차단 가능 (RDP만 VPN 뒤로 권장) |
| 가용성 | 24/7 켜진 상태 (절전 비활성화 필수 — 1.4 참조) |

**호스팅 옵션**:
- 사내 PC 1대 재활용 (가장 저렴, 전기료만)
- 미니 PC 자가 운영 (Intel NUC, MeleQuieter 등; 초기 50~100만원)
- AWS EC2 t3.large Windows / Azure Standard_B2ms (월 5~8만원)

### 1.2 계정/접근 권한

- Windows 머신의 **로컬 관리자 계정** 1개 (이 계정으로 자동 로그인)
- GitHub 저장소 [okrbest/okrbest-desktop](https://github.com/okrbest/okrbest-desktop)의 **Admin 권한** (Settings → Actions → Runners 등록)
- Certum SimplySign **모바일 앱** 설치된 휴대폰 (1회 OTP 입력용)
- 저장소 시크릿 `CERTUM_OTP_URI`, `CERTUM_USERID`에 들어 있는 값(머신에 환경변수로 복사 필요)

### 1.3 보안 사전 검토

이 머신은 **Certum 서명 키에 접근 가능한 인증된 세션을 24시간 유지**합니다. 따라서:

- **다른 용도와 공용하지 말 것** — 서명 전용 머신으로 격리
- BitLocker 디스크 전체 암호화 활성화 (Windows 11 Pro 기본 지원)
- Windows Defender + Windows Update 자동 활성화
- RDP/SSH 외부 노출 금지, VPN 또는 SSH 터널 뒤로
- public 저장소면 **fork PR이 self-hosted 러너에서 실행되지 않도록** [Settings → Actions → Fork pull request workflows](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#hardening-for-self-hosted-runners) 설정 — Require approval for first-time contributors 활성

---

## 2. Windows 11 Pro 초기 셋업

> 이 섹션은 **로컬 관리자 권한 PowerShell**(우클릭 → "관리자 권한으로 실행")에서 진행.

### 2.1 자동 로그인 활성화

자동 로그인이 필요한 이유: SimplySign Desktop GUI 인증을 위한 SendKeys는 **인터랙티브 데스크톱**에서만 동작합니다. 머신이 재부팅되면 사람이 로그인하기 전까지 SendKeys가 작동 안 함 → 세션 갱신 cron도 실패.

**Sysinternals Autologon 사용** (권장):

```powershell
# Autologon 다운로드
$url = 'https://download.sysinternals.com/files/AutoLogon.zip'
Invoke-WebRequest $url -OutFile "$env:TEMP\Autologon.zip"
Expand-Archive "$env:TEMP\Autologon.zip" -DestinationPath "$env:TEMP\Autologon" -Force

# GUI로 실행 (대화형으로 비밀번호 입력)
& "$env:TEMP\Autologon\Autologon64.exe"
```

대화창에서 **Username, Domain, Password** 입력 → `Enable` 클릭. 비밀번호는 LSA에 암호화 저장됨.

> **대안 (CLI 전용)**: 레지스트리 직접 편집 방식도 가능하나 비밀번호가 평문 저장되어 비추천.

### 2.2 절전/슬립/하이버네이션 차단

```powershell
# AC 전원 시 슬립/모니터/하이버네이트 모두 무한대로 (=차단)
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /change disk-timeout-ac 0

# 하이버네이션 자체 비활성 (디스크 hiberfil.sys 제거)
powercfg /hibernate off

# USB 선택적 일시 중단 비활성화 (서명 키 통신용)
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT
```

### 2.3 자동 업데이트 시간 조정

자동 업데이트 후 재부팅이 빌드 중에 일어나면 곤란합니다. **활성 시간(Active Hours)** 을 nightly가 도는 시간을 포함하도록 설정:

`설정 → Windows Update → 고급 옵션 → 활성 시간` → "수동" → 최대 18시간 범위 (예: 06:00 ~ 24:00) — nightly가 매일 04:00 UTC = 13:00 KST에 도므로 활성 시간 안에 들어가도록.

또는 PowerShell:

```powershell
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'ActiveHoursStart' -Value 6
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' `
    -Name 'ActiveHoursEnd' -Value 24
```

### 2.4 PowerShell 7+ 설치

기본 5.1로도 동작하나, 워크플로 호환성 위해 7+ 권장:

```powershell
winget install --id Microsoft.PowerShell --source winget `
    --scope machine --installer-type msi `
    --accept-package-agreements --accept-source-agreements
```

> **주의**: `--scope machine --installer-type msi` 옵션을 **반드시** 명시하세요. 옵션 없이 설치하면 winget이 환경에 따라 **MSIX/사용자 스코프**로 설치할 수 있고, 이 경우 실행파일이 `C:\Users\<user>\AppData\Local\Microsoft\WindowsApps\pwsh.exe` (App Execution Alias) 에만 노출됩니다. 이 별칭은 Task Scheduler 컨텍스트에서 해석되지 않아 4장의 세션 갱신 작업이 `0x80070002 (ERROR_FILE_NOT_FOUND)` 로 실패합니다.

설치 후 검증 — **반드시 다음 경로가 존재해야** 합니다:

```powershell
Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe'   # True 여야 함
pwsh --version                                       # 새 PowerShell 창에서
```

`Test-Path` 가 `False` 면 MSIX로 잘못 설치된 것 — `winget uninstall --id Microsoft.PowerShell` 후 위 명령으로 재설치하세요.

### 2.5 PowerShell ExecutionPolicy 설정

Windows 11의 기본값은 `Restricted` 라 GitHub Actions가 매 스텝마다 생성하는 임시 `.ps1` 스크립트를 실행조차 못 합니다(`UnauthorizedAccess: ... is not digitally signed`). GitHub-hosted 러너 이미지는 미리 풀어놓아서 안 보이던 문제로, self-hosted에서는 **머신에서 1회 영구 설정**해야 합니다.

**관리자 PowerShell**:

```powershell
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
```

확인:

```powershell
Get-ExecutionPolicy -List
# LocalMachine 이 RemoteSigned 로 표시되어야 함
```

> `RemoteSigned`: 로컬 생성된 .ps1(GHA의 `_work\_temp\*.ps1` 포함)은 실행 허용, 인터넷에서 다운로드된 미서명 스크립트는 차단. CI 러너에 적절한 균형. 더 풀어주려면 `Bypass`도 가능하지만 보통 `RemoteSigned`로 충분합니다.

> **러너 등록 전에 반드시 설정**할 것 — 러너 서비스가 시작되고 잡이 들어온 뒤에 정책을 풀면 이미 실패한 잡은 재실행이 필요합니다. 러너 등록(5장) 후에 정책을 바꾸려면 `Restart-Service 'actions.runner.*'` 권장.

### 2.6 Chocolatey 설치 (패키지 매니저)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2.7 빌드 도구 설치

```powershell
# Git
choco install git -y

# Visual Studio Build Tools (C++ 컴파일러 + Windows SDK 포함)
# Electron 네이티브 모듈 빌드에 필요
choco install visualstudio2022buildtools --package-parameters `
    "--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended `
     --add Microsoft.VisualStudio.Component.Windows11SDK.22621" -y

# yq (워크플로의 install-deps 단계가 사용)
choco install yq --version 4.15.1 -y

# jq (워크플로가 package.json 파싱에 사용)
choco install jq -y

# Node.js — 워크플로의 actions/setup-node가 매번 재설치하지만, 초기 검증용으로 설치
# package.json의 engines 섹션과 일치하는 버전 확인 후 설치
choco install nodejs-lts -y

# 모든 설치 후 PATH 갱신을 위해 새 PowerShell 창 열기
```

### 2.8 signtool.exe 위치 확인

Visual Studio Build Tools와 함께 설치된 Windows SDK 안에 있습니다:

```powershell
Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' |
    Sort-Object FullName -Descending | Select-Object -First 1
```

경로 예: `C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe` — 이걸 [scripts/certum-sign.ps1](../scripts/certum-sign.ps1)이 사용합니다.

---

## 3. SimplySign Desktop 설치 및 초기 인증

### 3.1 SimplySign Desktop 설치

**중요**: GHA 호스트 러너에서는 GUI가 안 떠도, 사용자가 직접 RDP로 접속한 머신에서는 정상 GUI가 보입니다. 따라서 **9.4.x 64-bit 최신 버전을 써도 무방**합니다 (오히려 보안/지원 측면에서 권장).

```powershell
# 9.4.2.86 64비트 MSI (필요 시 Certum 서포트 페이지에서 최신 버전 확인)
# https://support.certum.eu/en/cert-offer-software-and-libraries/
$url = 'https://files.certum.eu/software/SimplySignDesktop/Windows/9.4.2.86/SimplySignDesktop-9.4.2.86-64-bit-en.msi'
$msi = "$env:TEMP\SimplySign.msi"
Invoke-WebRequest $url -OutFile $msi
Start-Process msiexec.exe -ArgumentList '/i', "`"$msi`"", '/qn', '/norestart' -Wait -NoNewWindow
```

설치 위치 확인:

```powershell
Get-ChildItem 'C:\Program Files\Certum\SimplySign Desktop\' -Filter '*.exe' -Recurse |
    Select-Object FullName
# 또는 (32비트 MSI 사용 시):
Get-ChildItem 'C:\Program Files (x86)\Certum\SimplySign Desktop\' -Filter '*.exe' -Recurse |
    Select-Object FullName
```

`SimplySignDesktop.exe` 또는 `SimplySign Desktop.exe`가 보여야 정상.

### 3.2 첫 OTP 인증 (사람 작업, 1회만)

이 단계는 **자동화 불가** — Certum의 보안 정책상 모바일 앱 OTP를 1회 입력해야 세션이 시작됩니다.

1. RDP 또는 직접 키보드/모니터로 머신에 로그인
2. 시작 메뉴에서 **"SimplySign Desktop"** 실행 (또는 시스템 트레이 우클릭 → 로그인)
3. 로그인 윈도우 표시:
   - **Username**: `CERTUM_USERID` 시크릿 값 (SimplySign 계정 이메일)
   - **Token**: 휴대폰 SimplySign 앱에서 생성된 6자리 OTP
4. 로그인 성공 → 트레이 아이콘이 활성화되고 Windows 인증서 저장소에 코드 서명 인증서가 주입됨

**중요 — Options 설정 (4장 자동 갱신의 전제조건)**:

로그인 성공 후 트레이 아이콘 우클릭 → **Options** 또는 **Settings** 진입 후 다음 체크박스를 **반드시** 켜주세요:

- ✅ **Show login dialog on SimplySign Desktop startup**
- ✅ Autostart with Windows
- ✅ Remember last logged ID
- ✅ Show login dialog when an application requests access to SimplySign
- ❌ Unregister certificates after disconnecting from SimplySign (꺼두기)
- ✅ Enable PIN cache for CSP/KSP-based applications

**"Show login dialog on SimplySign Desktop startup" 가 꺼져 있으면** 4장의 자동 갱신 스크립트가 SimplySign을 실행해도 로그인 창이 안 뜨고, SendKeys가 활성 윈도우를 못 찾아 `SimplySign Desktop window not found.` 로 실패합니다.

**검증**:

```powershell
# 인증서가 Windows 인증서 저장소에 보이는지 확인
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
# Subject가 'CN=Open Source Developer, ...' 또는 발급된 코드 서명 인증서 라인 출력되어야 함
```

### 3.3 환경변수 설정 (시스템 영구)

**관리자 PowerShell**:

```powershell
# CERTUM_OTP_URI는 GitHub Secret과 동일한 값 (otpauth://totp/... QR URI)
[Environment]::SetEnvironmentVariable('CERTUM_OTP_URI', 'otpauth://totp/...', 'Machine')
[Environment]::SetEnvironmentVariable('CERTUM_USERID', 'you@okr.best', 'Machine')

# 새 PowerShell 창 열어 확인
$env:CERTUM_OTP_URI
$env:CERTUM_USERID
```

> **보안**: 이 머신의 레지스트리에 OTP 시크릿이 저장됩니다. BitLocker 활성화 + 다른 사용자 미허용으로 보호.

---

## 4. SimplySign 세션 자동 갱신

### 4.1 갱신 스크립트 작성

기존 `scripts/certum-sign.ps1`에서 **인증 부분만 추출**한 축약판을 머신에 배치합니다. 다운로드/설치/signtool 호출 코드는 제거 — 이미 설치 완료 + 인증서가 Windows 저장소에 들어 있으므로.

`C:\certum\refresh-session.ps1`:

```powershell
<#
  refresh-session.ps1
  ----------------
  SimplySign Desktop 세션을 갱신해 영구 유지하기 위한 스크립트.
  Task Scheduler에서 매 1시간 50분마다 실행 + 워크플로의 서명 잡 시작 시
  certum-sign-selfhosted.ps1이 즉석 호출.

  설계 원칙 (운영 학습 반영):
    - 시작 시 기존 SimplySignDesktop 인스턴스를 강제 종료한 뒤 새로 띄움.
      이미 떠 있으면 새 로그인 창이 안 뜨고 SendKeys가 미아 → 알려진 실패 모드.
    - 성공 판정은 cert 존재가 아니라 private key SignData 테스트 통과로 격상.
      cert 메타데이터는 세션이 죽어도 store에 캐시처럼 남아 거짓 양성 가능.
    - 따라서 LastTaskResult=0 이면 signtool이 즉시 서명 가능한 상태가 보장된다.

  필요 환경변수: CERTUM_OTP_URI, CERTUM_USERID (시스템 영구 등록 권장)
#>

$ErrorActionPreference = 'Stop'

# 디버깅용 트랜스크립트 (Task Scheduler에서 실패할 때 실제 에러 추적)
Start-Transcript -Path ('C:\certum\refresh-{0:yyyyMMdd-HHmmss}.log' -f (Get-Date)) -Append

$OtpUri = $env:CERTUM_OTP_URI
$UserId = $env:CERTUM_USERID
# Machine 스코프 환경변수가 현재 로그온 세션에 안 박혀 있을 수 있어 레지스트리 폴백
if (-not $OtpUri) { $OtpUri = [Environment]::GetEnvironmentVariable('CERTUM_OTP_URI','Machine') }
if (-not $UserId) { $UserId = [Environment]::GetEnvironmentVariable('CERTUM_USERID','Machine') }
if (-not $OtpUri -or -not $UserId) { throw 'CERTUM_OTP_URI / CERTUM_USERID not set.' }

# === otpauth:// 파싱 ===
$uri = [Uri]$OtpUri
$q = @{}
foreach ($part in $uri.Query.TrimStart('?') -split '&') {
    $kv = $part -split '=', 2
    if ($kv.Count -eq 2) { $q[$kv[0]] = [Uri]::UnescapeDataString($kv[1]) }
}
$Base32 = $q['secret']
$Digits = if ($q['digits']) { [int]$q['digits'] } else { 6 }
$Period = if ($q['period']) { [int]$q['period'] } else { 30 }
$Algorithm = if ($q['algorithm']) { $q['algorithm'].ToUpper() } else { 'SHA1' }

# === TOTP 생성기 ===
Add-Type -Language CSharp @'
using System;
using System.Security.Cryptography;
public static class Totp {
    private const string B32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private static byte[] Base32Decode(string s) {
        s = s.TrimEnd('=').ToUpperInvariant();
        int byteCount = s.Length * 5 / 8;
        byte[] bytes = new byte[byteCount];
        int bitBuffer = 0, bitsLeft = 0, idx = 0;
        foreach (char c in s) {
            int val = B32.IndexOf(c);
            if (val < 0) throw new ArgumentException("Invalid Base32 char: " + c);
            bitBuffer = (bitBuffer << 5) | val;
            bitsLeft += 5;
            if (bitsLeft >= 8) {
                bytes[idx++] = (byte)(bitBuffer >> (bitsLeft - 8));
                bitsLeft -= 8;
            }
        }
        return bytes;
    }
    public static string Now(string secret, int digits, int period, string algorithm) {
        byte[] key = Base32Decode(secret);
        long counter = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / period;
        byte[] cnt = BitConverter.GetBytes(counter);
        if (BitConverter.IsLittleEndian) Array.Reverse(cnt);
        byte[] hash = (algorithm == "SHA256")
            ? new HMACSHA256(key).ComputeHash(cnt)
            : new HMACSHA1(key).ComputeHash(cnt);
        int offset = hash[hash.Length - 1] & 0x0F;
        int binary = ((hash[offset] & 0x7F) << 24) | ((hash[offset + 1] & 0xFF) << 16) |
                     ((hash[offset + 2] & 0xFF) << 8) | (hash[offset + 3] & 0xFF);
        int otp = binary % (int)Math.Pow(10, digits);
        return otp.ToString(new string('0', digits));
    }
}
'@

$otp = [Totp]::Now($Base32, $Digits, $Period, $Algorithm)

# === SimplySign Desktop 실행 + 로그인 ===
$exe = Get-ChildItem -Path 'C:\Program Files\Certum\SimplySign Desktop',
                          'C:\Program Files (x86)\Certum\SimplySign Desktop' `
                          -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue |
       Where-Object { $_.Name -in 'SimplySignDesktop.exe', 'SimplySign Desktop.exe' } |
       Select-Object -First 1

if (-not $exe) { throw 'SimplySign Desktop executable not found.' }

# 기존 SimplySignDesktop 인스턴스 강제 종료 — 안 그러면 새 로그인 창이 안 떠
# SendKeys 가 미아가 됨 (알려진 실패 모드).
Get-Process SimplySignDesktop -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$proc = Start-Process -FilePath $exe.FullName -PassThru
Start-Sleep -Seconds 5

$wshell = New-Object -ComObject WScript.Shell

# 윈도우 활성화 (사람이 로그인된 인터랙티브 데스크톱에서는 동작)
$titleCandidates = @(
    'SimplySign Desktop', 'proCertum SmartSign SimplySign Desktop',
    'proCertum SmartSign', 'SmartSign', 'Start SimplySign', 'SimplySign'
)
$focused = $false
for ($i = 0; -not $focused -and $i -lt 30; $i++) {
    if ($wshell.AppActivate([int]$proc.Id)) { $focused = $true; break }
    foreach ($t in $titleCandidates) {
        if ($wshell.AppActivate($t)) { $focused = $true; break }
    }
    Start-Sleep -Milliseconds 500
}
if (-not $focused) { throw 'SimplySign Desktop window not found.' }

Start-Sleep -Milliseconds 500
$wshell.SendKeys('^a')
Start-Sleep -Milliseconds 200
$wshell.SendKeys($UserId)
Start-Sleep -Milliseconds 150
$wshell.SendKeys('{TAB}')
Start-Sleep -Milliseconds 150
$wshell.SendKeys($otp)
Start-Sleep -Milliseconds 150
$wshell.SendKeys('{ENTER}')

# private key 실접근(SignData)까지 통과해야 성공 — cert 존재만으론 거짓 양성 가능.
# CNG 키(SimplySign 가상 스마트카드는 CNG/KSP)에 대응하기 위해
# RSACertificateExtensions.GetRSAPrivateKey 사용 ($cert.PrivateKey 는 CNG에서 null).
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
            Select-Object -First 1
    if ($cert) {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
        if ($rsa) {
            try {
                [void]$rsa.SignData([byte[]](1..32), 'SHA256', 'Pkcs1')
                Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] SimplySign session refreshed and private key verified. Subject: $($cert.Subject)"
                return
            } catch {
                # 키 핸들은 잡혔는데 SignData 시 throw — KSP 인증 미완. 계속 폴링.
            }
        }
    }
    Start-Sleep -Seconds 1
}
throw 'Session refresh did not produce a working private key (signtool-ready) within 30s.'
```

### 4.2 Task Scheduler 등록

**관리자 PowerShell**:

```powershell
# 폴더 생성
New-Item -ItemType Directory -Path 'C:\certum' -Force | Out-Null
# refresh-session.ps1 파일을 C:\certum\refresh-session.ps1 에 저장 (위 내용 복사)

# 매 1시간 50분마다 실행하는 스케줄 작업 (2시간 세션 만료 직전 갱신)
# pwsh.exe는 절대경로로 — Task Scheduler는 App Execution Alias(WindowsApps\pwsh.exe)를 해석 못 함
$pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (-not (Test-Path $pwsh)) { throw "$pwsh not found. 2.4 단계의 MSI 설치 확인 필요." }

$action = New-ScheduledTaskAction -Execute $pwsh `
    -Argument '-ExecutionPolicy Bypass -NoProfile -File C:\certum\refresh-session.ps1' `
    -WorkingDirectory 'C:\certum'

# 시작 시 1회 + 그 이후 110분마다 반복
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 110) `
    -RepetitionDuration ([TimeSpan]::FromDays(3650))

# 로그인된 사용자로 인터랙티브 실행 (SendKeys 필수)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName 'CertumSessionRefresh' `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings

# 로그온 시에도 한 번 실행 (재부팅 후 즉시 세션 시작)
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$task = Get-ScheduledTask -TaskName 'CertumSessionRefresh'
$task.Triggers += $logonTrigger
Set-ScheduledTask -InputObject $task

# 즉시 한 번 돌려서 검증
Start-ScheduledTask -TaskName 'CertumSessionRefresh'
```

**확인**:

```powershell
# 작업 상태
Get-ScheduledTask -TaskName 'CertumSessionRefresh' | Get-ScheduledTaskInfo

# 마지막 실행 결과 (0 = 정상)
(Get-ScheduledTask -TaskName 'CertumSessionRefresh' | Get-ScheduledTaskInfo).LastTaskResult
```

`LastTaskResult`가 `0` 이고 `Cert:\CurrentUser\My`에 코드 서명 인증서가 보이면 자동 갱신 정상 동작.

### 4.3 트러블슈팅 — `LastTaskResult` 코드별 진단

| 코드 (10진/16진) | 의미 | 원인 / 조치 |
|---|---|---|
| `0` / `0x0` | 성공 | — |
| `1` / `0x1` | 스크립트 내부 throw | `C:\certum\refresh-*.log` 트랜스크립트 확인. 흔한 원인: ① **Show login dialog on SimplySign Desktop startup** 체크 누락 (3.2 참조) ② SimplySign 윈도우 타이틀 변경 (`$titleCandidates` 추가 필요) ③ 환경변수 누락 (3.3 참조) |
| `2147942402` / `0x80070002` | ERROR_FILE_NOT_FOUND | `pwsh.exe` 또는 `refresh-session.ps1` 경로 미존재. 2.4의 MSI 설치 확인 (`Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe'`) |
| `2147942405` / `0x80070005` | ERROR_ACCESS_DENIED | 작업의 `RunLevel` / `LogonType` 확인. `Highest` + `Interactive` 필요 |
| `267011` / `0x41303` | 한 번도 실행 안 됨 | 트리거 시점이 미래 또는 자동 로그인 미설정 (2.1 참조) |

**트랜스크립트 로그 확인** (가장 빠른 진단):

```powershell
Get-ChildItem C:\certum\refresh-*.log | Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 | Get-Content
```

**SimplySign 실제 윈도우 타이틀 확인** (9.x 업데이트 후 타이틀 변경 시):

```powershell
# 작업 실행 직후, 로그인 창이 떠 있는 동안 별도 창에서:
Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and $_.Name -match 'SimplySign|SmartSign|proCertum' } |
    Select-Object Id, Name, MainWindowTitle
```

여기 보이는 타이틀이 [refresh-session.ps1](file:///C:/certum/refresh-session.ps1) 의 `$titleCandidates` 배열에 없으면 추가하세요. 동일 변경이 워크플로(`.github/workflows/`)에도 필요할 수 있습니다.

---

## 5. GitHub Actions Self-hosted Runner 등록

### 5.1 러너 등록 토큰 발급

1. 브라우저에서 https://github.com/okrbest/okrbest-desktop/settings/actions/runners 접속
2. 우상단 **`New self-hosted runner`** 클릭
3. **Operating system**: Windows / **Architecture**: x64 선택
4. 페이지에 표시된 다운로드 + config 명령을 복사 (토큰 포함)

### 5.2 러너 설치

화면에 표시된 명령을 그대로 실행 — 다음과 비슷한 형태:

```powershell
# 폴더 생성
mkdir C:\actions-runner; cd C:\actions-runner

# 러너 다운로드 (URL/버전은 GitHub이 제시한 것 그대로 사용)
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.x.x/actions-runner-win-x64-2.x.x.zip `
    -OutFile actions-runner-win-x64-2.x.x.zip

# 압축 해제
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\actions-runner-win-x64-2.x.x.zip", $PWD)

# 등록 — 라벨에 'certum' 추가해서 워크플로에서 선택 가능하게
.\config.cmd `
    --url https://github.com/okrbest/okrbest-desktop `
    --token <GitHub이 제시한 1회용 토큰> `
    --name 'okrbest-win-signing-01' `
    --labels 'self-hosted,windows,x64,certum' `
    --runasservice `
    --windowslogonaccount "$env:USERDOMAIN\$env:USERNAME" `
    --windowslogonpassword '<로그인 비밀번호>'
```

> `--runasservice` 옵션이 러너를 Windows 서비스로 자동 등록합니다. 머신 재부팅 시 자동 재시작됩니다.
> 단 SendKeys 기반 세션 갱신은 별도 Task Scheduler 작업으로 인터랙티브 데스크톱에서 돌아가야 하므로 그쪽은 4.2의 자동 로그인 + Logon trigger에 의존합니다.

### 5.3 러너 검증

```powershell
# Windows 서비스 상태 확인
Get-Service 'actions.runner.*' | Format-List Name, Status, StartType

# GitHub 측에서도 Settings → Actions → Runners 페이지에서 'okrbest-win-signing-01' 이 'Idle (녹색)' 상태로 보여야 정상
```

---

## 6. 워크플로 수정

### 6.1 Windows 잡을 self-hosted로 라우팅

[.github/workflows/nightly-main.yml](../.github/workflows/nightly-main.yml)의 `build-msi-installer` 잡 수정:

```diff
 build-msi-installer:
-  runs-on: windows-2022
+  runs-on: [self-hosted, windows, certum]
   steps:
     ...
```

`build-for-pr.yml`, `nightly-rainforest.yml`, `release.yaml` 등 Windows 빌드를 하는 다른 워크플로도 같이 수정.

### 6.2 SimplySign 다운로드/설치 단계 제거

[scripts/certum-sign.ps1](../scripts/certum-sign.ps1)이 매번 SimplySign Desktop을 다운로드+설치하던 로직은 self-hosted 환경에서 불필요. **신규 단순화 스크립트**를 분리하거나, 기존 스크립트가 self-hosted 환경에서는 설치 단계를 건너뛰도록 분기.

가장 깔끔한 방법은 **별도 스크립트 `scripts/certum-sign-selfhosted.ps1`** 신설:

```powershell
<#
  certum-sign-selfhosted.ps1
  ----------------
  Self-hosted 러너 전용 — 이미 SimplySign 세션이 활성 상태라고 가정하고 signtool만 호출.
  Task Scheduler 'CertumSessionRefresh' 작업이 1시간 50분마다 세션을 갱신해줌.
#>
param([Parameter(Mandatory=$true)][string]$FilePath)

$ErrorActionPreference = 'Stop'

# signtool 자동 탐색
$signtool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' `
    -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $signtool) { throw 'signtool.exe not found. Windows SDK 설치 확인.' }

# Cert:\CurrentUser\My 에 코드 서명 인증서가 있는지 사전 검증
$certs = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue)
if ($certs.Count -eq 0) {
    throw 'No code signing certificate in cert store. SimplySign 세션 만료 가능성. CertumSessionRefresh 작업 상태 확인.'
}

$files = Get-ChildItem -Path $FilePath -Recurse -ErrorAction SilentlyContinue
if ($files.Count -eq 0) { throw "No files found matching: $FilePath" }

foreach ($file in $files) {
    Write-Host "Signing: $($file.FullName)"
    & $signtool sign /fd sha256 /tr http://time.certum.pl /td sha256 /a "$($file.FullName)"
    if ($LASTEXITCODE -ne 0) { throw "Failed to sign: $($file.FullName)" }
    & $signtool verify /pa "$($file.FullName)"
    if ($LASTEXITCODE -ne 0) { throw "Verification failed: $($file.FullName)" }
}
Write-Host 'All files signed successfully.'
```

워크플로의 서명 스텝도 이 새 스크립트를 가리키도록 변경:

```diff
 - name: nightly/sign-windows-exe
   env:
     CERTUM_OTP_URI: ${{ secrets.CERTUM_OTP_URI }}
     CERTUM_USERID: ${{ secrets.CERTUM_USERID }}
   if: ${{ env.CERTUM_OTP_URI != '' && env.CERTUM_USERID != '' }}
   shell: powershell
-  run: pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign.ps1 -FilePath "release/win*-unpacked/*.exe"
+  run: pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign-selfhosted.ps1 -FilePath "release/win*-unpacked/*.exe"
```

### 6.3 단계별 도입

리스크를 줄이기 위해 단계적으로:

1. **Step A**: `runs-on:`을 [self-hosted, windows, certum]으로 바꾸고, `certum-sign.ps1` 호출은 그대로 유지 → 다운로드/설치는 self-hosted에 캐시되어 빨라지지만 인증은 여전히 SendKeys로 시도
2. **Step B**: 위가 안정되면 `certum-sign-selfhosted.ps1` 스크립트로 교체 → signtool만 호출
3. **Step C**: 1주일 모니터링 후 GHA 호스트 워크플로의 Windows 잡을 모두 self-hosted로 일원화

---

## 7. 운영

### 7.1 일상 모니터링

다음을 정기적으로 확인:

```powershell
# 1. CertumSessionRefresh 마지막 실행 결과
Get-ScheduledTask -TaskName 'CertumSessionRefresh' | Get-ScheduledTaskInfo |
    Select-Object LastRunTime, LastTaskResult, NextRunTime

# 2. 인증서 저장소에 코드 서명 인증서 존재 여부
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object Subject, NotAfter

# 3. SimplySign Desktop 프로세스 상태
Get-Process SimplySignDesktop -ErrorAction SilentlyContinue

# 4. GitHub Actions runner 서비스 상태
Get-Service 'actions.runner.*' | Format-List Name, Status
```

이 4개를 한 번에 체크하는 점검 스크립트를 `C:\certum\health-check.ps1` 정도로 두고 별도 스케줄(예: 매시간)로 돌려 결과를 로그 파일에 누적하면 편합니다.

### 7.2 인증서 갱신 (1년 1회)

Certum 인증서 만료 30일 전부터 갱신 절차:

1. Certum 관리 콘솔에서 인증서 갱신 (CA/Browser Forum 규정상 459일 단위 재발급)
2. SimplySign 모바일 앱에서 새 OTP QR 코드 생성 (계정 자체는 동일)
3. 새 `otpauth://` URI 추출
4. **이 self-hosted 머신**:
   - 환경변수 `CERTUM_OTP_URI` 갱신: `[Environment]::SetEnvironmentVariable('CERTUM_OTP_URI', '<새 URI>', 'Machine')`
   - 새 PowerShell 창에서 `Start-ScheduledTask CertumSessionRefresh` 실행 (즉시 새 세션 진입)
5. **GitHub 시크릿**도 동일하게 갱신 (CI 호스트 러너 워크플로가 남아 있다면)

소요: 30분 정도.

### 7.3 머신 재부팅 시

자동 복구 시퀀스:
1. Windows 자동 로그인 (2.1) → 사용자 세션 복귀
2. Task Scheduler `CertumSessionRefresh` Logon Trigger → 즉시 세션 인증 시도
3. GitHub Actions runner Windows 서비스 → 자동 시작 (`--runasservice`)

수동 개입 없이 5분 안에 복구되어야 정상.

### 7.4 OS 업데이트 후 재부팅

활성 시간(2.3) 외에 자동 재부팅이 발생할 수 있음. 재부팅 후 위 7.3 흐름이 정상 작동하는지 분기마다 1회는 수동 검증 권장.

---

## 8. 자주 발생하는 문제와 해결

### 8.1 nightly가 "No code signing certificate in cert store"로 실패

원인:
- Task Scheduler 작업 실패 → SimplySign 세션 만료
- 자동 로그인이 풀려 인터랙티브 데스크톱이 없음

해결:
- RDP로 머신 접속
- `Start-ScheduledTask CertumSessionRefresh` 수동 실행
- Cert store 재확인: `Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert`
- 자동 로그인 상태 확인 (Sysinternals Autologon 재실행)

### 8.2 Task Scheduler 작업이 실행되지만 LastTaskResult가 0이 아님

원인 후보:
- SendKeys가 SimplySign 외 다른 활성 윈도우로 가서 OTP 잘못 입력
- KSP/CSP 통신 일시 장애 → SignData 검증이 30초 안에 통과 못 해 throw
- SimplySign 윈도우 타이틀 변경 → AppActivate 실패 (§4.3 진단)
- 인터랙티브 데스크톱 잠김 (Autologon 풀림 / 화면 잠금) → SendKeys가 데스크톱 미진입

진단:
- `C:\certum\refresh-*.log` 트랜스크립트에서 정확한 throw 라인 확인 (§4.3 트랜스크립트 명령 참조)
- 프로세스 충돌 자체는 §4.1 의 "기존 SimplySignDesktop 강제 종료" 블록으로 자동 해결되므로 더 이상 흔한 원인이 아님

### 8.2.1 cert는 보이는데 signtool이 "No certificates were found"로 실패

특수 케이스 — `Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert`로는 인증서가 잡히는데 signtool은 후보 0건이라며 거부.

원인: cert 메타데이터는 store에 캐시처럼 남아있지만 SimplySign 세션이 죽어 **private key 핸들이 사용 불가**. signtool `/a`는 "키 접근 가능한" cert만 선별하므로 후보 0건. `$cert.HasPrivateKey`는 True를 돌려주고 `$cert.PrivateKey`는 CNG 키라 조용히 null이라 거짓 양성 만들기 쉬움.

진단:
```powershell
$c = (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
$rsa = [Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($c)
$rsa  # null 이면 키 핸들 못 얻음 = 세션 죽음
try { [void]$rsa.SignData([byte[]](1..32),'SHA256','Pkcs1'); 'SIGN OK' } catch { "SIGN FAIL: $_" }
```

해결: [scripts/certum-sign-selfhosted.ps1](../scripts/certum-sign-selfhosted.ps1)는 이미 SignData 검증을 거쳐 실패 시 CertumSessionRefresh를 즉석 호출하도록 구현되어 있음. 그래도 실패하면 RDP로 SimplySign Desktop 수동 OTP 재인증 필요.

### 8.3 GitHub Actions runner가 offline로 표시됨

원인:
- Windows 서비스 중지
- 네트워크 단절

해결:
- `Get-Service 'actions.runner.*' | Start-Service`
- 방화벽/프록시 설정 확인 (GitHub Actions runner는 GitHub.com 아웃바운드 HTTPS 필요)

### 8.4 runner는 살아 있는데 잡이 안 들어옴

원인:
- 워크플로 `runs-on:` 라벨이 러너 라벨과 불일치
- 러너에 다른 잡이 점유 중

해결:
- 러너 라벨 확인: `cat C:\actions-runner\.runner` (config.json) 또는 GitHub Settings → Runners 페이지
- 워크플로 yaml의 `runs-on:` 값과 정확히 일치하는지 점검

### 8.5 빌드는 성공하는데 서명 스텝에서 "0x80092004 (cert not found)"

원인:
- signtool이 LocalMachine 저장소를 보고 있는데 인증서는 CurrentUser에만 있음

해결:
- signtool 옵션에 `/sm` 추가 → LocalMachine 저장소 사용 (필요시), 또는
- SimplySign Desktop이 인증서를 양쪽에 주입하도록 설정 변경 (드물게 필요)
- 가장 간단: `signtool sign /a` 의 `/a`가 자동 선택이지만 명시적으로 `/i` (issuer name) 지정해 일치도 향상:
  ```powershell
  & $signtool sign /fd sha256 /tr http://time.certum.pl /td sha256 `
      /a /i 'Certum' "$file"
  ```

---

## 9. 보안 운영 수칙

1. **머신 격리**: 이 머신은 서명 전용. 다른 용도 금지.
2. **BitLocker 활성화**: 디스크 도난/분실 시 OTP secret 보호.
3. **Windows Update 자동**: 보안 패치 누락 금지.
4. **로컬 관리자 계정 강한 비밀번호** + RDP는 VPN/SSH 터널 뒤로만 접근 가능.
5. **GitHub repo 접근 제한**:
   - public repo면 fork PR 워크플로가 self-hosted에서 실행되지 않도록 [Approval for first-time contributors] 설정
   - private repo면 collaborator만 정기 리뷰
6. **시크릿 회전**: 인증서 갱신마다 환경변수 + GitHub Secret 동시 회전.
7. **로그 보존**: `CertumSessionRefresh`의 stdout을 파일로 저장 → 문제 발생 시 시간선 추적 (Task Scheduler `Configure for: Windows 10/11` + `Settings → If the task fails, restart every: 5 minutes`)
8. **인증서 만료 알림**: 만료 30일 전 자동 알림 — 일례:
   ```powershell
   # 정기 점검 스크립트에서
   $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
   $daysLeft = ($cert.NotAfter - (Get-Date)).Days
   if ($daysLeft -lt 30) {
       # Slack/이메일/GitHub Issue 자동 생성
   }
   ```

---

## 10. 운영 체크리스트

### 최초 셋업 시

- [ ] Windows 11 Pro 머신 1대 확보, BitLocker 활성화
- [ ] Sysinternals Autologon으로 자동 로그인 활성
- [ ] 절전/슬립/하이버네이트 비활성 (`powercfg`)
- [ ] Windows Update 활성 시간 nightly 시간대 포함
- [ ] PowerShell 7+ 설치 + ExecutionPolicy `RemoteSigned`(LocalMachine) 설정
- [ ] Chocolatey 설치
- [ ] Git, Visual Studio Build Tools, Windows SDK, Node.js, yq, jq 설치
- [ ] SimplySign Desktop 9.4.x 64-bit 설치
- [ ] **사람이 1회 OTP로 SimplySign 인증** (모바일 앱)
- [ ] `Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert` 결과 확인
- [ ] `CERTUM_OTP_URI`, `CERTUM_USERID` 시스템 환경변수 등록
- [ ] `C:\certum\refresh-session.ps1` 배치
- [ ] Task Scheduler `CertumSessionRefresh` 등록 + 즉시 1회 실행 검증
- [ ] GitHub Actions self-hosted runner 등록 + Windows 서비스 시작
- [ ] GitHub Settings → Actions → Runners 페이지에서 'Idle' 상태 확인
- [ ] 워크플로 `runs-on:` 변경 및 `certum-sign-selfhosted.ps1`로 서명 호출 변경
- [ ] PR 빌드 또는 `workflow_dispatch`로 nightly 수동 트리거 → 서명 정상 동작 확인
- [ ] 1주일 모니터링 후 정상이면 다른 Windows 잡(release.yaml 등)도 self-hosted로 일원화

### 정기 점검 (월 1회)

- [ ] 인증서 만료일 (`NotAfter`) 확인
- [ ] Task Scheduler `CertumSessionRefresh` `LastTaskResult` 0 유지 확인
- [ ] runner 서비스 Status `Running`
- [ ] Windows Update 적용 여부
- [ ] BitLocker 보호 상태 (`manage-bde -status`)

### 인증서 갱신 시 (연 1회)

- [ ] Certum 관리 콘솔에서 인증서 갱신
- [ ] 모바일 앱에서 새 OTP QR 추출
- [ ] 머신의 `CERTUM_OTP_URI` 환경변수 갱신
- [ ] `Start-ScheduledTask CertumSessionRefresh` 즉시 실행
- [ ] 새 인증서 cert store에 들어왔는지 확인
- [ ] GitHub Secret 동시 갱신 (호스트 러너 fallback 워크플로 잔존 시)
- [ ] 다음 nightly에서 새 인증서로 서명되는지 검증

---

## 11. 참고 문서

- [Certum SimplySign 가이드](./Certum-SimplySign.md) — 일반 코드 서명 흐름
- [CI/CD 가이드](./CI_CD.md)
- [Apple Developer 계정 가이드](./APPLE_DEVELOPER_ACCOUNT_SETUP.md) — 비교용
- GitHub — [About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)
- GitHub — [Security hardening for self-hosted runners](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#hardening-for-self-hosted-runners)
- Microsoft Sysinternals — [Autologon](https://learn.microsoft.com/en-us/sysinternals/downloads/autologon)
- Microsoft Learn — [PowerCfg command-line options](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options)
- Microsoft Learn — [Schedule a task](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask)
