<#
  certum-sign.ps1
  ----------------
  Certum SimplySign 자동 인증 및 Windows 코드 서명 스크립트

  필요한 환경변수:
    CERTUM_OTP_URI  - SimplySign QR 코드의 otpauth:// URI
    CERTUM_USERID   - SimplySign 계정 이메일

  사용법:
    pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign.ps1 -FilePath "release/**/okrbest-desktop*.exe"
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
    Write-Host "::warning::CERTUM_OTP_URI not set. Skipping code signing."
    exit 0
}
if (-not $UserId) {
    Write-Host "::warning::CERTUM_USERID not set. Skipping code signing."
    exit 0
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

if ($Algorithm -ne 'SHA1') {
    throw "This helper only implements HMAC-SHA1 (requested: $Algorithm)."
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

    public static string Now(string secret, int digits, int period)
    {
        byte[] key = Base32Decode(secret);
        long counter = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / period;

        byte[] cnt = BitConverter.GetBytes(counter);
        if (BitConverter.IsLittleEndian) Array.Reverse(cnt);

        byte[] hash = new HMACSHA1(key).ComputeHash(cnt);
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
    param([string]$Secret, [int]$Digits=6, [int]$Period=30)
    [Totp]::Now($Secret, $Digits, $Period)
}

# === 4. SimplySign Desktop 설치 ==============================================
$SimplySignUrl = "https://simplysign.certum.eu/app/SimplySignDesktop-latest.exe"
$InstallerPath = "$env:TEMP\SimplySignDesktop-latest.exe"
$SimplySignExe = "C:\Program Files (x86)\Certum\SimplySign Desktop\SimplySign Desktop.exe"

if (-not (Test-Path $SimplySignExe)) {
    Write-Host "Downloading SimplySign Desktop..."
    Invoke-WebRequest -Uri $SimplySignUrl -OutFile $InstallerPath -UseBasicParsing

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
$otp = Get-TotpCode -Secret $Base32 -Digits $Digits -Period $Period
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
$wshell.SendKeys("$otp{ENTER}")
Write-Host "TOTP credentials sent to SimplySign Desktop."

# 인증 대기
Write-Host "Waiting for SimplySign authentication..."
Start-Sleep -Seconds 10

# === 6. signtool 서명 ========================================================
Write-Host "Signing files matching: $FilePath"

$files = Get-ChildItem -Path $FilePath -Recurse -ErrorAction SilentlyContinue
if ($files.Count -eq 0) {
    Write-Host "::warning::No files found matching pattern: $FilePath"
    exit 0
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
    Write-Host "Successfully signed: $($file.Name)"
}

Write-Host "All files signed successfully."
