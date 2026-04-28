<#
  certum-sign-selfhosted.ps1
  ----------------
  Self-hosted Windows 러너 전용 Certum 코드 서명 스크립트.

  사전 조건 (spec-docs/SELFHOSTED_WINDOWS_RUNNER_SETUP.md 참조):
    - 러너 머신에 SimplySign Desktop이 설치돼 있고, Task Scheduler 작업
      'CertumSessionRefresh'가 ~110분마다 세션을 갱신해 Windows 인증서
      저장소(Cert:\CurrentUser\My)에 코드 서명 인증서가 상시 존재한다.

  따라서 이 스크립트는 SimplySign 설치/OTP 인증 없이 signtool 호출만 수행한다.
  GitHub-hosted 러너에서는 동작하지 않으니 그 경우 ./scripts/certum-sign.ps1 사용.

  사용법:
    pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign-selfhosted.ps1 -FilePath "release/win*-unpacked/*.exe"
    pwsh -ExecutionPolicy Bypass -File ./scripts/certum-sign-selfhosted.ps1 -FilePath "release/*.msi"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

# === 1. 코드 서명 인증서 사전 검증 ============================================
# 세션 만료 시 signtool에서 0x80092004(cert not found)가 나는데, 그 전에
# 인증서 저장소를 직접 확인해 fail-fast — 운영에서 원인 추적이 훨씬 쉽다.
$certs = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue)
if ($certs.Count -eq 0) {
    throw "No code signing certificate in Cert:\CurrentUser\My. SimplySign 세션이 만료됐을 수 있습니다. 러너 머신에서 'Get-ScheduledTask CertumSessionRefresh | Get-ScheduledTaskInfo' 로 LastTaskResult를 확인하세요."
}
Write-Host "Code signing certificate found. Subject: $($certs[0].Subject)"
Write-Host "  Expires: $($certs[0].NotAfter.ToString('yyyy-MM-dd'))"

# === 2. signtool 자동 탐색 ====================================================
$signtool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $signtool) {
    throw "signtool.exe not found. Windows SDK 설치 확인 (Visual Studio Build Tools + Windows 11 SDK)."
}
Write-Host "Using signtool: $signtool"

# === 3. 대상 파일 수집 =======================================================
$files = Get-ChildItem -Path $FilePath -Recurse -ErrorAction SilentlyContinue
if ($files.Count -eq 0) {
    throw "No files found matching pattern: $FilePath"
}

# === 4. 서명 + 검증 ==========================================================
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
