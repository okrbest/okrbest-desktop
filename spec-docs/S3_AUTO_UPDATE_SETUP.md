# AWS S3 & 자동 업데이트 설정 가이드

이 문서는 OKR Best Desktop의 AWS 인프라를 처음 세팅하는 사람을 위한 **순차 실행 가이드**다. 각 STEP을 위에서 아래로 그대로 따라 하면 작동하는 상태가 된다.

이 프로젝트는 세 가지 독립된 S3 경로를 쓴다. **PART A**만 완료하면 정식 릴리즈와 자동 업데이트가 작동한다. PART B·C는 선택이며 필요할 때만 추가한다.

| PART | 목적 | 필수? | 소요 시간 |
|---|---|---|---|
| **A** | 정식 릴리즈 + 자동 업데이트 (OIDC) | ✅ 필수 | ~90분 |
| **B** | Nightly / Rainforest QA 빌드 배포 | 선택 | ~30분 |
| **C** | E2E 테스트 리포트 저장 | 선택 | ~20분 |

> **전제**: AWS Console 로그인 가능, GitHub 레포 관리자 권한, `okrbest.com` DNS 관리 권한 (**`okrbest.com`은 외부 DNS에서 운영 중이며 `releases.okrbest.com` 서브도메인만 AWS 배포용**으로 쓴다. 외부 DNS에 CNAME·검증 레코드를 추가할 수 있어야 함 — 자세한 내용은 STEP 1 참조), 로컬에 AWS CLI 설치.

---

# PART A — 정식 릴리즈 + 자동 업데이트 (필수)

이 PART는 8 STEP이다. 순서대로 따라가면 된다.

- STEP 1: 시작 전 준비물 확인
- STEP 2: S3 버킷 만들기
- STEP 3: GitHub OIDC Provider 등록
- STEP 4: IAM Policy + Role 만들기
- STEP 5: GitHub Secrets 등록
- STEP 6: 도메인 + CloudFront + HTTPS 연결
- STEP 7: 첫 RC 태그로 전체 플로우 검증
- STEP 8: 자동 업데이트 알림 확인

---

## STEP 1. 시작 전 준비물 확인

이 5가지가 모두 준비되어 있는지 먼저 확인한다. 하나라도 없으면 STEP 2로 넘어가기 전에 확보한다.

- [ ] AWS 계정 (루트 아닌 IAM 사용자, 콘솔 접속 가능)
- [ ] 로컬 `aws` CLI 설치 및 자격 증명 설정 완료 (IAM 사용자면 `aws configure`, SSO/IAM Identity Center면 `aws configure sso`)
- [ ] `okrbest.com` 도메인의 DNS 관리 권한 — 이 프로젝트는 **`okrbest.com`을 외부 DNS(도메인 등록업체나 타사 DNS 서비스)에서 운영**하고 `releases.okrbest.com` 서브도메인만 AWS 배포용으로 쓴다. STEP 6에서 외부 DNS에 ACM 검증용 CNAME 1건과 배포용 CNAME 1건을 추가해야 하므로 해당 권한이 필요하다.
- [ ] 이 레포(`okrbest/okrbest-desktop`)의 GitHub 관리자 권한
- [ ] 앱 소스의 [src/common/config/buildConfig.ts:39](../src/common/config/buildConfig.ts#L39)에 하드코딩된 업데이트 URL 확인

### 1-1. AWS CLI 자격 증명이 잘 잡혔는지 확인

가이드의 나머지 STEP이 전부 `aws` CLI 명령에 의존하므로, 본격적으로 들어가기 전에 아래 명령이 **에러 없이** 현재 계정 ARN을 출력하는지 확인한다.

```bash
aws sts get-caller-identity
```

에러가 나면 아래 "NoCredentials / 프로필 관련 트러블슈팅"을 참고한다. 이 확인을 생략하면 STEP 2 검증부터 막혀서 버킷이 정말 만들어졌는지 알 수 없게 된다.

#### NoCredentials / 프로필 관련 트러블슈팅

`aws` 명령이 `Unable to locate credentials` 또는 `NoCredentials` 에러를 내면, **자격 증명이 없는 것이 아니라 CLI가 default 프로필을 찾고 있는데 default가 비어 있는 경우**가 대부분이다. SSO/IAM Identity Center로 로그인한 사람은 자격 증명이 `~/.aws/config`의 `[profile okrbest]` 같은 이름 있는 프로필에만 저장되고 default에는 없다.

세 가지 해결 방법:

**방법 1 — 매 명령에 `--profile` 붙이기** (가장 명시적)
```bash
aws s3 ls s3://releases.okrbest.com/ --profile okrbest
```

**방법 2 — 현재 셸 세션에 고정** (이 가이드를 따라가는 동안 가장 편함)
```bash
export AWS_PROFILE=okrbest
aws sts get-caller-identity   # 이제 --profile 없이 동작
```
셸을 닫으면 사라진다. 영구 적용하려면 `~/.bashrc` 또는 `~/.zshrc`에 같은 줄을 추가한다.

**방법 3 — 해당 프로필을 default로 승격**
`~/.aws/config`의 `[profile okrbest]` 블록을 `[default]`로 바꾸거나 복사한다. 이후에는 프로필 지정 없이도 동작한다.

> **⏱️ SSO 세션 만료**: SSO/Identity Center 프로필은 토큰 수명(보통 8~12시간)이 지나면 `ExpiredToken` 에러로 실패한다. 그때는 `aws sso login --profile okrbest`로 재로그인하면 된다. `--profile`을 생략하려면 `AWS_PROFILE` 환경변수가 먼저 설정되어 있어야 한다.

> **📍 기본 리전 확인**: `aws configure get region --profile okrbest` (또는 default) 결과가 `ap-northeast-2`인지 확인. 아니면 `aws configure set region ap-northeast-2 --profile okrbest`로 맞춘다. 리전이 안 맞으면 STEP 2 버킷 생성 시 `IllegalLocationConstraintException`이 난다.

마지막 항목이 중요하다. 현재 값은 다음과 같다:
```ts
updateNotificationURL: 'https://releases.okrbest.com/desktop',
```

**이 URL은 빌드 타임에 하드코딩된 이 프로젝트의 지정 도메인이다.** 이 가이드 전체가 사용할 도메인은 `releases.okrbest.com`으로 코드에서 이미 정해져 있다 — 단순 예시가 아니라 앱 바이너리가 실제로 접근하는 주소다. 따라서 **S3 버킷 이름, CloudFront Alternate domain, 외부 DNS의 CNAME 레코드가 모두 `releases.okrbest.com`과 정확히 일치해야** 자동 업데이트가 동작한다. 다른 도메인을 쓰려면 먼저 `buildConfig.ts`를 수정하고 앱을 재빌드한 뒤, 아래 가이드의 모든 `releases.okrbest.com`을 해당 값으로 바꿔 적용해야 한다.

---

## STEP 2. S3 버킷 만들기

> **📍 리전 정책**: 이 가이드의 모든 AWS 리소스는 `ap-northeast-2`(Seoul)에 생성한다. 단 **STEP 6-1의 ACM 인증서 한 건만** AWS 서비스 제약으로 `us-east-1`에서 발급해야 한다(그 이유는 6-1에서 설명). 그 외 모든 단계에서 우상단 리전이 **`아시아 태평양(서울) ap-northeast-2`** 로 유지되고 있는지 매 화면마다 확인할 것. 기본 리전이 이미 서울인 계정이라면 자동으로 맞춰져 있다.

### 2-1. 할 일

AWS Console → **S3** → **Create bucket**. AWS Console이 위에서 아래로 보여주는 순서 그대로 아래 값을 입력한다.

| # | 항목 | 입력값 |
|---|---|---|
| 1 | **Bucket type** (버킷 유형) | **General purpose** (글로벌 네임스페이스) |
| 2 | **Bucket name** | `releases.okrbest.com` (도메인과 **정확히 같은 이름**) |
| 3 | **Copy settings from existing bucket** | 사용하지 않음 (공란 유지) |
| 4 | **AWS Region** | **Asia Pacific (Seoul) `ap-northeast-2`** (변경 금지 — 워크플로 고정) |
| 5 | **Object Ownership** | ACLs disabled (Bucket owner enforced) |
| 6 | **Block Public Access** | **모든 4개 옵션 체크 해제** (잠시만 공개) |
| 7 | "I acknowledge..." 경고 | 체크 |
| 8 | **Bucket Versioning** | Disable |
| 9 | **Tags** (선택) | `Project=okrbest-desktop` 권장 (비용 할당용) |
| 10 | **Default encryption** | Amazon S3 managed keys (SSE-S3), Bucket Key **Enable** (기본값) |
| 11 | **Object Lock** | Disable |

**Create bucket** 클릭.

> ⚠️ Block Public Access를 지금 해제하는 이유는 STEP 6에서 CloudFront OAC로 버킷을 다시 비공개로 되돌릴 것이기 때문이다. 잠시만 공개로 둔다.

### 2-2. 각 설정의 의미

표를 그대로 따라 하면 작동하지만, AWS Console에서 낯선 항목을 만났을 때 당황하지 않도록 각 설정이 무슨 의미인지 짧게 정리한다.

- **Bucket type — General purpose vs Directory**: AWS는 2024년부터 버킷 유형을 둘로 나눴다.
  - **General purpose (글로벌 네임스페이스)**: 우리가 아는 기존 S3. 버킷 이름이 전역 고유하고 여러 AZ에 복제된다. 정적 호스팅·CloudFront OAC·`s3://` 표준 경로 모두 이 유형에서만 동작한다. **반드시 이 쪽을 선택한다.**
  - **Directory (계정 리전 네임스페이스, S3 Express One Zone)**: 단일 AZ 저지연 워크로드용. 이름이 `bucket--usw2-az1--x-s3` 같은 특수 형식이고, CloudFront·정적 호스팅과 호환되지 않는다. 릴리즈 배포에는 쓸 수 없다.
- **Bucket name**: 전역 고유해야 한다. 도메인 `releases.okrbest.com`과 **정확히 같은 이름**을 쓰는 이유는 CloudFront Alternate domain + 외부 DNS의 CNAME 레코드와 매칭해 운영자가 혼동하지 않게 하려는 것이다. 다른 이름을 써도 기술적으로는 동작한다.
- **Copy settings from existing bucket**: 기존 버킷의 설정을 복사해 오는 편의 옵션. 초보자는 **반드시 공란으로 둔다** — 실수로 다른 프로젝트의 정책/암호화 설정이 끌려오면 디버깅이 어렵다.
- **AWS Region — 왜 서울인가**: 주 사용자가 한국이므로 `ap-northeast-2`로 고정한다. 계정의 기본 리전도 서울이라 특별히 바꿀 필요가 없다. STEP 6-1의 ACM 인증서만 CloudFront 제약 때문에 `us-east-1`에서 발급하는 단 하나의 예외가 있다.
- **Object Ownership — ACLs disabled**: PART A는 CloudFront OAC(Origin Access Control)만 버킷에 접근하므로 객체별 ACL이 필요 없다. "Bucket owner enforced"가 2023년 이후 신규 버킷의 AWS 권장 기본값이다. (PART B는 워크플로가 `--acl public-read`를 쓰기 때문에 예외적으로 ACL을 켠다 — STEP B1 참고.)
- **Block Public Access — 4개 옵션 구성**: AWS는 공개 경로를 두 층(ACL, 정책)으로 나눠 각각 "신규/모두" 두 옵션으로 총 4개를 둔다.
  1. Block public ACLs (신규 ACL 차단)
  2. Ignore public ACLs (기존 ACL 무시)
  3. Block public bucket policies (신규 정책 차단)
  4. Restrict public access via policies (기존 정책 제한)

  STEP 2에서는 CloudFront가 OAC 정책으로 접근하도록 허용하기 위해 **4개 모두 잠시 해제**하고, STEP 6-3에서 다시 전부 켠다.
- **Bucket Versioning**: 릴리즈 아티팩트는 불변(immutable) 버전 키로 업로드되므로 S3 버전 관리가 불필요하다. 켜면 저장 비용만 늘어난다.
- **Tags**: 비용·리소스 추적용 라벨. 필수 아님. 조직 차원의 청구 태그가 있다면 함께 붙인다.
- **Default encryption — SSE-S3 + Bucket Key**: AWS가 관리하는 키로 저장 시 자동 암호화한다. Bucket Key는 KMS 호출 비용을 대폭 줄이는 캐시 계층이며 SSE-S3에서도 켜두면 이점만 있다. 2023년 이후 기본값이라 그대로 두면 된다.
- **Object Lock**: WORM(Write Once Read Many) 규정 준수용. 이 프로젝트는 법적 보관 요건이 없어 Disable 유지.

### 2-3. 검증

터미널에서:
```bash
aws s3 ls s3://releases.okrbest.com/
```
에러 없이 빈 줄(또는 아무 출력 없음)이 나오면 성공. `NoSuchBucket` 에러가 나면 버킷 이름을 다시 확인한다. `IllegalLocationConstraintException`이 나면 로컬 `aws configure`의 기본 리전이 `ap-northeast-2`로 설정돼 있는지 확인한다.

---

## STEP 3. GitHub OIDC Provider 등록

AWS 계정당 한 번만 해도 되는 작업이다. 이미 다른 GitHub Actions 워크플로용으로 등록돼 있다면 STEP 4로 건너뛴다.

### 3-1. 할 일

AWS Console → **IAM** → 좌측 **Identity providers** → **Add provider**.

| 항목 | 입력값 |
|---|---|
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

**Add provider** 클릭.

### 3-2. 검증

Identity providers 목록에 `token.actions.githubusercontent.com`이 보이면 성공. 상세 페이지에서 Thumbprint가 자동으로 채워져 있는지 확인.

---

## STEP 4. IAM Policy + Role 만들기

Release 업로드 전용 IAM Role을 만든다. OIDC로 GitHub Actions가 이 Role을 assume해서 S3에 업로드한다.

### 4-1. 정책(Policy) 생성

AWS Console → **IAM** → **Policies** → **Create policy** → JSON 탭에 아래를 붙여넣기 (버킷명이 다르면 바꿀 것):

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
        "arn:aws:s3:::releases.okrbest.com",
        "arn:aws:s3:::releases.okrbest.com/*"
      ]
    }
  ]
}
```

**Next** → 정책 이름: `OKRBestDesktopReleaseS3Upload` → **Create policy**.

### 4-2. Role 생성

IAM → **Roles** → **Create role**.

1. **Trusted entity type**: Web identity
2. **Identity provider**: `token.actions.githubusercontent.com`
3. **Audience**: `sts.amazonaws.com`
4. **GitHub organization**: `okrbest`
5. **GitHub repository**: `okrbest-desktop`
6. **GitHub branch**: 비워둠 (다음 단계에서 trust policy를 직접 수정)
7. **Next** → 방금 만든 정책 `OKRBestDesktopReleaseS3Upload` 체크
8. **Next** → **Role name**: `OKRBestDesktopRelease` → **Create role**

### 4-3. Trust Policy 강화 (보안상 필수)

방금 만든 Role 상세 페이지 → **Trust relationships** 탭 → **Edit trust policy**. 전체 JSON을 아래로 교체한다 (`123456789012`를 본인 AWS 계정 ID로 교체):

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

**Update policy** 클릭.

> `sub` 조건이 있어야 **이 레포의 `v*` 태그 또는 master 브랜치**에서만 이 Role을 쓸 수 있다. master 브랜치를 포함시키는 이유는 [nightly-main.yml](../.github/workflows/nightly-main.yml)이 master에서 실행되어 같은 Role로 release 버킷에 업로드하기 때문이다. 이 조건이 없으면 같은 OIDC provider로 다른 레포가 이 Role을 assume해 버킷을 오염시킬 수 있다.

### 4-4. Role ARN 복사

Role 상세 페이지 상단의 `arn:aws:iam::123456789012:role/OKRBestDesktopRelease` 전체를 복사해 둔다. 다음 STEP에서 사용한다.

### 4-5. 검증

Role이 `OKRBestDesktopRelease`로 생성되었고, Trust relationships에 `StringLike`로 `refs/tags/v*`와 `refs/heads/master` 두 줄이 모두 있는지 확인.

---

## STEP 5. GitHub Secrets 등록

레포 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. 두 개를 각각 등록한다.

| Secret Name | Value |
|---|---|
| `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME` | STEP 4-4에서 복사한 Role ARN |
| `OKRBEST_DESKTOP_RELEASE_BUCKET` | `releases.okrbest.com` |

### 검증

Secrets 목록에 위 두 이름이 보이면 된다. 값은 마스킹되어 확인할 수 없다.

---

## STEP 6. 도메인 + CloudFront + HTTPS 연결

이 STEP을 건너뛰면 앱이 `https://releases.okrbest.com/desktop/latest.txt`에 접근할 수 없어 **자동 업데이트가 작동하지 않는다**.

6 STEP 중 가장 복잡하지만 한 번만 하면 된다.

> **📍 외부 DNS 환경에서 진행**
>
> `okrbest.com`은 Route 53이 아닌 **외부 DNS 서비스**에서 운영 중이다. 따라서 CloudFront 콘솔이 제공하는 "Route 53 managed domain 자동 통합"(도메인 입력 → ACM 인증서·DNS 검증·A 레코드 자동 생성)은 쓸 수 없고, 아래 6-1·6-2·6-5를 모두 수동으로 진행한다. 6-1에서 만든 ACM 검증용 CNAME, 6-5에서 만드는 배포용 CNAME **둘 다 외부 DNS에 직접 추가**해야 한다.
>
> 수행 순서: 6-1 → 6-2 → 6-3 → 6-4 → 6-5 → 6-6 → 6-7.

### 6-1. ACM 인증서 발급 (⚠️ 이 단계만 us-east-1)

> **❗ 중요 — 이 가이드에서 유일한 리전 예외**
>
> 이 프로젝트의 모든 버킷·워크플로는 `ap-northeast-2`(Seoul)에 있지만, **ACM 인증서 한 건만은 반드시 `us-east-1`에서 발급**해야 한다.
>
> 이유: CloudFront는 리전 개념이 없는 글로벌 엣지 서비스이고, 대체 도메인(CNAME/Alternate domain name)에 연결할 ACM 인증서를 **오직 us-east-1 리전에서만** 읽어오기 때문이다. 다른 리전에서 발급한 인증서는 CloudFront distribution의 "Custom SSL certificate" 드롭다운에 아예 나타나지 않는다.
>
> **이 단계에서만 리전을 바꾸고, 끝나면 반드시 서울로 되돌린다.**

#### 리전을 us-east-1로 전환

1. AWS Console 우상단 리전 드롭다운 클릭 (현재 `아시아 태평양(서울) ap-northeast-2`)
2. **미국 동부(버지니아 북부) `us-east-1`** 선택
3. 브라우저 주소창이 `...console.aws.amazon.com/acm/home?region=us-east-1...` 로 바뀌었는지 확인 — URL의 `region=` 파라미터가 바뀌지 않으면 좌측 메뉴 → **Certificate Manager**를 다시 눌러 새 리전으로 진입한다
4. 우상단에도 **N. Virginia**로 표시되는지 재확인

#### 인증서 요청

**Certificate Manager (ACM)** → **Request certificate** → **Request a public certificate** → **Next**

| 항목 | 입력값 |
|---|---|
| Fully qualified domain name | `releases.okrbest.com` |
| Validation method | DNS validation |
| Key algorithm | RSA 2048 |
| **Allow export** (내보내기 허용) | **Disabled** (내보내기 비활성화) |

**Request**.

> **💡 "Allow export"를 Disabled로 두는 이유**: CloudFront는 ACM에서 인증서를 직접 참조하므로 Private key를 내보낼 필요가 없다. Disabled는 **무료**이며 AWS가 자동 갱신한다. Enabled는 PEM 파일을 다운로드해 AWS 외부(온프레미스, 타 클라우드 등)에서도 쓸 수 있게 해주지만 **인증서당 월 $15가 청구되고**, 내보낸 키가 유출될 위험이 생기며, 자동 갱신 후 수동 재배포 부담도 따른다. 이 프로젝트는 전부 CloudFront 안에서 끝나므로 반드시 Disabled.

#### DNS 검증 레코드 추가 (외부 DNS)

Request 직후 인증서 목록에서 방금 만든 인증서를 클릭하면 **Domains** 섹션에 검증용 CNAME 레코드가 표시된다.

> ⚠️ `okrbest.com`이 Route 53에 없으므로 "Create records in Route 53" 버튼은 **쓸 수 없다** (버튼이 비활성화되거나 에러가 난다). 외부 DNS에 직접 추가한다.

1. ACM 콘솔 → 인증서 상세 → **Domains** → 표시되는 **CNAME name**과 **CNAME value** 두 값을 복사한다.
   - CNAME name 예시: `_abc123def456.releases.okrbest.com.`
   - CNAME value 예시: `_xyz789.xxxx.acm-validations.aws.`
2. 외부 DNS 관리 콘솔(도메인 등록업체 또는 타사 DNS) → `okrbest.com` 존 → 레코드 추가:
   - **Type**: CNAME
   - **Host / Name**: `_abc123def456.releases` (DNS 제공자에 따라 존 루트를 자동으로 append하므로 끝의 `.okrbest.com.`은 생략하는 경우가 많다 — 제공자 문서 확인)
   - **Value / Points to**: ACM이 준 값 그대로 (끝의 `.` 포함 여부는 제공자 규칙을 따름)
   - **TTL**: 300~3600
3. 저장 후 5~30분 기다리면 ACM 인증서 Status가 **Pending validation** → **Issued**로 바뀐다. `dig CNAME _abc123def456.releases.okrbest.com`으로 전파 여부를 중간에 확인 가능.

> 이 검증용 CNAME 레코드는 **인증서가 Issued된 뒤에도 삭제하지 말 것.** ACM이 자동 갱신할 때 다시 검증하므로 삭제하면 갱신이 실패한다.

#### 🔙 발급 후 반드시 서울 리전으로 되돌리기

인증서가 **Issued** 상태가 되었으면 **우상단 리전을 다시 `아시아 태평양(서울) ap-northeast-2`로 되돌린다.** 되돌리지 않으면 STEP 6-2 이후에 버지니아 리전에서 엉뚱한 CloudFront distribution/S3 버킷 작업을 하게 될 수 있다.

CloudFront 생성(6-2) 자체는 리전 무관(글로벌 서비스)이라 어느 리전에서도 진행할 수 있지만, 혼란을 막기 위해 이 가이드 전체는 **서울 리전에서 작업한다**는 규칙을 유지한다.

### 6-2. CloudFront Distribution 생성

> **📍 2024년 말 개편된 마법사 UI 기준**
>
> AWS는 CloudFront distribution 생성 화면을 단일 폼에서 **6단계 마법사**(`console.aws.amazon.com/cloudfront/v4/home`)로 개편했다. 구 UI의 단일 폼은 이 섹션과 필드 구성이 달라 보이지만 최종 결과(S3 + OAC + HTTPS + Custom SSL)는 동일하다. 새 UI에서는 OAC·Viewer policy·Cache policy·S3 bucket policy 업데이트가 자동화되어 수동 입력이 크게 줄었다.

AWS Console → **CloudFront** → **Create distribution**.

#### 1단계 — Choose a plan

안내/요금제 화면이 표시되면 기본값 그대로 두고 **Next**. (AWS가 이 화면에 신기능 안내나 플랜 선택을 넣을 수 있으므로 옵션이 보이면 **Standard** 또는 기본 선택을 유지한다.)

#### 2단계 — Get started

**Distribution options**

| 항목 | 입력값 |
|---|---|
| Distribution name | `okrbest-desktop-releases` (자유 — 태그 `Name`으로만 저장됨) |
| Description | 비워둠 |
| Distribution type | **Single website or app** (기본 선택. Multi-tenant는 여러 도메인이 한 distribution을 공유하는 SaaS용이라 이 프로젝트엔 불필요) |

**Domain**

| 항목 | 입력값 |
|---|---|
| Route 53 managed domain | **비워둔다** |

> ⚠️ 이 필드는 Route 53 호스티드존이 같은 AWS 계정에 있을 때만 동작한다. `okrbest.com`은 외부 DNS에 있으므로 여기에 입력하면 "No matching Route 53 hosted zone" 에러가 나거나 distribution 생성이 막힌다. **반드시 비워두고 진행**한다. Alternate domain name과 SSL 인증서는 distribution이 만들어진 뒤 설정 화면에서 별도로 연결한다(아래 "생성 직후 확인 사항" 참고).

**Tags** (선택) — `Project=okrbest-desktop` 권장.

**Next**.

#### 3단계 — Specify origin

| 항목 | 입력값 |
|---|---|
| Origin type | **Amazon S3** |
| Origin | **Browse S3** 버튼 클릭 → `releases.okrbest.com` 버킷 선택 |
| Settings | **Use recommended origin settings** (기본 선택) |

> **💡 "Use recommended origin settings"가 자동으로 적용하는 항목** (구 UI에서 수동으로 고르던 것들):
> - **Origin Access Control(OAC)** 신규 생성 및 연결
> - Viewer protocol policy: **Redirect HTTP to HTTPS**
> - Allowed HTTP methods: **GET, HEAD**
> - Cache policy: **CachingOptimized**
>
> 이 프로젝트의 워크로드(정적 릴리즈 아티팩트 배포)에는 이 기본값으로 충분하다. 개별 값을 바꾸고 싶을 때만 **Customize origin settings**로 전환한다.

**Next**.

#### 4단계 — Enable security

AWS WAF 보호 기능을 붙일지 묻는다. **Do not enable security protections** 선택 → **Next**.

(릴리즈 아티팩트 정적 배포에 WAF는 과도하다. 비용만 늘어나므로 끄고 진행. 필요해지면 나중에 distribution 설정에서 추가 가능.)

#### 5단계 — Get TLS certificate

2단계에서 Route 53 managed domain을 비워뒀으므로 이 단계는 **표시되지 않고 건너뛴다**. (Route 53 도메인을 입력한 경우에만 나타나는 자동 프로비저닝 단계다.) 바로 6단계로 간다.

#### 6단계 — Review and create

입력값 검토 후 **Create distribution**.

#### 생성 직후 확인 사항

- 상단에 "S3 bucket policy was updated" 류의 성공 배너가 뜬다. 구 UI의 "Copy policy → 수동 붙여넣기" 단계가 **자동화**되어 사라졌다.
- S3 → `releases.okrbest.com` → **Permissions** → **Bucket policy**에 `AllowCloudFrontServicePrincipalReadOnly`(Principal: `cloudfront.amazonaws.com`) Statement가 들어갔는지 확인.

Distribution Status가 **Deploying**으로 뜬다. **Deployed**로 바뀔 때까지 5~15분 걸린다. 기다리는 동안 아래 "Alternate domain + SSL 인증서 연결"을 먼저 진행해도 된다.

#### Alternate domain name + SSL 인증서 연결 (외부 DNS 도메인용 필수 단계)

2단계에서 도메인을 비워뒀기 때문에 지금 distribution은 `dXXXXXXXX.cloudfront.net` 기본 도메인으로만 응답한다. `releases.okrbest.com`으로 접근 가능하게 하려면 Alternate domain name과 6-1에서 만든 인증서를 수동으로 붙여야 한다.

1. CloudFront → 방금 만든 distribution 선택 → **General** 탭 → **Settings** 옆 **Edit** (또는 **Alternate domain names** 섹션의 **Add a domain** 버튼).
2. **Alternate domain name (CNAME)** 필드에 `releases.okrbest.com` 입력.
3. **Custom SSL certificate** 드롭다운 → STEP 6-1에서 us-east-1에 발급한 `releases.okrbest.com` 인증서 선택.
   - 드롭다운에 인증서가 보이지 않으면 6-1의 Status가 **Issued**인지, 리전이 us-east-1인지 재확인.
4. **Save changes**.

저장 후 distribution이 다시 **Deploying** 상태가 되며 5~10분 재배포된다.

### 6-3. S3 Block Public Access 다시 켜기

이제 CloudFront OAC만 버킷에 접근하므로 퍼블릭 접근을 차단해도 된다.

S3 → `releases.okrbest.com` 버킷 → **Permissions** → **Block public access (bucket settings)** → **Edit** → **Block all public access** 체크 → Save.

### 6-4. CloudFront 배포 대기

CloudFront 목록에서 방금 만든 distribution의 Status가 **Deployed**가 될 때까지 기다린다 (5~15분). 배포가 끝나면 도메인 이름이 `d1234xxxxx.cloudfront.net` 형태로 표시된다.

### 6-5. 외부 DNS에 CNAME 레코드 추가

`releases.okrbest.com` → CloudFront 기본 도메인(`dXXXXXXXX.cloudfront.net`)을 가리키는 CNAME을 외부 DNS에 만든다.

> AWS Route 53이라면 Alias(A) 레코드로 비용 없이 루트 도메인에도 연결할 수 있지만, 외부 DNS에서는 Alias가 존재하지 않는다. 대신 표준 **CNAME**을 쓴다. 서브도메인(`releases`)이라 CNAME이 문제없이 동작한다.

#### CloudFront 기본 도메인 확인

CloudFront → distribution 목록 → 방금 만든 distribution의 **Domain name** 컬럼 복사 (예: `d1a2b3c4d5e6f7.cloudfront.net`).

#### 외부 DNS에서 CNAME 추가

외부 DNS 관리 콘솔(도메인 등록업체 또는 타사 DNS) → `okrbest.com` 존 → 새 레코드 추가:

| 항목 | 값 |
|---|---|
| Type | CNAME |
| Host / Name | `releases` (또는 제공자 규칙에 따라 `releases.okrbest.com`) |
| Value / Points to | `d1a2b3c4d5e6f7.cloudfront.net` (위에서 복사한 CloudFront 도메인) |
| TTL | 300~3600 |

> 제공자에 따라 끝의 `.` 유무가 다르고, Host 필드에 서브도메인만 적는 곳도 있고 FQDN 전체를 적는 곳도 있다. 제공자 문서나 기존 레코드 예시를 참고.

#### 검증

```bash
dig CNAME releases.okrbest.com
# ANSWER SECTION에 d1a2b3c4d5e6f7.cloudfront.net이 보이면 전파 완료
```

전파까지 보통 1~5분, TTL에 따라 최대 수십 분 걸릴 수 있다.

### 6-6. CloudFront invalidation 권한 추가 (선택이지만 권장)

릴리즈 직후 새 `latest.txt`를 즉시 반영하려면 워크플로가 CloudFront 캐시를 무효화해야 한다.

STEP 4-1의 정책에 다음 Statement를 추가한다 (`DISTRIBUTION_ID`는 방금 만든 distribution의 ID):

```json
{
  "Sid": "AllowCloudFrontInvalidation",
  "Effect": "Allow",
  "Action": "cloudfront:CreateInvalidation",
  "Resource": "arn:aws:cloudfront::123456789012:distribution/DISTRIBUTION_ID"
}
```

그런 다음 [release.yaml](../.github/workflows/release.yaml)의 `upload-to-s3` job 끝에 다음 step을 추가하고 커밋:

```yaml
      - name: release/invalidate-cloudfront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/desktop/latest.txt" "/desktop/rc.txt" "/desktop/nightly.txt" "/desktop/mas.txt"
```

GitHub Secret `CLOUDFRONT_DISTRIBUTION_ID`도 추가 등록한다.

### 6-7. 검증

로컬 터미널에서:
```bash
# 임시 테스트 파일 업로드
echo "0.0.0" > /tmp/latest.txt
aws s3 cp /tmp/latest.txt s3://releases.okrbest.com/desktop/latest.txt --cache-control "no-cache"

# HTTPS로 접근
curl https://releases.okrbest.com/desktop/latest.txt
# 기대 출력: 0.0.0

# HTTP는 HTTPS로 리다이렉트되어야 함
curl -I http://releases.okrbest.com/desktop/latest.txt
# Location: https://releases.okrbest.com/... 확인

# 임시 파일 삭제
aws s3 rm s3://releases.okrbest.com/desktop/latest.txt
```

세 명령이 모두 정상 응답하면 PART A의 AWS 쪽 세팅은 완료다.

> **DNS 전파 지연으로 실패하는 경우**: 외부 DNS에 추가한 CNAME 레코드의 TTL에 따라 최대 수십 분까지 전파 대기가 필요할 수 있다. `dig releases.okrbest.com`로 확인.

---

## STEP 7. 첫 RC 태그로 전체 플로우 검증

이제 실제 워크플로가 AWS와 잘 연동되는지 확인한다.

### 7-1. RC 태그 찍기

로컬에서:
```bash
git checkout -b release-test-$(date +%Y%m%d)  # 또는 기존 release-X.Y 브랜치
./scripts/release.sh start                    # rc.1 태그 생성
git push --follow-tags
```

GitHub → Actions 탭에서 [release.yaml](../.github/workflows/release.yaml) 워크플로가 시작되는지 확인. 15~30분 정도 걸린다.

### 7-2. S3 업로드 확인

성공 후:
```bash
aws s3 ls s3://releases.okrbest.com/desktop/
```

기대 출력 (버전은 다를 수 있음):
```
                           PRE 5.12.0-rc.1/
2026-04-13 10:23:45         15 rc.txt
2026-04-13 10:23:40       1234 latest.yml
...
```

```bash
curl https://releases.okrbest.com/desktop/rc.txt
# 기대: 5.12.0-rc.1 (또는 방금 찍은 버전)
```

### 7-3. 만약 실패한다면

- `AccessDenied`: STEP 4-3의 Trust Policy `sub` 조건에 `refs/tags/v*`가 포함됐는지 재확인. 브랜치에서 `workflow_dispatch`로 돌렸다면 `refs/heads/...`도 필요.
- `The role ... cannot be assumed`: STEP 4-4의 Role ARN이 STEP 5의 Secret 값과 정확히 일치하는지 확인.
- `NoSuchBucket`: STEP 5의 `OKRBEST_DESKTOP_RELEASE_BUCKET` 값에 오타가 없는지 확인.
- 워크플로가 아예 트리거되지 않음: 태그 이름이 `v[0-9]+.[0-9]+.[0-9]+(-rc.[0-9]+)?` 패턴에 맞는지 확인 ([release.yaml:6-7](../.github/workflows/release.yaml#L6-L7)).

---

## STEP 8. 자동 업데이트 알림 확인

마지막 검증: 실제 앱이 새 버전을 감지하는지 확인.

### 8-1. 테스트 시나리오

방금 찍은 RC 태그 빌드의 MSI/DMG를 다운로드해 설치한다. 설치 후 앱을 실행한 상태에서:

```bash
# 앱 버전보다 높은 가짜 버전으로 rc.txt를 임시 덮어쓰기
echo "99.0.0-rc.1" > /tmp/rc.txt
aws s3 cp /tmp/rc.txt s3://releases.okrbest.com/desktop/rc.txt --cache-control "no-cache"

# CloudFront 캐시가 걸려 있으면 invalidation
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/desktop/rc.txt"
```

설치된 앱에서 **View 메뉴 → Check for Updates** 클릭.

### 8-2. 기대 결과

"새 업데이트가 있습니다: 99.0.0-rc.1" 알림이 뜬다. 뜨면 성공.

### 8-3. 원상복구 (중요)

테스트 후 반드시 실제 버전으로 되돌린다:
```bash
echo "5.12.0-rc.1" > /tmp/rc.txt   # 실제 RC 버전
aws s3 cp /tmp/rc.txt s3://releases.okrbest.com/desktop/rc.txt --cache-control "no-cache"
```

### 8-4. 만약 "No update available"만 뜬다면

- 브라우저에서 `https://releases.okrbest.com/desktop/rc.txt` 직접 열어 200 OK와 버전 문자열이 보이는지 확인.
- 설치된 앱의 버전 문자열이 `-rc` 접미사를 포함하는지 확인. stable 앱은 `latest.txt`만 본다.
- 파일에 BOM이나 쓰레기 문자가 없는지 (`cat -A /tmp/rc.txt`로 확인).
- View → Developer Tools for Application Wrapper → Console에서 "UpdateNotifier" 로그 확인.

---

## PART A 완료 체크리스트

아래 8개가 모두 체크되면 정식 릴리즈 + 자동 업데이트가 완전히 작동하는 상태다.

- [ ] STEP 2: `releases.okrbest.com` S3 버킷 생성됨
- [ ] STEP 3: GitHub OIDC provider가 AWS에 등록됨
- [ ] STEP 4: IAM Role `OKRBestDesktopRelease` 생성, Trust Policy에 `refs/tags/v*` + `refs/heads/master` 조건 포함
- [ ] STEP 5: GitHub Secrets 2개 (`OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME`, `OKRBEST_DESKTOP_RELEASE_BUCKET`) 등록
- [ ] STEP 6: CloudFront + ACM + 외부 DNS CNAME 연결, `https://releases.okrbest.com/desktop/` 접근 가능
- [ ] STEP 7: 실제 RC 태그로 워크플로 실행 성공, S3에 아티팩트 업로드 확인
- [ ] STEP 8: 앱에서 가짜 버전으로 업데이트 알림 확인 후 원상복구
- [ ] `DISTRIBUTION_ID`와 IAM 정책에 CloudFront invalidation 권한 추가 (6-6)

**여기까지 완료되면 PART A는 끝이다.** PART B·C는 Nightly 또는 E2E를 돌릴 필요가 있을 때만 진행한다.

---

# PART B — Nightly / Rainforest QA 빌드 (선택)

Rainforest QA나 내부 테스터가 매일 최신 develop 빌드를 **고정된 URL**에서 받아갈 수 있게 하는 경로다. PART A와 **완전히 독립**되어 있다.

- STEP B1: Daily 버킷 만들기 (이름 고정)
- STEP B2: 전용 IAM User + Access Key 발급
- STEP B3: IAM Policy 생성
- STEP B4: GitHub Secrets 등록
- STEP B5: 수동 실행으로 검증

소요 시간: 약 30분.

---

## STEP B1. Daily 버킷 만들기

### B1-1. 할 일

버킷 이름이 [nightly-rainforest.yml:173](../.github/workflows/nightly-rainforest.yml#L173)에 **하드코딩**되어 있으므로 반드시 아래 이름을 써야 한다.

AWS Console 우상단 리전이 **`아시아 태평양(서울) ap-northeast-2`** 인지 먼저 확인한다. → **S3** → **Create bucket**.

| # | 항목 | 입력값 |
|---|---|---|
| 1 | **Bucket type** | **General purpose** (글로벌 네임스페이스) |
| 2 | **Bucket name** | `okrbest-desktop-daily-builds` (**고정**) |
| 3 | **Copy settings from existing bucket** | 공란 유지 |
| 4 | **AWS Region** | **Asia Pacific (Seoul) `ap-northeast-2`** (고정) |
| 5 | **Object Ownership** | **ACLs enabled** → **Bucket owner preferred** (PART A와 다름 — 워크플로가 `--acl public-read`를 씀) |
| 6 | **모든 퍼블릭 액세스 차단** (상위 체크박스) | **체크 해제** — 아래 4개 개별 옵션을 각각 제어하기 위해 마스터 체크를 먼저 끈다 |
| 7 | 개별 옵션 ① **새 ACL(액세스 제어 목록)을 통해 부여된 버킷 및 객체에 대한 퍼블릭 액세스 차단** | **체크 해제** (ACL 기반) |
| 8 | 개별 옵션 ② **임의의 ACL(액세스 제어 목록)을 통해 부여된 버킷 및 객체에 대한 퍼블릭 액세스 차단** | **체크 해제** (ACL 기반) |
| 9 | 개별 옵션 ③ **새 퍼블릭 버킷 또는 액세스 지점 정책을 통해 부여된 버킷 및 객체에 대한 퍼블릭 액세스 차단** | **체크 유지** (정책 기반) |
| 10 | 개별 옵션 ④ **임의의 퍼블릭 버킷 또는 액세스 지점 정책을 통해 부여된 버킷 및 객체에 대한 퍼블릭 및 교차 계정 액세스 차단** | **체크 유지** (정책 기반) |
| 11 | 하단 경고 박스의 **"현재 설정으로 인해 이 버킷과 그 안에 포함된 객체가 퍼블릭 상태가 될 수 있음을 알고 있습니다."** | **체크** (체크하지 않으면 저장 불가) |
| 12 | **Bucket Versioning** | Disable |
| 13 | **Tags** | 선택 (`Project=okrbest-desktop`, `Purpose=daily-build` 권장) |
| 14 | **Default encryption** | Amazon S3 managed keys (SSE-S3), Bucket Key Enable (기본값) |
| 15 | **Object Lock** | Disable |

**Create bucket**.

### B1-2. 왜 PART A와 다른가

- PART A는 CloudFront OAC 뒤에 숨기므로 ACL 불필요
- PART B는 워크플로가 개별 오브젝트를 `--acl public-read`로 업로드하므로 ACL이 켜져 있어야 함
- 이 차이를 지키지 않으면 `AccessControlListNotSupported` 에러로 실패함
- Block Public Access 4개 옵션 중 **ACL 기반 2개만** 해제하는 이유: 워크플로가 `--acl public-read`로 객체를 공개해야 하지만, 버킷 정책 기반의 public 접근은 원치 않기 때문이다. 정책 기반 2개를 같이 해제하면 실수로 버킷 전체가 정책을 통해 공개될 위험이 커진다.

---

## STEP B2. Daily 전용 IAM User + Access Key

OIDC가 아닌 **정적 키**를 쓴다. 워크플로가 이렇게 생겼기 때문.

### B2-1. 할 일

IAM → **Users** → **Create user**.

| 항목 | 입력값 |
|---|---|
| User name | `okrbest-desktop-daily-ci` |
| Provide user access to the AWS Management Console | **체크 해제** (프로그래밍 전용) |

**Next** → **Attach policies directly** → **Next** (정책은 다음 STEP에서 만들어 연결) → **Create user**.

### B2-2. Access Key 발급

방금 만든 User 클릭 → **Security credentials** 탭 → **Create access key**.

| 항목 | 입력값 |
|---|---|
| Use case | Third-party service (또는 Application running outside AWS) |
| "I understand..." | 체크 |

**Next** → Description: `GitHub Actions - nightly rainforest` → **Create access key**.

**⚠️ 이 화면에서만 Secret access key를 볼 수 있다.** 닫기 전에 두 값을 안전한 곳에 복사:
- Access key ID (`AKIA...`)
- Secret access key

---

## STEP B3. IAM Policy 생성 및 연결

### B3-1. 정책 생성

IAM → **Policies** → **Create policy** → JSON:

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

**Next** → 이름: `OKRBestDesktopDailyS3Upload` → **Create policy**.

> `s3:PutObjectAcl`이 반드시 있어야 한다. 없으면 `--acl public-read`가 `AccessDenied`로 실패한다.

### B3-2. User에 정책 연결

IAM → Users → `okrbest-desktop-daily-ci` → **Permissions** 탭 → **Add permissions** → **Attach policies directly** → `OKRBestDesktopDailyS3Upload` 검색/체크 → **Next** → **Add permissions**.

---

## STEP B4. GitHub Secrets 등록

레포 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. 두 개 등록.

| Secret Name | Value |
|---|---|
| `OKRBEST_DESKTOP_DAILY_AWS_ACCESS_KEY_ID` | B2-2에서 복사한 Access key ID |
| `OKRBEST_DESKTOP_DAILY_AWS_SECRET_ACCESS_KEY` | B2-2에서 복사한 Secret access key |

---

## STEP B5. 수동 실행으로 검증

Nightly 크론은 매일 04:00 UTC에 돌지만 즉시 검증하려면:

레포 → **Actions** → **nightly-builds** → **Run workflow** → **Run workflow** 버튼.

약 30~45분 후 완료되면:

```bash
aws s3 ls s3://okrbest-desktop-daily-builds/
```

기대 출력:
```
                           PRE macos/
                           PRE win/
```

```bash
aws s3 ls s3://okrbest-desktop-daily-builds/win/
# 예: okrbest-desktop-daily-develop-win-x64.msi
```

HTTPS로 직접 다운로드:
```bash
curl -I https://okrbest-desktop-daily-builds.s3.amazonaws.com/win/okrbest-desktop-daily-develop-win-x64.msi
# HTTP/1.1 200 OK
```

파일명이 **버전 번호가 아닌 `daily-develop-`으로 고정**되는 이유: [nightly-rainforest.yml:156-171](../.github/workflows/nightly-rainforest.yml#L156-L171)이 버전명 파일을 rename해 덮어쓴다. Rainforest가 매일 같은 URL에서 최신본을 받을 수 있도록 한 설계.

### 만약 실패한다면

- `AccessControlListNotSupported`: 버킷 Object Ownership이 "ACLs disabled"로 돼 있음. B1-1 대로 "Bucket owner preferred"로 변경.
- `AccessDenied (PutObjectAcl)`: 정책에 `s3:PutObjectAcl`이 없음. B3-1 재확인.
- `InvalidAccessKeyId`: B4의 Secret 값에 앞뒤 공백이 붙었는지 확인.

---

## PART B 완료 체크리스트

- [ ] `okrbest-desktop-daily-builds` 버킷 생성, ACLs enabled
- [ ] IAM User `okrbest-desktop-daily-ci` 생성, Access Key 발급
- [ ] 정책 `OKRBestDesktopDailyS3Upload` 생성 및 User에 연결
- [ ] GitHub Secrets 2개 등록
- [ ] 수동 워크플로 실행 성공, `daily-develop-*` 파일 HTTPS 다운로드 가능

---

# PART C — E2E 테스트 리포트 저장 (선택)

Playwright E2E 테스트 결과(HTML 리포트, 스크린샷)를 저장하는 경로다. CI에서 E2E를 돌리지 않으면 필요 없다.

- STEP C1: E2E 리포트 버킷 만들기 (이름 고정)
- STEP C2: 전용 IAM User + Access Key
- STEP C3: IAM Policy 생성
- STEP C4: GitHub Secrets + 기타 E2E 환경변수 등록
- STEP C5: E2E 워크플로 수동 실행

소요 시간: 약 20분.

---

## STEP C1. E2E 리포트 버킷 만들기

버킷 이름이 [e2e-functional-template.yml:118](../.github/workflows/e2e-functional-template.yml#L118)에 하드코딩되어 있다.

AWS Console 우상단 리전이 **`아시아 태평양(서울) ap-northeast-2`** 인지 확인 → **S3** → **Create bucket**.

| # | 항목 | 입력값 |
|---|---|---|
| 1 | **Bucket type** | **General purpose** (글로벌 네임스페이스) |
| 2 | **Bucket name** | `okrbest-cypress-report` (**고정**) |
| 3 | **Copy settings from existing bucket** | 공란 유지 |
| 4 | **AWS Region** | **Asia Pacific (Seoul) `ap-northeast-2`** |
| 5 | **Object Ownership** | ACLs disabled (Bucket owner enforced) |
| 6 | **Block Public Access** | **4개 모두 체크** (내부 공유용, 완전 비공개) |
| 7 | "I acknowledge..." | 해당 없음 (Block Public Access를 켰으므로 경고가 뜨지 않음) |
| 8 | **Bucket Versioning** | Disable |
| 9 | **Tags** | 선택 (`Project=okrbest-desktop`, `Purpose=e2e-report` 권장) |
| 10 | **Default encryption** | Amazon S3 managed keys (SSE-S3), Bucket Key Enable (기본값) |
| 11 | **Object Lock** | Disable |

**Create bucket**.

> 내부 팀만 볼 수 있도록 비공개로 둔다. 리포트 URL을 공유하려면 presigned URL을 생성하거나 VPN 뒤로 두는 방식을 쓴다. 공개로 돌리면 테스트 스크린샷에 계정 정보가 노출될 수 있으므로 권장하지 않는다.

---

## STEP C2. E2E 전용 IAM User + Access Key

PART B와 동일한 방식.

IAM → **Users** → **Create user** → 이름 `okrbest-desktop-e2e-ci` → 콘솔 접속 체크 해제 → **Create user**.

User → **Security credentials** → **Create access key** → Third-party service → Description `GitHub Actions - e2e reports` → **Create**.

**Access key ID**와 **Secret access key** 복사.

---

## STEP C3. IAM Policy

IAM → **Policies** → **Create policy** → JSON:

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

이름: `OKRBestDesktopE2EReportUpload` → **Create policy**.

IAM → Users → `okrbest-desktop-e2e-ci` → Permissions → **Attach policies** → `OKRBestDesktopE2EReportUpload` 선택 → **Add**.

---

## STEP C4. GitHub Secrets 등록

E2E는 AWS 외에도 Zephyr, 테스트 계정 등 **총 7개 시크릿**이 필요하다.

레포 → **Settings** → **Secrets and variables** → **Actions** → 각각 **New repository secret**:

| Secret Name | Value |
|---|---|
| `OKRBEST_DESKTOP_E2E_AWS_ACCESS_KEY_ID` | C2에서 복사한 Access key ID |
| `OKRBEST_DESKTOP_E2E_AWS_SECRET_ACCESS_KEY` | C2에서 복사한 Secret access key |
| `OKRBEST_DESKTOP_E2E_USER_NAME` | E2E가 로그인할 테스트 계정 아이디 |
| `OKRBEST_DESKTOP_E2E_USER_CREDENTIALS` | 위 계정의 비밀번호 |
| `OKRBEST_DESKTOP_E2E_TEST_CYCLE_LINK_PREFIX` | Zephyr 테스트 사이클 URL prefix (Zephyr 미사용 시 빈 값) |
| `OKRBEST_DESKTOP_E2E_WEBHOOK_URL` | 결과 알림 Mattermost webhook URL |
| `OKRBEST_DESKTOP_E2E_ZEPHYR_API_KEY` | Zephyr API Key (Zephyr 미사용 시 빈 값) |

**테스트 계정 준비**: 테스트용 OKR Best 서버 인스턴스에서 E2E 전용 계정을 만들어두고 그 값을 넣는다. 프로덕션 계정을 쓰면 안 된다.

---

## STEP C5. E2E 워크플로 수동 실행

레포 → **Actions** → **Electron Playwright Tests** → **Run workflow**. 입력 폼:

| 입력 | 값 |
|---|---|
| version_name | 테스트할 브랜치/태그 (예: `master`) |
| instance_details | 플랫폼별 JSON 배열 (E2E 문서 참고) |
| OKRBEST_SERVER_VERSION | 테스트 대상 서버 버전 |

실행 후 완료되면:
```bash
aws s3 ls s3://okrbest-cypress-report/ --recursive | head
```

어떤 파일이든 업로드됐으면 성공. 실제 키 구조는 E2E 스크립트(`e2e/` 디렉토리)에서 결정한다.

---

## PART C 완료 체크리스트

- [ ] `okrbest-cypress-report` 버킷 생성 (비공개)
- [ ] IAM User `okrbest-desktop-e2e-ci` + Access Key
- [ ] 정책 `OKRBestDesktopE2EReportUpload` 연결
- [ ] GitHub Secrets 7개 모두 등록
- [ ] E2E 워크플로 수동 실행 성공

---

# 부록 A. 세 경로 한눈에 보기

설정 후 혼란스러울 때 이 표를 참고한다.

| 속성 | PART A — Release | PART B — Daily | PART C — E2E |
|---|---|---|---|
| 버킷 이름 | Secret 지정 (`releases.okrbest.com`) | `okrbest-desktop-daily-builds` (고정) | `okrbest-cypress-report` (고정) |
| 인증 방식 | OIDC (IAM Role) | 정적 키 (IAM User) | 정적 키 (IAM User) |
| Object Ownership | ACLs disabled | **ACLs enabled** | ACLs disabled |
| Public 접근 | CloudFront OAC 경유 (버킷 자체는 비공개) | 버킷 ACL 기반 공개 | 완전 비공개 |
| IAM 권한 | `PutObject, PutObjectAcl, GetObject, ListBucket` | `PutObject, PutObjectAcl, ListBucket` | `PutObject, GetObject, ListBucket` |
| 도메인 | `releases.okrbest.com` (CloudFront) | S3 직접 URL | 내부 공유 |
| 운영 필수성 | **필수** | 선택 | 선택 |

---

# 부록 B. 이 프로젝트의 자동 업데이트 구조 (배경)

PART A를 따라 하는 동안 의아했던 점이 있다면 여기서 배경을 확인한다.

### 왜 `electron-updater`가 아닌가

이 프로젝트는 일반적인 Electron 앱과 달리 **커스텀 HTTP + plain text 방식**을 쓴다:

1. 앱이 1시간마다 [src/main/updateNotifier.ts:149](../src/main/updateNotifier.ts#L149)에서 `https://releases.okrbest.com/desktop/latest.txt`에 GET 요청
2. 서버는 버전 문자열(예: `5.12.0`) 한 줄을 text로 응답
3. `semver.gt(remoteVersion, currentVersion)`로 비교 ([updateNotifier.ts:168](../src/main/updateNotifier.ts#L168))
4. 새 버전이 있으면 **알림만 표시**. 다운로드·설치는 사용자가 수동으로 수행

워크플로가 업로드하는 `latest.yml`, `latest-mac.yml` 등의 파일은 **현재 런타임이 읽지 않는다** — 향후 `electron-updater` 마이그레이션을 위한 흔적이다.

### 왜 업데이트 URL이 빌드 타임 하드코딩인가

[buildConfig.ts:39](../src/common/config/buildConfig.ts#L39)의 `updateNotificationURL`은 webpack 빌드 시점에 고정된다. 환경변수로 바꿀 수 없다. 자체 인프라에서 쓰려면 소스 수정 후 재빌드 필요.

### 채널별 파일명 규칙

앱이 어떤 파일을 보는지는 현재 실행 중인 버전의 suffix에 따라 결정된다 ([updateNotifier.ts:143-146](../src/main/updateNotifier.ts#L143-L146)):

| 실행 중인 앱 버전 | 참조하는 파일 |
|---|---|
| `5.12.0` | `latest.txt` |
| `5.12.0-rc.1` | `rc.txt` |
| `5.12.0-nightly.20260413` | `nightly.txt` |
| `5.12.0-mas.1` | `mas.txt` |

**stable 사용자는 rc 채널을 볼 수 없다.** 채널 간 이동은 사용자가 수동 재설치로만 가능.

### S3 버킷 최종 레이아웃

PART A 완료 후 버킷 구조:

```
releases.okrbest.com/
└── desktop/
    ├── latest.txt              ← stable 채널 포인터 (예: "5.12.0")
    ├── rc.txt                  ← RC 채널 포인터
    ├── nightly.txt             ← nightly 포인터
    ├── mas.txt                 ← MAS 포인터
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

---

# 부록 C. 보안 강화 권장 사항

당장 설정해야 하는 건 아니지만 운영에 들어가면 적용하는 것을 권장한다.

- **정적 키 rotation**: PART B·C의 IAM User 액세스 키를 90일마다 교체. IAM → User → Security credentials → Make inactive → Create new → Secret 업데이트 → 이전 키 삭제.
- **PART B·C를 OIDC로 마이그레이션**: 워크플로 수정(`aws-actions/configure-aws-credentials`에 `role-to-assume`)이 필요하지만 정적 키를 완전히 제거할 수 있다. Trust policy에 `repo:okrbest/okrbest-desktop:ref:refs/heads/master`가 포함되어야 한다.
- **S3 서버 액세스 로깅 또는 CloudTrail 데이터 이벤트** 활성화 → 누가 언제 `latest.txt`를 갱신했는지 감사.
- **IAM Role 최소 권한 재검토**: 이 가이드의 정책은 여유를 두고 작성됐다. `GetObject`나 `ListBucket`이 실제로 필요한지 운영 로그 기반으로 점검.

---

# 부록 D. 참고 자료

- [Configuring OpenID Connect in Amazon Web Services — GitHub Docs](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [aws-actions/configure-aws-credentials — GitHub](https://github.com/aws-actions/configure-aws-credentials)
- [Use IAM roles to connect GitHub Actions to actions in AWS — AWS Security Blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/)
- [Examples of Amazon S3 bucket policies — AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html)
- [Controlling object ownership of objects uploaded to your bucket — AWS S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
