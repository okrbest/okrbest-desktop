# AWS S3 & 자동 업데이트 설정 가이드 (초보자용)

이 문서는 OKR Best Desktop이 사용하는 **모든 AWS S3 경로**를 처음 세팅하는 사람이 단계별로 따라 하면 정상 작동하는 것을 목표로 한다. 개념 설명보다는 "무엇을 만들고 어떤 값을 어디에 넣는가"에 집중한다.

관련 문서:
- [DEPLOYMENT_ENVIRONMENT_SETUP.md](DEPLOYMENT_ENVIRONMENT_SETUP.md) — 전체 시크릿 체크리스트
- [CI_CD.md](CI_CD.md) — 릴리즈 플로우 전반
- [APPLE_DEVELOPER_ACCOUNT_SETUP.md](APPLE_DEVELOPER_ACCOUNT_SETUP.md) — macOS 서명

---

## 0. 전체 그림 — 이 프로젝트는 AWS S3를 어디에 쓰는가

이 프로젝트는 서로 독립된 **4개의 S3 경로**를 사용한다. 각 경로는 **버킷도 다르고, 인증 방식도 다르고, 담당 워크플로도 다르다.** 먼저 이 표를 이해하는 것이 모든 혼란을 예방한다.

| # | 경로 이름 | 버킷 | 인증 방식 | 담당 워크플로 | 용도 |
|---|---|---|---|---|---|
| A | **Release** | `OKRBEST_DESKTOP_RELEASE_BUCKET` 시크릿 | **OIDC** (IAM Role) | [release.yaml](../.github/workflows/release.yaml), [nightly-main.yml](../.github/workflows/nightly-main.yml) | 정식/RC 릴리즈 바이너리 + 자동 업데이트 포인터 (`latest.txt` 등) |
| B | **Daily (Rainforest)** | `okrbest-desktop-daily-builds` **(워크플로에 하드코딩)** | 정적 IAM User 키 | [nightly-rainforest.yml](../.github/workflows/nightly-rainforest.yml) | Rainforest QA가 매일 최신 빌드를 받아가는 고정 URL |
| C | **E2E Reports** | `okrbest-cypress-report` **(워크플로에 하드코딩)** | 정적 IAM User 키 | [e2e-functional-template.yml](../.github/workflows/e2e-functional-template.yml) | Playwright/Cypress 테스트 리포트 HTML 아카이브 |
| D | **자동 업데이트 배포 엔드포인트** | `releases.okrbest.com` (CDN/도메인) | — (읽기 전용) | 없음 (앱이 직접 fetch) | 설치된 앱이 버전 체크용으로 접속 |

- **A**와 **D**는 같은 파일을 다룬다. A가 S3에 업로드하면 D(도메인/CDN)를 통해 앱이 읽는다. A를 설정하지 않으면 자동 업데이트가 동작하지 않는다.
- **B**는 A와 완전히 독립된 별도 버킷이다. Daily develop 빌드를 고정 URL로 제공하는 용도이며, 자동 업데이트와 무관하다.
- **C**는 배포가 아니라 **테스트 결과 저장소**다. 운영에 필수는 아니지만 CI에서 E2E를 돌리려면 필요하다.

아래 섹션은 이 네 경로를 순서대로 설정하는 방법이다. **A는 필수**, **B·C는 선택** (nightly Rainforest 또는 E2E를 실제로 돌릴 때만).

---

## 1. 이 프로젝트의 자동 업데이트 구조 (Release 경로 이해)

A 경로를 만들기 전에 앱이 어떻게 S3에 접근하는지 이해할 필요가 있다.

### 동작 흐름

1. 설치된 앱이 1시간마다 [src/main/updateNotifier.ts:149](../src/main/updateNotifier.ts#L149)에서 다음 URL에 HTTP GET을 보낸다:
   ```
   https://releases.okrbest.com/desktop/latest.txt
   ```
2. 서버는 최신 버전 문자열(예: `5.12.0`) 한 줄을 plain text로 응답한다.
3. 앱은 `semver.gt(remoteVersion, currentVersion)`으로 비교해 업그레이드 여부를 결정한다 ([updateNotifier.ts:168](../src/main/updateNotifier.ts#L168)).
4. 업데이트가 있으면 사용자에게 알림을 띄운다. **다운로드는 수동** — 앱이 직접 파일을 내려받지 않고 사용자가 배포 페이지로 이동해 새 설치본을 받는다.

### 일반적인 Electron 앱과 다른 점

이 프로젝트는 **`electron-updater`를 쓰지 않는다.** 커스텀 HTTP fetch + plain text 비교 방식이다. 그래서 `latest.yml`, `latest-mac.yml` 등은 업로드되긴 하지만 ([cp_artifacts.sh:18](../scripts/cp_artifacts.sh#L18)) **현재 런타임은 읽지 않는다** — 향후 electron-updater로 마이그레이션할 경우를 대비한 흔적이다.

### 업데이트 URL은 빌드 타임 하드코딩

[src/common/config/buildConfig.ts:39](../src/common/config/buildConfig.ts#L39):
```ts
updateNotificationURL: 'https://releases.okrbest.com/desktop',
```

**환경변수로 바꿀 수 없다.** 자체 인프라에서 쓰려면 이 상수를 수정해 재빌드해야 한다. 기본값을 그대로 쓰는 경우에만 아래 가이드의 도메인 예시(`releases.okrbest.com`)를 그대로 따라 한다.

### 채널별 파일명 규칙

[scripts/generate_latest_version.sh](../scripts/generate_latest_version.sh)와 [updateNotifier.ts:143-146](../src/main/updateNotifier.ts#L143-L146)가 같은 규칙을 사용한다. 실행 중인 앱 버전에 따라 다른 파일을 본다:

| 앱 버전 | 참조하는 파일 |
|---|---|
| `5.12.0` (stable) | `latest.txt` |
| `5.12.0-rc.1` | `rc.txt` |
| `5.12.0-nightly.20260413` | `nightly.txt` |
| `5.12.0-mas.1` | `mas.txt` |

**stable을 쓰는 사용자는 rc를 자동으로 보지 않는다.** 채널 업그레이드는 수동 재설치로만 일어난다.

---

## 2. 경로 A — Release 버킷 설정 (필수, OIDC)

정식 릴리즈·RC·MAS 빌드 업로드 경로. 자동 업데이트를 작동시키려면 반드시 설정해야 한다.

### 2-1. 사전 준비

- AWS 계정 (루트 아닌 IAM 권한 있는 사용자)
- 도메인 (예: `releases.okrbest.com`) — 버킷 이름으로 쓸 예정이면 이름도 도메인과 동일해야 한다
- 이 레포의 GitHub 관리자 권한 (Secrets 등록용)

### 2-2. S3 버킷 생성

AWS Console → **S3** → **Create bucket**

| 항목 | 값 |
|---|---|
| Bucket name | `releases.okrbest.com` (또는 원하는 이름) |
| AWS Region | `us-east-1` ([release.yaml:192](../.github/workflows/release.yaml#L192) 고정) |
| Object Ownership | ACLs disabled (Bucket owner enforced) 권장 |
| Block Public Access | **모든 옵션 OFF** (9번 섹션의 CloudFront 구성을 쓰면 다시 켤 수 있음) |
| Bucket Versioning | Disabled |
| Default encryption | SSE-S3 (기본값) |

> ⚠️ Block Public Access 해제는 위험한 작업이다. 이 버킷에는 **릴리즈 artifact와 버전 메타파일만** 올리고 민감 데이터는 절대 넣지 말 것.

### 2-3. 퍼블릭 읽기 정책

버킷 → **Permissions** → **Bucket policy** → Edit (`YOUR-RELEASE-BUCKET` 교체):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-RELEASE-BUCKET/*"
    }
  ]
}
```

### 2-4. CORS 설정 (선택)

앱은 Electron `net.fetch`를 쓰므로 CORS는 이론상 불필요하지만, 향후 웹 대시보드 호환을 위해 설정해 두면 좋다:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag", "Content-Length"],
    "MaxAgeSeconds": 3000
  }
]
```

### 2-5. GitHub OIDC Provider 등록 (AWS 계정당 1회)

AWS Console → **IAM** → **Identity providers** → **Add provider**

| 항목 | 값 |
|---|---|
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

이 Provider는 한 번만 만들면 되고, 같은 AWS 계정 안의 다른 GitHub Actions Role에서도 공유된다.

### 2-6. IAM Policy — Release 업로드용

IAM → **Policies** → **Create policy** → JSON 탭 (`YOUR-RELEASE-BUCKET` 교체):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReleaseS3Upload",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-RELEASE-BUCKET",
        "arn:aws:s3:::YOUR-RELEASE-BUCKET/*"
      ]
    }
  ]
}
```

정책 이름: `OKRBestDesktopReleaseS3Upload`

### 2-7. IAM Role 생성

IAM → **Roles** → **Create role**

1. Trusted entity type: **Web identity**
2. Identity provider: `token.actions.githubusercontent.com`
3. Audience: `sts.amazonaws.com`
4. GitHub organization: `okrbest`
5. GitHub repository: `okrbest-desktop`
6. 위 policy `OKRBestDesktopReleaseS3Upload` 연결
7. Role name: `OKRBestDesktopRelease`

### 2-8. Trust Policy 강화 (보안상 필수)

Role → **Trust relationships** → Edit trust policy. 기본값은 너무 관대하므로 아래로 교체 (`123456789012`와 조직명/레포명 교체):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:okrbest/okrbest-desktop:ref:refs/tags/v*",
            "repo:okrbest/okrbest-desktop:ref:refs/heads/master"
          ]
        }
      }
    }
  ]
}
```

> `master` 브랜치를 추가한 것은 [nightly-main.yml:222](../.github/workflows/nightly-main.yml#L222)이 같은 Role을 사용하기 때문이다. nightly 태그 (`workflow_dispatch`에서 생성)도 이 Role로 release 버킷에 업로드한다. 태그 전용으로만 제한하면 nightly가 실패한다.

### 2-9. GitHub Secrets 등록

레포 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret 이름 | 값 |
|---|---|
| `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | 2-7에서 만든 Role ARN (`arn:aws:iam::...:role/OKRBestDesktopRelease`) |
| `OKRBEST_DESKTOP_RELEASE_BUCKET` | 버킷 이름 (예: `releases.okrbest.com`) |

### 2-10. 도메인 연결

이대로 두면 URL이 `https://YOUR-RELEASE-BUCKET.s3.amazonaws.com/desktop/latest.txt`가 된다. 앱은 `buildConfig.ts`에 하드코딩된 `releases.okrbest.com/desktop/latest.txt`를 보므로 **도메인 연결 없이는 작동하지 않는다.**

**옵션 A: S3 Website Endpoint (간단, HTTP만)**
1. 버킷 이름을 도메인과 정확히 같게 (`releases.okrbest.com`)
2. 버킷 Properties → Static website hosting 활성화
3. Route 53 → A 레코드 → Alias to S3 website endpoint

단점: HTTPS 불가. **프로덕션 비권장.**

**옵션 B: CloudFront + ACM (권장)**
1. **ACM** (반드시 `us-east-1` 리전) → Request certificate → `releases.okrbest.com` → DNS 검증
2. **CloudFront** → Create distribution
   - Origin: S3 버킷 (REST endpoint, 주의: website endpoint 아님)
   - Origin access: **Origin access control (OAC)** — 새로 만들고 "Update bucket policy" 허용
   - Viewer protocol policy: Redirect HTTP to HTTPS
   - Alternate domain name (CNAME): `releases.okrbest.com`
   - Custom SSL certificate: 방금 만든 ACM 인증서
3. **Route 53** → `releases` A 레코드 → Alias to CloudFront distribution
4. 버킷 정책은 CloudFront가 자동으로 OAC 전용으로 업데이트한다 — 이후 Block Public Access를 다시 **ON**으로 돌려도 된다

CloudFront를 쓰면 전 세계 엣지 캐시 혜택을 받지만, 릴리즈 직후 새 `latest.txt`가 즉시 반영되도록 [release.yaml](../.github/workflows/release.yaml)에 invalidation step 추가가 필요하다:

```yaml
- name: release/invalidate-cloudfront
  run: |
    aws cloudfront create-invalidation \
      --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
      --paths "/desktop/latest.txt" "/desktop/rc.txt" "/desktop/nightly.txt" "/desktop/mas.txt"
```

추가 IAM 권한: `cloudfront:CreateInvalidation` on 해당 distribution.

### 2-11. 검증

임시 브랜치에 RC 태그를 찍거나, [release.yaml](../.github/workflows/release.yaml)의 `upload-to-s3` job이 성공하는지 확인:

```bash
aws s3 ls s3://YOUR-RELEASE-BUCKET/desktop/
# 예상:
#   rc.txt
#   5.12.0-rc.1/okrbest-desktop-5.12.0-rc.1-win-x64.msi
#   5.12.0-rc.1/okrbest-desktop-5.12.0-rc.1-mac-universal.dmg

curl https://releases.okrbest.com/desktop/rc.txt
# → 5.12.0-rc.1
```

앱에서 View → Check for Updates 메뉴로 즉시 업데이트 체크를 트리거할 수 있다.

---

## 3. 경로 B — Daily Builds 버킷 설정 (선택, 정적 키)

Rainforest QA나 내부 테스터가 매일 동일한 URL에서 최신 develop 빌드를 받아갈 수 있도록 제공하는 경로. nightly-rainforest 워크플로를 돌릴 때만 필요하다.

이 경로는 **2번과 완전히 독립된** 별개의 버킷·사용자·키를 사용한다. 2번을 아무리 잘 설정해도 B는 작동하지 않는다.

### 3-1. S3 버킷 생성 — 이름이 고정되어 있다

[nightly-rainforest.yml:173](../.github/workflows/nightly-rainforest.yml#L173)에 버킷 이름이 **하드코딩**되어 있다:

```yaml
run: aws s3 cp ./build/ s3://okrbest-desktop-daily-builds/ --acl public-read --cache-control "no-cache" --recursive
```

따라서 버킷 이름은 반드시 `okrbest-desktop-daily-builds`여야 한다. 다른 이름을 쓰고 싶다면 YAML 파일을 직접 수정해 커밋해야 한다.

| 항목 | 값 |
|---|---|
| Bucket name | `okrbest-desktop-daily-builds` (고정) |
| AWS Region | `us-east-1` ([nightly-rainforest.yml:143](../.github/workflows/nightly-rainforest.yml#L143) 고정) |
| Object Ownership | **ACLs enabled (Bucket owner preferred)** — `--acl public-read`를 쓰기 때문에 ACL이 활성화되어 있어야 함 |
| Block Public Access | `Block public access via bucket policy and ACLs`의 ACL 관련 두 옵션 OFF |
| Bucket Versioning | Disabled |

> ⚠️ 이 경로는 워크플로가 개별 오브젝트에 `--acl public-read`를 붙여 업로드한다. 따라서 **ACLs가 활성화된 상태(Object Ownership: Bucket owner preferred)** 여야 한다. 경로 A와 다른 점이다.

### 3-2. IAM User 생성 + 정적 키 발급

경로 B는 OIDC가 아니라 전통적인 IAM User의 액세스 키 페어를 사용한다.

IAM → **Users** → **Create user**
1. User name: `okrbest-desktop-daily-ci`
2. "Provide user access to AWS Management Console" **체크 해제** (프로그래밍 전용)
3. 다음 페이지 → "Attach policies directly" → 아래 3-3에서 만들 policy를 연결
4. 생성 완료 후 User → **Security credentials** 탭 → **Create access key**
5. Use case: **Third-party service** 또는 **Application running outside AWS** 선택
6. 생성된 **Access key ID**와 **Secret access key**를 복사 (Secret은 이 화면에서만 볼 수 있음)

### 3-3. IAM Policy — Daily 업로드용

IAM → **Policies** → **Create policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowDailyBucketUpload",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::okrbest-desktop-daily-builds",
        "arn:aws:s3:::okrbest-desktop-daily-builds/*"
      ]
    }
  ]
}
```

정책 이름: `OKRBestDesktopDailyS3Upload`

> `s3:PutObjectAcl`이 필수다. 워크플로가 `--acl public-read`로 업로드하기 때문에 이 권한이 없으면 `AccessDenied`로 실패한다.

### 3-4. GitHub Secrets 등록

| Secret 이름 | 값 |
|---|---|
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | 3-2에서 복사한 Access key ID (`AKIA...`) |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | 3-2에서 복사한 Secret access key |

### 3-5. 검증

nightly 크론은 매일 04:00 UTC에 돌지만, 수동 트리거 가능:

레포 → Actions → **nightly-builds** → Run workflow

성공 후:
```bash
aws s3 ls s3://okrbest-desktop-daily-builds/
# 예상:
#   macos/okrbest-desktop-daily-develop-mac-universal.dmg
#   win/okrbest-desktop-daily-develop-win-x64.msi

curl -I https://okrbest-desktop-daily-builds.s3.amazonaws.com/macos/okrbest-desktop-daily-develop-mac-universal.dmg
# → 200 OK
```

> 파일명이 `daily-develop-`으로 시작하는 이유: [nightly-rainforest.yml:156-171](../.github/workflows/nightly-rainforest.yml#L156-L171)이 `okrbest-desktop-{version}-` 파일명을 `okrbest-desktop-daily-develop-`로 rename해 덮어쓴다. 버전이 달라도 URL은 고정이라 Rainforest가 항상 같은 주소에서 최신본을 받아갈 수 있다.

---

## 4. 경로 C — E2E Reports 버킷 설정 (선택, 정적 키)

E2E 테스트 결과(HTML 리포트, 스크린샷, 로그)를 저장하는 경로. CI에서 E2E를 돌리지 않으면 필요 없다.

### 4-1. S3 버킷 생성 — 이름 고정

[e2e-functional-template.yml:118](../.github/workflows/e2e-functional-template.yml#L118):
```yaml
env:
  AWS_S3_BUCKET: "okrbest-cypress-report"
```

| 항목 | 값 |
|---|---|
| Bucket name | `okrbest-cypress-report` (고정) |
| AWS Region | `us-east-1` |
| Object Ownership | ACLs disabled 권장 |
| Block Public Access | 팀 정책에 따라 결정 — 리포트 URL을 공개할지 Slack 링크로만 공유할지에 달림 |
| Bucket Versioning | Disabled |

내부 팀만 접근하게 하려면 Block Public Access를 켜두고, 대신 **presigned URL**을 생성해 Slack/webhook으로 공유하도록 [e2e 스크립트](../e2e/)를 구성하는 것이 안전하다. 현재 워크플로는 단순 PUT만 하므로, 접근 방식은 팀 정책에 맡긴다.

### 4-2. IAM User + Policy

IAM → **Users** → Create user: `okrbest-desktop-e2e-ci`

Policy JSON:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowE2EReportUpload",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::okrbest-cypress-report",
        "arn:aws:s3:::okrbest-cypress-report/*"
      ]
    }
  ]
}
```

### 4-3. GitHub Secrets 등록

| Secret 이름 | 값 |
|---|---|
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | 새 IAM User의 Access key ID |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | Secret access key |

이 경로의 다른 E2E 시크릿들(`OKRBEST_DESKTOP_E2E_USER_NAME` 등)은 [DEPLOYMENT_ENVIRONMENT_SETUP.md 8](DEPLOYMENT_ENVIRONMENT_SETUP.md) 참고.

---

## 5. 경로별 대조표 (요약)

셋업 후 누가 뭘 보는지 헷갈릴 때 이 표만 다시 보면 된다.

| 속성 | A. Release | B. Daily | C. E2E |
|---|---|---|---|
| 버킷 이름 | Secret으로 설정 | `okrbest-desktop-daily-builds` (고정) | `okrbest-cypress-report` (고정) |
| 인증 | OIDC (IAM Role) | 정적 키 (IAM User) | 정적 키 (IAM User) |
| ACL 업로드 | `--cache-control "no-cache"`만 | `--acl public-read --cache-control "no-cache"` | 스크립트 의존 |
| Block Public Access | OFF (또는 CloudFront 시 ON) | ACL 옵션만 OFF | 선택 |
| IAM 권한 | `s3:PutObject, PutObjectAcl, GetObject, ListBucket` | `s3:PutObject, PutObjectAcl, ListBucket` | `s3:PutObject, GetObject, ListBucket` |
| GitHub Secret (버킷) | `OKRBEST_DESKTOP_RELEASE_BUCKET` | 없음 (하드코딩) | 없음 (하드코딩) |
| GitHub Secret (인증) | `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID/_SECRET_ACCESS_KEY` | `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID/_SECRET_ACCESS_KEY` |
| 운영 필수성 | **필수** (자동 업데이트) | 선택 (Rainforest 사용 시) | 선택 (E2E 사용 시) |
| 도메인/CDN | `releases.okrbest.com` 연결 권장 | 직접 S3 URL 사용 | 내부 공유 |

---

## 6. 트러블슈팅

### AccessDenied — Release 업로드 실패
- **Trust policy `sub` 조건**이 실제 태그/브랜치와 일치하는지 확인. 예: `refs/tags/v*`로만 제한했는데 nightly `workflow_dispatch`에서 master 브랜치로 실행하면 실패. 2-8의 `master` 브랜치 조건 추가 여부 점검.
- Role policy Resource ARN에서 `/*`가 빠지지 않았는지 확인.
- [release.yaml:185-187](../.github/workflows/release.yaml#L185-L187) job-level `permissions: { id-token: write, contents: read }` 블록이 있는지 확인.

### AccessDenied — Daily 업로드 실패
- **`s3:PutObjectAcl`** 권한이 policy에 있는지 확인. 이게 없으면 `--acl public-read`가 실패한다.
- 버킷의 Object Ownership이 "ACLs disabled"면 `--acl` 플래그가 거부된다. **ACLs enabled**로 바꿔야 한다.
- Block Public Access의 "Block public access to buckets and objects granted through new access control lists (ACLs)" 옵션이 켜져 있으면 ACL 부여가 거부된다.

### 앱이 "No update available"만 계속 표시
- 브라우저에서 `https://releases.okrbest.com/desktop/latest.txt` 직접 열어본다. 200 OK + 버전 문자열이 나와야 함.
- Content-Type이 `text/plain`인지. 바이너리로 업로드됐다면 `--content-type text/plain` 명시.
- 파일에 BOM이나 쓰레기 문자가 없는지 — `semver.gt`가 실패한다.
- CloudFront를 쓴다면 invalidation을 잊지 말 것.
- 사용자가 실행 중인 채널과 실제 업로드된 파일명이 맞는지 (`5.12.0-rc.1` 사용자는 `rc.txt`만 읽는다).

### 사용자 버전이 "올라가지 않는" 것처럼 보임
- 기억할 것: **이 프로젝트의 auto-update는 알림만 띄우고 자동 설치하지 않는다.** 사용자가 직접 새 설치본을 받아야 한다. 의도된 동작.

### OIDC 토큰 실패 — "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- job-level `permissions: id-token: write` 확인.
- AWS의 Identity provider thumbprint가 자동으로 갱신됐는지. GitHub이 인증서를 바꿀 때 가끔 수동 재등록이 필요.

### Daily 빌드가 "예전 파일"만 보여줌
- [nightly-rainforest.yml:156-171](../.github/workflows/nightly-rainforest.yml#L156-L171)의 rename 로직이 성공했는지 로그 확인. 실패하면 `{version}/` 폴더가 지워지지 않고 누적된다.
- 버킷 Versioning이 켜져 있다면 이전 버전 오브젝트가 숨어 있을 수 있다. Disabled 권장.

---

## 7. 보안 강화 (선택)

- **경로 A에 CloudFront OAC 적용** (2-10 옵션 B) → 버킷을 다시 Block Public Access로. 퍼블릭 버킷 유지는 버킷 takeover 시도 등 불필요한 트래픽을 유발한다.
- **경로 B의 정적 키 주기적 rotation**: IAM User → Security credentials → Make inactive → Create new → 새 키로 Secret 업데이트 → 이전 키 삭제. 90일 주기 권장.
- **경로 B를 OIDC로 마이그레이션**: 가장 근본적인 보안 개선. [nightly-rainforest.yml:140-145](../.github/workflows/nightly-rainforest.yml#L140-L145)를 경로 A와 같은 OIDC 방식으로 바꾸면 정적 키를 없앨 수 있다. Trust policy의 `sub` 조건에 `repo:okrbest/okrbest-desktop:ref:refs/heads/master`가 포함되어야 한다 (nightly는 master 기반). 단, 이는 워크플로 수정이 필요한 별도 리팩터링 작업이다.
- **IAM Role 최소 권한 리뷰**: 각 경로에서 `GetObject`는 보통 업로드에 불필요. 최소화하려면 `PutObject` + `ListBucket`만 남겨도 된다.
- **S3 서버 액세스 로깅 또는 CloudTrail 데이터 이벤트** 활성화 → 누가 언제 `latest.txt`를 갱신했는지 감사 기록 확보.

---

## 8. 파일 레이아웃 (최종 상태)

### 경로 A: Release 버킷

```
YOUR-RELEASE-BUCKET/
└── desktop/
    ├── latest.txt              ← stable 채널 포인터 (예: "5.12.0")
    ├── rc.txt                  ← RC 채널 포인터
    ├── nightly.txt             ← nightly 채널 포인터
    ├── mas.txt                 ← MAS 채널 포인터
    ├── latest.yml              ← electron-builder 메타 (현재 미사용)
    ├── latest-mac.yml
    ├── latest-linux.yml
    └── 5.12.0/
        ├── okrbest-desktop-5.12.0-win-x64.msi
        ├── okrbest-desktop-5.12.0-win-arm64.msi
        ├── okrbest-desktop-5.12.0-mac-universal.dmg
        ├── okrbest-desktop-5.12.0-linux-x64.tar.gz
        └── ...
```

### 경로 B: Daily 버킷

```
okrbest-desktop-daily-builds/
├── macos/
│   ├── okrbest-desktop-daily-develop-mac-universal.dmg
│   └── okrbest-desktop-daily-develop-mac-arm64.dmg
└── win/
    ├── okrbest-desktop-daily-develop-win-x64.msi
    └── okrbest-desktop-daily-develop-win-arm64.msi
```

파일명이 버전과 독립적이므로 매일 같은 URL에서 "최신 develop"을 받을 수 있다.

### 경로 C: E2E Reports 버킷

```
okrbest-cypress-report/
└── (E2E 스크립트가 정의한 키 구조, 보통 {branch}/{sha}/ 또는 {test-cycle}/)
```

---

## 참고 자료

- [Configuring OpenID Connect in Amazon Web Services — GitHub Docs](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [aws-actions/configure-aws-credentials — GitHub](https://github.com/aws-actions/configure-aws-credentials)
- [Use IAM roles to connect GitHub Actions to actions in AWS — AWS Security Blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/)
- [Setting permissions for website access — AWS S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteAccessPermissionsReqd.html)
- [Examples of Amazon S3 bucket policies — AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html)
- [Controlling object ownership of objects uploaded to your bucket — AWS S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
