<#
  refresh-session.ps1
  ----------------
  SimplySign Desktop 세션을 갱신해 영구 유지하기 위한 스크립트.
  Self-hosted Windows 러너의 Task Scheduler 작업 'CertumSessionRefresh'에서
  매 1시간 50분마다 실행 + 워크플로의 서명 잡 진입 시
  scripts/certum-sign-selfhosted.ps1 이 (세션 죽음 감지 시) 즉석 호출.

  배포: 본 파일은 repo가 단일 진실 소스. 러너 머신에서는 별도 셋업 단계로
        C:\certum\refresh-session.ps1 에 복사해 두며, repo 갱신 시 재복사한다.
        (Task Scheduler 액션은 C:\certum\ 경로를 가리키므로 변경 불필요.)
        절차는 spec-docs/SELFHOSTED_WINDOWS_RUNNER_SETUP.md §4.1 참조.

  설계 원칙 (운영 학습 반영):
    - 시작 시 기존 SimplySignDesktop 인스턴스를 강제 종료한 뒤 새로 띄움.
      이미 떠 있으면 새 로그인 창이 안 뜨고 SendKeys가 미아 → 알려진 실패 모드.
    - 종료 직후 store 의 stale cert 도 제거. 9.4.3.x launcher 는 cert 가 store 에
      있으면 "이미 인증됨" 으로 판단해 로그인 창을 띄우지 않는다 → fresh 로그인
      미발생 → CNG 핸들 죽은 채로 "잘못된 UID" 30초. 핸들이 이미 죽었으니
      제거해도 손해 없음.
    - 로그인 입력은 Win32 SendMessage 로 EDIT 에 WM_SETTEXT, BUTTON 에 BM_CLICK
      직접 송신. 7.6 launcher 의 UI Automation provider 가 모든 컨트롤을
      ControlType.Pane + IsKeyboardFocusable=False 로 노출해서 ValuePattern /
      SetFocus / InvokePattern 다 동작 안 하고, SendKeys + Tab 도 새 UI 의
      초기 포커스 (Token 필드) + ID 자동완성 거동 ("Remember last logged ID"
      옵션) 때문에 username/OTP 가 잘못 들어가는 함정이 있다. UI Automation 은
      ClassName / NativeWindowHandle 추출에만 사용.
    - 성공 판정은 cert 존재가 아니라 private key SignData 테스트 통과로 격상.
      cert 메타데이터는 세션이 죽어도 store에 캐시처럼 남아 거짓 양성 가능.
    - GetRSAPrivateKey 와 SignData 둘 다 throw 가능 — "잘못된 UID입니다" /
      "Invalid UID" 는 cert 메타는 살아있는데 CNG 핸들이 죽은 SimplySign
      세션을 가리킬 때 GetRSAPrivateKey 가 던진다. 양쪽을 모두 try/catch 로
      감싸 30s 폴링이 한 사이클 만에 죽지 않도록 함.
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

# === otpauth:// 파싱 =========================================================
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

# === TOTP 생성기 =============================================================
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

# === SimplySign Desktop 실행 + 로그인 ========================================
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

# Stop-Process 후 cert 메타가 store 에 남아있으면 9.4.3.x launcher 가
# "이미 인증됨" 으로 판단해 로그인 창을 안 띄운다 → SendKeys 가 갈 곳 없음 →
# fresh 로그인 미발생 → 죽은 CNG 핸들 그대로 → GetRSAPrivateKey 가 30초 내내
# "잘못된 UID" (운영 학습). 핸들은 이미 죽어 cert 는 사용 불가 상태였으므로
# 제거해도 손해 없음. 사람이 manual 로 할 때 자연스레 하던 단계를 자동화한 것.
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -match 'OKRBEST' } |
    Remove-Item -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $exe.FullName -PassThru
Start-Sleep -Seconds 5

# === 로그인 입력: Win32 SendMessage 로 EDIT/BUTTON 에 직접 메시지 ===========
# 7.6 launcher 의 UI Automation provider 가 망가져 있다 — 모든 컨트롤을
# ControlType.Pane + IsKeyboardFocusable=False 로 노출함 (트리 덤프로 확인).
# ValuePattern, SetFocus, InvokePattern 다 동작 안 함. 옛 SendKeys + Tab 도 새 UI
# 거동 (초기 포커스 Token, ID 자동완성) 에서 깨짐.
#
# 해결: UI Automation 은 ClassName / NativeWindowHandle 추출에만 사용하고,
# 실제 입력은 Win32 SendMessage 로 EDIT 에 WM_SETTEXT, BUTTON 에 BM_CLICK 직접
# 송신. focus / 키스트로크 의존 없음.
Add-Type -AssemblyName UIAutomationClient -ErrorAction SilentlyContinue

if (-not ('SsdNative' -as [type])) {
    Add-Type -Namespace WS -Name SsdNative -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet=System.Runtime.InteropServices.CharSet.Auto, SetLastError=true)]
public static extern System.IntPtr SendMessage(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, string lParam);

[System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint="SendMessageW", SetLastError=true)]
public static extern System.IntPtr SendMessagePtr(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, System.IntPtr lParam);
'@
}
$WM_SETTEXT = 0x000C
$BM_CLICK   = 0x00F5

# 로그인 윈도우 식별 기준: ClassName 이 EDIT.app 패턴인 컨트롤이 2개 이상.
# (모두 Pane 으로 노출되므로 ControlType.Edit 검색은 무의미.)
$root = [System.Windows.Automation.AutomationElement]::RootElement
$pidCond = [System.Windows.Automation.PropertyCondition]::new(
    [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $proc.Id)

function Find-MatchingDescendants {
    param($Window, [string]$ClassNameRegex)
    $hits = New-Object System.Collections.ArrayList
    $all = $Window.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($c in $all) {
        try {
            if ($c.Current.ClassName -match $ClassNameRegex) { [void]$hits.Add($c) }
        } catch {}
    }
    # ArrayList 로 반환 — PS unary-comma trap 회피 (PowerShell pipeline 이
    # ArrayList 는 unwrap 하지 않으므로 .Count 와 인덱스 접근 안전).
    return $hits
}

$loginWin = $null
$edits = $null
for ($i = 0; -not $loginWin -and $i -lt 40; $i++) {
    foreach ($w in $root.FindAll([System.Windows.Automation.TreeScope]::Children, $pidCond)) {
        $cand = Find-MatchingDescendants -Window $w -ClassNameRegex 'EDIT\.app|^Edit$|TextBox'
        if ($cand.Count -ge 2) {
            $loginWin = $w
            $edits = $cand
            break
        }
    }
    if (-not $loginWin) { Start-Sleep -Milliseconds 500 }
}

if (-not $loginWin) {
    # 실패 시에만 트리 덤프 — 다음 진단의 근거.
    Write-Host "=== UI Automation tree dump (login window not found) ==="
    foreach ($w in $root.FindAll([System.Windows.Automation.TreeScope]::Children, $pidCond)) {
        Write-Host ("WINDOW Name='{0}' Class='{1}'" -f $w.Current.Name, $w.Current.ClassName)
        try {
            $allCtrls = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                [System.Windows.Automation.Condition]::TrueCondition)
            foreach ($c in $allCtrls) {
                try {
                    $rect = $c.Current.BoundingRectangle
                    Write-Host ("  CT={0} Class='{1}' Name='{2}' HWND={3} Rect=({4},{5},{6}x{7})" -f `
                        $c.Current.ControlType.ProgrammaticName,
                        $c.Current.ClassName,
                        $c.Current.Name,
                        $c.Current.NativeWindowHandle,
                        [int]$rect.Left, [int]$rect.Top,
                        [int]$rect.Width, [int]$rect.Height)
                } catch {}
            }
        } catch {}
    }
    throw 'SimplySign Desktop login window (2+ EDIT.app fields) not found. Transcript의 트리 덤프 참조.'
}

# ID/Token 식별: visual 위치 — Y 작은 게 ID (위), 큰 게 Token (아래).
$sortedEdits = $edits | Sort-Object { $_.Current.BoundingRectangle.Top }
$idEdit    = $sortedEdits[0]
$tokenEdit = $sortedEdits[1]

Write-Host "=== Login fields ==="
Write-Host ("  ID    HWND={0} Name='{1}' Top={2}" -f $idEdit.Current.NativeWindowHandle, $idEdit.Current.Name, [int]$idEdit.Current.BoundingRectangle.Top)
Write-Host ("  Token HWND={0} Name='{1}' Top={2}" -f $tokenEdit.Current.NativeWindowHandle, $tokenEdit.Current.Name, [int]$tokenEdit.Current.BoundingRectangle.Top)

# WM_SETTEXT 로 EDIT 컨트롤에 직접 텍스트 설정.
$idHwnd    = [IntPtr]$idEdit.Current.NativeWindowHandle
$tokenHwnd = [IntPtr]$tokenEdit.Current.NativeWindowHandle
[void][WS.SsdNative]::SendMessage($idHwnd,    $WM_SETTEXT, [IntPtr]::Zero, $UserId)
[void][WS.SsdNative]::SendMessage($tokenHwnd, $WM_SETTEXT, [IntPtr]::Zero, $otp)
Start-Sleep -Milliseconds 200

# Ok 버튼 BM_CLICK — focus 불필요. 인라인 탐색으로 PS 배열 unwrap 트랩 회피.
$okBtn = $null
$btnCandidates = Find-MatchingDescendants -Window $loginWin -ClassNameRegex 'BUTTON\.app|^Button$'
foreach ($b in $btnCandidates) {
    try {
        if ($b.Current.Name -match '^(Ok|OK|확인)$') { $okBtn = $b; break }
    } catch {}
}
if (-not $okBtn) { throw 'Ok button not found in login window.' }

$okHwnd = [IntPtr]$okBtn.Current.NativeWindowHandle
[void][WS.SsdNative]::SendMessagePtr($okHwnd, $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "Ok button clicked via BM_CLICK (HWND=$okHwnd)."

# === 검증: private key 실접근(SignData)까지 통과해야 성공 ====================
# CNG 키(SimplySign 가상 스마트카드는 CNG/KSP)에 대응하기 위해
# RSACertificateExtensions.GetRSAPrivateKey 사용 ($cert.PrivateKey 는 CNG에서 null).
#
# GetRSAPrivateKey 와 SignData 둘 다 throw 가능 — 특히 "잘못된 UID입니다" /
# "Invalid UID" 는 cert 메타는 store 에 남아있는데 SimplySign 세션이 죽어
# CNG 핸들이 미아인 상태에서 GetRSAPrivateKey 가 던진다. $ErrorActionPreference='Stop'
# 환경에서 이걸 안 잡으면 폴링 한 사이클 만에 스크립트가 죽는다. 양쪽 모두
# try/catch 로 감싸 30s 전체를 폴링한다.
$deadline = (Get-Date).AddSeconds(30)
$lastError = $null
while ((Get-Date) -lt $deadline) {
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
            Select-Object -First 1
    if ($cert) {
        try {
            $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
            if ($rsa) {
                # PowerShell 7 / .NET 8 은 'SHA256' / 'Pkcs1' 문자열을 HashAlgorithmName /
                # RSASignaturePadding 로 자동변환해주지 않아 "SignData 오버로드 없음" 으로 깨진다.
                # PS 5.1 에선 통하던 거라 운영 중 발견. 반드시 typed 값으로 호출.
                [void]$rsa.SignData(
                    [byte[]](1..32),
                    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
                Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] SimplySign session refreshed and private key verified. Subject: $($cert.Subject)"
                return
            }
        } catch {
            $lastError = $_.Exception.Message
        }
    }
    Start-Sleep -Seconds 1
}
throw "Session refresh did not produce a working private key (signtool-ready) within 30s. Last error: $lastError. SimplySign 세션이 반쯤 죽어있을 가능성 — RDP 로 머신 접속해 SimplySign Desktop 수동 OTP 재인증 필요할 수 있음."
