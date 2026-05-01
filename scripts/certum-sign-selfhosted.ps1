<#
  certum-sign-selfhosted.ps1
  ----------------
  Self-hosted Windows 러너 전용 Certum 코드 서명 스크립트.

  사전 조건 (spec-docs/SELFHOSTED_WINDOWS_RUNNER_SETUP.md 참조):
    - 러너 머신에 SimplySign Desktop이 설치돼 있고, Task Scheduler 작업
      'CertumSessionRefresh'가 ~110분마다 세션을 갱신해 Windows 인증서
      저장소(Cert:\CurrentUser\My)에 코드 서명 인증서가 상시 존재한다.

  검증 정책 (운영 학습 반영):
    Cert store에 인증서가 보여도 SimplySign 세션이 죽으면 private key 접근이
    안 돼 signtool이 0x80092004(cert not found)로 실패한다. 이를 방지하기 위해
      1) cert 존재만이 아니라 SignData 테스트로 private key 실접근을 검증
      2) 검증 실패 시 'CertumSessionRefresh' task를 동기 호출해 즉석 갱신
      3) 갱신 후에도 키 접근 불가면 fail-fast (사람이 RDP로 OTP 재인증 필요)

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

# === 0. 헬퍼: private key 실접근 검증 =========================================
# CNG 키(SimplySign 가상 스마트카드는 CNG/KSP)도 처리하기 위해
# RSACertificateExtensions.GetRSAPrivateKey 사용. .PrivateKey 프로퍼티는
# CNG 키에 대해 조용히 null을 돌려주므로 부적합.
function Test-CodeSigningCertUsable {
    param([Parameter(Mandatory=$true)] $Cert)
    try {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Cert)
        if (-not $rsa) { return $false }
        # SignData가 실제 KSP/CSP까지 도달해 키 핸들이 살아있는지 확인.
        # PS 7 / .NET 8 에선 문자열 → HashAlgorithmName/RSASignaturePadding 자동변환이
        # 안 돼 "SignData 오버로드 없음" 으로 깨진다 (PS 5.1 호환 가정 시 함정).
        # 반드시 typed 값으로 호출.
        [void]$rsa.SignData(
            [byte[]](1..32),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        return $true
    } catch {
        return $false
    }
}

function Get-UsableCodeSigningCert {
    $candidates = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue)
    foreach ($c in $candidates) {
        if (Test-CodeSigningCertUsable -Cert $c) { return $c }
    }
    return $null
}

# === 1. 인증서 검증 + 필요 시 즉석 세션 갱신 ===================================
$cert = Get-UsableCodeSigningCert

if (-not $cert) {
    Write-Host "No usable code signing certificate (cert metadata는 있어도 private key 접근 불가). CertumSessionRefresh 즉석 호출."

    $task = Get-ScheduledTask -TaskName 'CertumSessionRefresh' -ErrorAction SilentlyContinue
    if (-not $task) {
        throw "Scheduled task 'CertumSessionRefresh' 미등록. spec-docs/SELFHOSTED_WINDOWS_RUNNER_SETUP.md §4.2 따라 등록 필요."
    }

    Start-ScheduledTask -TaskName 'CertumSessionRefresh'

    # 0x41301 (267009) = 작업 실행 중. 완료될 때까지 대기 (최대 3분).
    $deadline = (Get-Date).AddMinutes(3)
    do {
        Start-Sleep -Seconds 2
        $info = Get-ScheduledTaskInfo -TaskName 'CertumSessionRefresh'
    } while ($info.LastTaskResult -eq 267009 -and (Get-Date) -lt $deadline)

    if ($info.LastTaskResult -eq 267009) {
        throw "CertumSessionRefresh 가 3분 내 끝나지 않음. 러너 머신 RDP 접속해 직접 진단 필요."
    }
    if ($info.LastTaskResult -ne 0) {
        throw "CertumSessionRefresh 실패 (LastTaskResult=$($info.LastTaskResult)). C:\certum\refresh-*.log 트랜스크립트 확인."
    }

    $cert = Get-UsableCodeSigningCert
    if (-not $cert) {
        throw "세션 갱신 작업은 성공했으나 private key 접근 여전히 불가. SimplySign이 모바일 OTP 재인증을 요구하는 상태일 수 있음 — 러너 머신 RDP로 SimplySign Desktop 수동 로그인 필요."
    }
    Write-Host "Session refreshed and private key verified."
}

Write-Host "Code signing certificate ready. Subject: $($cert.Subject)"
Write-Host "  Expires:    $($cert.NotAfter.ToString('yyyy-MM-dd'))"
Write-Host "  Thumbprint: $($cert.Thumbprint)"

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
# /sha1 로 thumbprint 콕 찍기 — /a 는 후보 부재 시 "no certs found"만 던져
# 진단이 어렵다. 우리는 §1에서 검증 끝낸 cert를 들고 있으므로 명시 지정이 정확.
foreach ($file in $files) {
    Write-Host "Signing: $($file.FullName)"
    & $signtool sign /fd sha256 /tr http://time.certum.pl /td sha256 /sha1 $cert.Thumbprint "$($file.FullName)"
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
