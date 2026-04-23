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
# 게시하는 버전 고정 URL을 사용한다. `.exe` 대신 MSI 변형을 쓰는 이유:
#   (1) `.exe` 인스톨러의 `/S` 같은 비표준 silent 스위치가 인식되지 않으면 설치가 조용히
#       중단되어 "Executable not found" 단계에서만 비로소 실패가 드러난다.
#   (2) `msiexec /qn`은 표준 silent 설치를 보장하고 exit code가 명확해 실패 감지가 즉시 가능하다.
$SimplySignVersion = "9.4.2.86"
$SimplySignUrl = "https://files.certum.eu/software/SimplySignDesktop/Windows/$SimplySignVersion/SimplySignDesktop-$SimplySignVersion-64-bit-en.msi"
$InstallerPath = "$env:TEMP\SimplySignDesktop-$SimplySignVersion-64-bit-en.msi"

# 9.4.x부터 GUI 런처 파일명이 `SimplySign Desktop.exe`(공백 포함)에서 `SimplySignDesktop.exe`
# (공백 없음)로 변경됨. 신버전을 우선 탐색하고 구버전을 폴백으로 유지한다.
# `proCertumSmartSign.exe`는 보조 도구(53KB)이므로 후보에서 제외.
$SimplySignExeNames = @('SimplySignDesktop.exe', 'SimplySign Desktop.exe')
$SimplySignDefaultDirs = @(
    'C:\Program Files\Certum\SimplySign Desktop',
    'C:\Program Files (x86)\Certum\SimplySign Desktop'
)

function Find-SimplySignExe {
    foreach ($dir in $SimplySignDefaultDirs) {
        if (-not (Test-Path $dir)) { continue }
        foreach ($name in $SimplySignExeNames) {
            $p = Join-Path $dir $name
            if (Test-Path $p) { return $p }
        }
    }
    return $null
}

$SimplySignExe = Find-SimplySignExe

if (-not $SimplySignExe) {
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

    # MSI는 OLE compound document이므로 매직 바이트가 D0 CF 11 E0 이어야 한다.
    # 다운로드가 HTML 오류 페이지로 대체되면 여기서 터진다.
    $head = [byte[]]::new(4)
    $fs = [System.IO.File]::OpenRead($InstallerPath)
    try { [void]$fs.Read($head, 0, 4) } finally { $fs.Close() }
    if ($head[0] -ne 0xD0 -or $head[1] -ne 0xCF -or $head[2] -ne 0x11 -or $head[3] -ne 0xE0) {
        throw "Downloaded file is not a valid MSI package. URL may be outdated: $SimplySignUrl"
    }

    $msiLog = "$env:TEMP\simplysign-install.log"
    Write-Host "Installing SimplySign Desktop via msiexec (log: $msiLog)..."
    $proc = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i", "`"$InstallerPath`"", "/qn", "/norestart", "/L*V", "`"$msiLog`"" `
        -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        Write-Host "--- msiexec failed; tail of install log ---"
        if (Test-Path $msiLog) { Get-Content $msiLog -Tail 80 | ForEach-Object { Write-Host $_ } }
        throw "msiexec failed with exit code $($proc.ExitCode)."
    }

    $SimplySignExe = Find-SimplySignExe

    if (-not $SimplySignExe) {
        # 기본 경로에서 못 찾았으면 레지스트리 InstallLocation 기준으로 다시 탐색.
        $uninstallRoots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        foreach ($root in $uninstallRoots) {
            $entries = Get-ItemProperty $root -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like '*SimplySign*' -or $_.DisplayName -like '*SmartSign*' }
            foreach ($entry in $entries) {
                if ($entry.InstallLocation -and (Test-Path $entry.InstallLocation)) {
                    foreach ($name in $SimplySignExeNames) {
                        $cand = Join-Path $entry.InstallLocation $name
                        if (Test-Path $cand) { $SimplySignExe = $cand; break }
                    }
                }
                if ($SimplySignExe) { break }
            }
            if ($SimplySignExe) { break }
        }

        # 그래도 못 찾으면 Program Files / 사용자 폴더 재귀 탐색 (두 이름 모두).
        if (-not $SimplySignExe) {
            $searchRoots = @(
                'C:\Program Files',
                'C:\Program Files (x86)',
                $env:LOCALAPPDATA,
                $env:APPDATA,
                $env:ProgramData
            ) | Where-Object { $_ -and (Test-Path $_) }
            foreach ($root in $searchRoots) {
                foreach ($name in $SimplySignExeNames) {
                    $found = Get-ChildItem -Path $root -Filter $name `
                        -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($found) { $SimplySignExe = $found.FullName; break }
                }
                if ($SimplySignExe) { break }
            }
        }

        if (-not $SimplySignExe) {
            Write-Host "--- Registered SimplySign/Certum uninstall entries ---"
            foreach ($root in $uninstallRoots) {
                Get-ItemProperty $root -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like '*SimplySign*' -or $_.DisplayName -like '*SmartSign*' -or $_.Publisher -like '*Certum*' -or $_.Publisher -like '*Asseco*' } |
                    Select-Object DisplayName, DisplayVersion, InstallLocation, Publisher, UninstallString |
                    Format-List
            }
            Write-Host "--- .exe files under C:\Program Files\Certum\SimplySign Desktop ---"
            $probeDir = 'C:\Program Files\Certum\SimplySign Desktop'
            if (Test-Path $probeDir) {
                Get-ChildItem -Path $probeDir -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue |
                    ForEach-Object { Write-Host "  $($_.FullName)" }
            }
            Write-Host "--- msiexec install log (tail 200 lines) ---"
            if (Test-Path $msiLog) { Get-Content $msiLog -Tail 200 | ForEach-Object { Write-Host $_ } }
            throw "SimplySign Desktop installation failed. Executable not found."
        }
    }
    Write-Host "SimplySign Desktop installed at: $SimplySignExe"
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
