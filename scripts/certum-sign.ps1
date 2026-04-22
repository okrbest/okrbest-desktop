<#
  certum-sign.ps1
  ----------------
  Certum SimplySign 자동 인증 및 Windows 코드 서명 스크립트

  필요한 환경변수:
    CERTUM_OTP_URI  - SimplySign QR 코드의 otpauth:// URI
    CERTUM_USERID   - SimplySign 계정 이메일

  사용법:
    pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign.ps1 -FilePath "release/win*-unpacked/*.exe"
    pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign.ps1 -FilePath "release/*.msi"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

# === 1. 환경변수 확인 ========================================================
$OtpUri  = $env:CERTUM_OTP_URI
$UserId  = $env:CERTUM_USERID

if (-not $OtpUri) {
    throw "CERTUM_OTP_URI not set. Failing code signing step."
}
if (-not $UserId) {
    throw "CERTUM_USERID not set. Failing code signing step."
}

# === 2. otpauth:// URI 파싱 ==================================================
$uri = [Uri]$OtpUri

try {
    $q = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
} catch {
    $q = @{}
    foreach ($part in $uri.Query.TrimStart('?') -split '&') {
        $kv = $part -split '=',2
        if ($kv.Count -eq 2) { $q[$kv[0]] = [Uri]::UnescapeDataString($kv[1]) }
    }
}

$Base32    = $q['secret']
$Digits    = if ($q['digits']) { [int]$q['digits'] } else { 6 }
$Period    = if ($q['period']) { [int]$q['period'] } else { 30 }
$Algorithm = if ($q['algorithm']) { $q['algorithm'].ToUpper() } else { 'SHA1' }

if (-not $Base32) {
    throw "Invalid CERTUM_OTP_URI: missing 'secret' parameter."
}
if ($Algorithm -ne 'SHA1' -and $Algorithm -ne 'SHA256') {
    throw "This helper implements HMAC-SHA1 and HMAC-SHA256 only (requested: $Algorithm)."
}

# === 3. TOTP 생성기 ==========================================================
Add-Type -Language CSharp @"
using System;
using System.Security.Cryptography;

public static class Totp
{
    private const string B32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    private static byte[] Base32Decode(string s)
    {
        s = s.TrimEnd('=').ToUpperInvariant();
        int byteCount = s.Length * 5 / 8;
        byte[] bytes = new byte[byteCount];

        int bitBuffer = 0, bitsLeft = 0, idx = 0;
        foreach (char c in s)
        {
            int val = B32.IndexOf(c);
            if (val < 0) throw new ArgumentException("Invalid Base32 char: " + c);

            bitBuffer = (bitBuffer << 5) | val;
            bitsLeft += 5;

            if (bitsLeft >= 8)
            {
                bytes[idx++] = (byte)(bitBuffer >> (bitsLeft - 8));
                bitsLeft -= 8;
            }
        }
        return bytes;
    }

    public static string Now(string secret, int digits, int period, string algorithm)
    {
        byte[] key = Base32Decode(secret);
        long counter = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / period;

        byte[] cnt = BitConverter.GetBytes(counter);
        if (BitConverter.IsLittleEndian) Array.Reverse(cnt);

        byte[] hash;
        if (algorithm == "SHA256")
        {
            hash = new HMACSHA256(key).ComputeHash(cnt);
        }
        else
        {
            hash = new HMACSHA1(key).ComputeHash(cnt);
        }

        int offset = hash[hash.Length - 1] & 0x0F;
        int binary =
            ((hash[offset]     & 0x7F) << 24) |
            ((hash[offset + 1] & 0xFF) << 16) |
            ((hash[offset + 2] & 0xFF) <<  8) |
             (hash[offset + 3] & 0xFF);

        int otp = binary % (int)Math.Pow(10, digits);
        return otp.ToString(new string('0', digits));
    }
}
"@

function Get-TotpCode {
    param([string]$Secret, [int]$Digits=6, [int]$Period=30, [string]$Algorithm='SHA1')
    [Totp]::Now($Secret, $Digits, $Period, $Algorithm)
}

function Escape-SendKeysText {
    param([string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    # WScript.Shell SendKeys 특수문자 이스케이프
    $escaped = $Text
    $escaped = $escaped.Replace('{', '{{}')
    $escaped = $escaped.Replace('}', '{}}')
    $escaped = $escaped.Replace('+', '{+}')
    $escaped = $escaped.Replace('^', '{^}')
    $escaped = $escaped.Replace('%', '{%}')
    $escaped = $escaped.Replace('~', '{~}')
    $escaped = $escaped.Replace('(', '{(}')
    $escaped = $escaped.Replace(')', '{)}')
    $escaped = $escaped.Replace('[', '{[}')
    $escaped = $escaped.Replace(']', '{]}')
    return $escaped
}

function Wait-ForCodeSigningCert {
    param([int]$TimeoutSeconds = 30)

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $certs = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue)
        if ($certs.Count -gt 0) {
            return $true
        }
        Start-Sleep -Seconds 1
    }

    return $false
}

# === 4. SimplySign Desktop 설치 ==============================================
# Certum 공식 서포트 페이지(https://support.certum.eu/en/cert-offer-software-and-libraries/)에서
# 게시하는 버전 고정 URL을 사용한다. 과거 `simplysign.certum.eu/app/...-latest.exe` 경로는 폐기되어
# 현재 HTML 랜딩 페이지로 리다이렉트되므로 리다이렉트 허용은 금지하고 PE 시그니처까지 검증한다.
$SimplySignVersion = "9.4.2.86"
$SimplySignUrl = "https://files.certum.eu/software/SimplySignDesktop/Windows/$SimplySignVersion/SimplySignDesktop-$SimplySignVersion-win-64-bit.exe"
$InstallerPath = "$env:TEMP\SimplySignDesktop-$SimplySignVersion-win-64-bit.exe"
$SimplySignExe = "C:\Program Files (x86)\Certum\SimplySign Desktop\SimplySign Desktop.exe"

if (-not (Test-Path $SimplySignExe)) {
    Write-Host "Downloading SimplySign Desktop $SimplySignVersion..."
    $maxAttempts = 3
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Invoke-WebRequest -Uri $SimplySignUrl -OutFile $InstallerPath `
                -MaximumRedirection 0 -UseBasicParsing
            break
        } catch {
            if ($i -eq $maxAttempts) { throw }
            Start-Sleep -Seconds ([math]::Pow(2, $i))
        }
    }

    $head = [byte[]]::new(2)
    $fs = [System.IO.File]::OpenRead($InstallerPath)
    try { [void]$fs.Read($head, 0, 2) } finally { $fs.Close() }
    if ($head[0] -ne 0x4D -or $head[1] -ne 0x5A) {
        throw "Downloaded file is not a valid PE executable. URL may be outdated: $SimplySignUrl"
    }

    Write-Host "Installing SimplySign Desktop..."
    Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -NoNewWindow

    if (-not (Test-Path $SimplySignExe)) {
        # 대체 경로 시도
        $altPath = "C:\Program Files\Certum\SimplySign Desktop\SimplySign Desktop.exe"
        if (Test-Path $altPath) {
            $SimplySignExe = $altPath
        } else {
            throw "SimplySign Desktop installation failed. Executable not found."
        }
    }
    Write-Host "SimplySign Desktop installed successfully."
} else {
    Write-Host "SimplySign Desktop already installed."
}

# === 5. SimplySign 인증 ======================================================
Write-Host "Generating TOTP code..."
$otp = Get-TotpCode -Secret $Base32 -Digits $Digits -Period $Period -Algorithm $Algorithm
Write-Host "TOTP code generated."

Write-Host "Launching SimplySign Desktop..."
$proc = Start-Process -FilePath $SimplySignExe -PassThru
Start-Sleep -Seconds 5

$wshell = New-Object -ComObject WScript.Shell

# SimplySign 윈도우에 포커스
$focused = $wshell.AppActivate($proc.Id)
if (-not $focused) {
    $focused = $wshell.AppActivate('SimplySign Desktop')
}

for ($i = 0; -not $focused -and $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    $focused = $wshell.AppActivate($proc.Id) -or $wshell.AppActivate('SimplySign Desktop')
}

if (-not $focused) {
    throw "Could not bring SimplySign Desktop to the foreground."
}

# TOTP 입력
Start-Sleep -Milliseconds 400

$escapedUserId = Escape-SendKeysText -Text $UserId
$escapedOtp = Escape-SendKeysText -Text $otp

# Hosted runner 신규 설치 환경을 고려해 Username + Token 모두 입력 시도
$wshell.SendKeys("^a")
Start-Sleep -Milliseconds 200
$wshell.SendKeys($escapedUserId)
Start-Sleep -Milliseconds 150
$wshell.SendKeys("{TAB}")
Start-Sleep -Milliseconds 150
$wshell.SendKeys($escapedOtp)
Start-Sleep -Milliseconds 150
$wshell.SendKeys("{ENTER}")
Write-Host "Username and TOTP credentials sent to SimplySign Desktop."

# 인증 대기
Write-Host "Waiting for SimplySign authentication..."
if (-not (Wait-ForCodeSigningCert -TimeoutSeconds 30)) {
    throw "No code signing certificate detected in Windows Certificate Store after authentication."
}
Write-Host "Code signing certificate detected."

# === 6. signtool 서명 ========================================================
Write-Host "Signing files matching: $FilePath"

$files = Get-ChildItem -Path $FilePath -Recurse -ErrorAction SilentlyContinue
if ($files.Count -eq 0) {
    throw "No files found matching pattern: $FilePath"
}

$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
if (-not (Test-Path $signtool)) {
    # Windows SDK signtool 자동 탐색
    $signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1 -ExpandProperty FullName

    if (-not $signtool) {
        throw "signtool.exe not found. Ensure Windows SDK is installed."
    }
}

Write-Host "Using signtool: $signtool"

foreach ($file in $files) {
    Write-Host "Signing: $($file.FullName)"
    & $signtool sign /fd sha256 /tr http://time.certum.pl /td sha256 /a "$($file.FullName)"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sign: $($file.FullName)"
    }

    & $signtool verify /pa "$($file.FullName)"
    if ($LASTEXITCODE -ne 0) {
        throw "Signature verification failed: $($file.FullName)"
    }
    Write-Host "Successfully signed: $($file.Name)"
}

Write-Host "All files signed successfully."
