# OKRBEST 리브랜딩 마무리 계획서

> 마지막 업데이트: 2026-05-10
>
> 본 문서는 [REBRAND_STATUS.md](./REBRAND_STATUS.md) 의 "완료" 주장과 실제 코드 상태가 광범위하게 불일치한 것을 확인한 뒤,
> *실제 상태*를 기준으로 작성한 **순차 실행 계획서**다. 각 Phase는 독립 commit 단위이며, 실행 시 본 문서를 참조한다.

---

## 1. Context

이 프로젝트(`okrbest-desktop`)는 Mattermost Desktop의 fork이며, 단계적 리브랜딩이 진행 중. 직전까지 처리된 것:

- 카피라이트 헤더 정렬 (`OKRBEST, Inc.`) — 모든 소스 388개 (`commit 435c522d`, 후속 정렬 포함)
- `productName`·UI 표면 → `OKRBEST` (`commit d23c7e2e`)
- `app.setAppUserModelId`·DND·tccutil 등 런타임 식별자 → `OKRBest.Desktop`
- macOS entitlements bundle ID portion → `OKRBest.Desktop` (Team ID는 보류)
- i18n 영문 토큰 일괄 치환 (en.json + 63 locale 값 부분)
- assets (앱 아이콘) 교체 (`commit 11a50dec`)

본 계획은 **위 외에 남아있는 모든 리브랜딩 작업**을 다룬다.

---

## 2. 정합성 검증 요약 (REBRAND_STATUS "완료" 주장 vs 실제)

| 섹션 | 주장 | 실제 | 상태 |
|---|---|---|---|
| 1.1 `package.json` `name` | `okrbest-desktop` | `mattermost-desktop` | **불일치** |
| 1.1 `description` | `OKRBEST Desktop` | `OKRBEST` | 경미한 차이 |
| 1.1 `homepage` | `https://okr.best` | `https://mattermost.com` | **불일치** |
| 1.1 `repository` | `okrbest/okrbest-desktop` | `mattermost/desktop` | **불일치** |
| 1.1 `package-lock.json` | `okrbest-desktop` | `mattermost-desktop` | **불일치** |
| 1.2 `electron-builder` 파일 형식 | `.json` | `.ts` (문서 오기재) | 문서 정정 |
| 1.2 protocols schemes | `[okrbest, mattermost]` | `[mattermost]` | **불일치** |
| 1.4 i18n 키 `notMattermost`→`notOKRBest` | 변경됨 | **미변경** | **불일치** |
| 1.4 i18n 키 `MattermostVersionX`→`VersionX` | 변경됨 | **미변경** | **불일치** |
| 1.5 `URLValidationStatus.NotMattermost`→`NotOKRBest` | 변경됨 | **미변경** (`NOT_MATTERMOST` enum value 포함) | **불일치** |
| 1.5 `src/common/constants.ts` 외부 링크 | OKRBEST URL | 일부만 변경, 다수 `*.mattermost.com` 잔존 | **불일치** |
| 1.5 `src/common/config/buildConfig.ts` URL | OKRBEST 기준 | `releases.mattermost.com` 등 잔존 | **불일치** |
| 1.6 Windows GPO 파일명 | `okrbest.admx/adml` | `mattermost.admx/adml` | **불일치** |
| 1.7 `scripts/generate_release_markdown.sh` | OKRBEST 기준 | 완전히 미수정 | **불일치** |
| 1.8 nightly-rainforest.yml rename regex | 제거됨 | 잔존, S3 버킷 `mattermost-desktop-daily-builds` | **불일치** |
| 2.1 `scripts/generate_release_post.sh` | 미완료(정확) | 미완료 | 일치 |

→ **REBRAND_STATUS.md는 마지막 검증 후 회귀가 발생했거나, 처음부터 완료되지 않은 상태가 기재됨**. 본 계획 진행 중 각 phase 완료 후 STATUS 문서를 *실제 상태*에 맞춰 동기화한다.

---

## 3. Phase 구조 (순차 실행 권장)

각 Phase는 독립 commit 단위. 의존성 화살표(◀)가 있는 곳은 선행 phase 결정에 의존.

```
A  패키지 메타데이터          ─┐
B  NPM name cascade          ◀─ A-1 결정에 의존
C  프로토콜 스킴              (독립)
D  내부 식별자 리네임         (독립)
E  Windows GPO 파일           (독립)
F  릴리스 스크립트            (독립)
G  워크플로우                 ─┐
H  빌드 인프라(webpack/patch) ◀─ A·B 결정에 의존
I  User-Agent / CSS           (독립)
J  문서 / AI 가이드            (독립)
K  REBRAND_STATUS 동기화       (각 phase 후 누적)
L  외부 인프라 체크리스트     (참고용, 저장소 밖)
```

---

## Phase A: 패키지 메타데이터

### A-1. NPM `name` 필드 — **정책 결정 필요**

현재: `mattermost-desktop` (직전 productName 작업에서 의도적 보류). REBRAND_STATUS는 `okrbest-desktop`이라고 주장.

**결정 옵션**:
- **(a) `okrbest-desktop`으로 변경** — Phase B 전체 동반 필요 (cascade)
- **(b) 현재대로 유지** — REBRAND_STATUS를 "유지" 상태로 정정하고 Phase B 전체를 out-of-scope 처리

**Cascade 영향 (옵션 a 선택 시 Phase B에서 처리)**:
| 위치 | 영향 |
|---|---|
| `electron-builder.ts:24,69` `${name}` 토큰 | 산출물 파일명 자동 변경 (`mattermost-desktop-*` → `okrbest-desktop-*`) |
| `src/main/updateNotifier.ts:241` | 자동업데이트 다운로드 URL 하드코딩 — 산출물명과 어긋나면 업데이트 깨짐 |
| `e2e/global-setup.ts`·`global-teardown.ts`·`fixtures/index.ts`·`helpers/exclusiveLock.ts`·`specs/deep_linking/deeplink.test.ts` | `mattermost-desktop-e2e-*` PID/lock 파일명 |
| `scripts/linux_dev_setup.js` | `mattermost-desktop-dev.desktop` 파일명, `Icon=`, `MimeType=` |
| `electron-builder.ts:194` `certificateProfileName` | Azure 코드 사이닝 ID (외부 등록 이름) |
| `src/common/config/buildConfig.ts` `macAppStoreUpdateURL` | App Store ID는 별도이지만 URL 슬러그 `mattermost-desktop` 포함 |
| `.github/workflows/nightly-rainforest.yml` | rename regex 패턴 (Phase G에서 함께 처리) |

### A-2. 기타 메타데이터 (옵션 a/b 무관 진행)

`package.json` 다음 필드 정렬:
- `description`: `OKRBEST` → `OKRBEST Desktop`
- `author`: 현재 `OKRBEST, Inc.` 유지 (이메일 정책 결정 시 추가)
- `homepage`: `https://mattermost.com` → `https://okr.best` (또는 OKRBEST 공식 도메인 확정 시)
- `repository.url`: `git://github.com/mattermost/desktop.git` → `git://github.com/okrbest/okrbest-desktop.git`

### A-3. `package-lock.json`

A-1 변경 시 `npm install`이 자동으로 lockfile 상단의 `name` 필드를 갱신. 별도 수정 불필요.

**검증**: `npm install` 후 `package-lock.json`의 `"name"` 필드 확인.

### A-4. Commit
```
chore(rebrand): align package.json metadata with OKRBEST identity
```

---

## Phase B: NPM `name` cascade (A-1=옵션 a 선택 시에만)

### B-1. `src/main/updateNotifier.ts:241`
하드코딩된 다운로드 파일명 패턴:
```ts
return `mattermost-desktop-${version}-${platformName}-${archName}.${fileExt}`;
```
→ `okrbest-desktop-${version}-...`

### B-2. E2E 인프라
- `e2e/global-setup.ts`, `e2e/global-teardown.ts`: PID 파일 경로
- `e2e/fixtures/index.ts`, `e2e/helpers/exclusiveLock.ts`: 락 파일 경로
- `e2e/specs/deep_linking/deeplink.test.ts`: 테스트 데이터

검색: `grep -rn "mattermost-desktop-e2e" e2e/`

### B-3. `scripts/linux_dev_setup.js`
- `mattermost-desktop-dev.desktop` 파일명
- `Icon=mattermost-desktop` → `Icon=okrbest-desktop`
- `MimeType=x-scheme-handler/mattermost-dev` → 정책 결정 (Phase C 프로토콜과 정합)

### B-4. `electron-builder.ts:194`
```ts
certificateProfileName: 'mattermost-desktop-app',
```
→ Azure에 등록된 OKRBEST 인증서 profile 이름으로. (외부 인프라 결정 후)

### B-5. `src/common/config/buildConfig.ts`
- `macAppStoreUpdateURL`: `apps.apple.com/.../mattermost-desktop/id...` → OKRBEST App Store ID 발급 후 교체. 미발급 시 보류 + TODO 주석.

### B-6. Commit
```
chore(rebrand): rename npm package mattermost-desktop -> okrbest-desktop
```

---

## Phase C: 프로토콜 스킴 — **정책 결정 필요**

### C-1. 정책 결정
**옵션**:
- **(a) `okrbest://` 추가, `mattermost://` 호환 유지 (병행)** — REBRAND_STATUS 주장과 일치
- **(b) `okrbest://`만 사용** — 기존 mattermost:// 링크 모두 깨짐
- **(c) 현재 `mattermost://` 유지** — STATUS 정정만

### C-2. (옵션 a/b 선택 시) `electron-builder.ts:58-65`
```ts
protocols: [{
    name: 'OKRBEST',
    schemes: ['okrbest', 'mattermost'],   // 옵션 a
    // 또는: schemes: ['okrbest'],         // 옵션 b
}],
```

### C-3. `src/main/app/initialize.ts` 프로토콜 등록
- L235 (dev): `setAsDefaultProtocolClient('mattermost-dev')` 처리 정책
- L237 (prod): `setAsDefaultProtocolClient(MATTERMOST_PROTOCOL)` — 옵션 a면 양쪽 등록, 옵션 b면 OKRBEST 1개

### C-4. `src/common/constants.ts:23`
```ts
export const MATTERMOST_PROTOCOL = 'mattermost';
```
- 옵션 a: `OKRBEST_PROTOCOL = 'okrbest'` 추가, allowedProtocols 양쪽 포함
- 옵션 b: `MATTERMOST_PROTOCOL` → `OKRBEST_PROTOCOL = 'okrbest'`

### C-5. `src/common/config/buildConfig.ts` `allowedProtocols`
- L45 `allowedProtocols: ['mattermost', ...]` — Phase C-1 결정에 맞게 추가/교체

### C-6. URL parsing/validation
검색: `grep -rn "mattermost:" src/ --include="*.ts" --include="*.tsx"`
- URL 검증, 딥링크 라우팅, 테스트 mock 등 모든 사용처가 두 스킴 모두 처리 가능한지 확인

### C-7. 테스트
`grep -rn "mattermost://" src/ e2e/` — 결과 검토 후 옵션에 맞춰 변경/유지

### C-8. Commit
```
feat(rebrand): add okrbest:// deep link protocol  (옵션 a)
또는
feat(rebrand): replace mattermost:// with okrbest://  (옵션 b)
```

---

## Phase D: 내부 식별자 리네임 — **정책 결정 필요**

### D-1. 정책 결정
**옵션**:
- **(a) 리네임** — 일관성. 64 locale + TS 코드 영향
- **(b) 유지** — 내부 식별자, 사용자 노출 없음. STATUS 정정만

### D-2. (옵션 a 선택 시) i18n 키 리네임
- `notMattermost` → `notOKRBest`
- `MattermostVersionX` → `VersionX`

영향 위치:
- `i18n/en.json` 키 정의 (3곳)
- 64개 locale json 파일 (같은 키 사용)
- TS 코드에서 `formatMessage({id: '...notMattermost'})` 호출
  - `src/renderer/components/ConfigureServer/ConfigureServer.tsx`
  - `src/renderer/components/NewServerModal/NewServerModal.tsx`
  - `src/renderer/components/DownloadsDropdown/Update/UpdateAvailable.tsx`
- 테스트에서 키 검증

### D-3. TypeScript enum 리네임
`src/common/constants.ts` `URLValidationStatus`:
```ts
NotMattermost: 'NOT_MATTERMOST'
```
→ `NotOKRBest: 'NOT_OKRBEST'`

영향: enum 멤버명 + 문자열 값 사용처 모두. `grep -rn "NotMattermost\|NOT_MATTERMOST" src/`.

### D-4. Commit
```
refactor(rebrand): rename internal identifiers (notMattermost -> notOKRBest, NotMattermost enum)
```

---

## Phase E: Windows GPO 파일

### E-1. 파일 리네임 (`git mv`)
- `resources/windows/gpo/mattermost.admx` → `okrbest.admx`
- `resources/windows/gpo/en-US/mattermost.adml` → `okrbest.adml`

### E-2. 콘텐츠 갱신
admx/adml 안의 `displayName`, `policyNamespaces`, `description` 등에 "Mattermost Desktop" 표기 → "OKRBEST Desktop". XML 네임스페이스 ID도 함께.

### E-3. `resources/windows/gpo/README.md`
파일명 참조 갱신.

### E-4. `electron-builder.ts win.extraFiles` 참조 검증
```ts
{ from: 'resources/windows/gpo', to: 'gpo' }
```
디렉토리 단위 복사이므로 파일명 변경에 영향 없음 — 검증만.

### E-5. Commit
```
chore(rebrand): rename Windows GPO templates to okrbest.admx/adml
```

---

## Phase F: 릴리스 스크립트

### F-1. `scripts/generate_release_markdown.sh`
- `BASE_URL="https://releases.mattermost.com/desktop/${VERSION}"` → OKRBEST 릴리스 URL (S3 endpoint 또는 `releases.okr.best`)
- 헤더 `### Mattermost Desktop v${VERSION}` → `OKRBEST Desktop`
- `https://docs.mattermost.com/...` 링크 정책 결정 (OKRBEST 자체 문서 미구축이면 보류 + TODO)
- artifact 명명: `mattermost-desktop-` 패턴 → A-1 결정에 따라

### F-2. `scripts/generate_release_post.sh` (REBRAND_STATUS 2.1 미완료)
- `https://github.com/mattermost/desktop/releases/tag/...` → 새 GitHub repo
- PR 링크 `mattermost/desktop` → OKRBEST repo
- `mattermost.atlassian.net` Jira → 정책 결정 (OKRBEST Jira 미구축이면 보류 또는 GitHub Issues로 전환)

### F-3. Commit
```
chore(rebrand): update release script URLs to OKRBEST
```

---

## Phase G: 워크플로우

### G-1. `.github/workflows/nightly-rainforest.yml`
- L147-148 rename regex `s/...mattermost(.+).../mattermost$1daily-develop/` → `okrbest`
- S3 버킷 `mattermost-desktop-daily-builds` → `okrbest-desktop-daily-builds` (외부 인프라 미구축이면 Phase L 체크리스트로 이관)
- artifact 패턴 — A-1 결정 반영

### G-2. `MATTERMOST_BUILD_GH_TOKEN` 시크릿 갱신 (UPSTREAM_REBRAND_REVIEW 1.1)
- `.github/workflows/run-release-script.yml:46`
- `.github/workflows/release.yaml:243`

```yaml
token: ${{ secrets.MATTERMOST_BUILD_GH_TOKEN }}
```
→ `OKRBEST_DESKTOP_BUILD_GH_TOKEN`

### G-3. 외부 GitHub Action 파라미터 (정책 결정)
`.github/workflows/release.yaml` 의 `mattermost/action-mattermost-notify` 호출:
- `MATTERMOST_WEBHOOK_URL`, `MATTERMOST_USERNAME: MattermostRelease`, `MATTERMOST_ICON_URL`
- 외부 action API 이름이 고정 → 파라미터 *이름*은 그대로 두고 *값*만 OKRBEST 자산으로 매핑하는 게 표준. 단 `MATTERMOST_USERNAME: MattermostRelease` (표시명) → `OKRBESTRelease`로 갱신.

### G-4. dependabot 팀 참조 (정책 결정)
`.github/dependabot.yaml` `mattermost/core-build-engineers` 팀 멘션 → OKRBEST 팀 미구축이면 일단 제거 또는 OKRBEST 조직 팀으로 변경.

### G-5. Commit
```
chore(rebrand): update workflows to OKRBEST secrets and identifiers
```

---

## Phase H: 빌드 인프라 (webpack / patch)

### H-1. `webpack.config.renderer.js` 윈도우 타이틀
HtmlWebpackPlugin `title:` 옵션의 하드코딩 (15+ 곳):
- `'Mattermost Desktop App'`, `'Mattermost Desktop Settings'`, `'Mattermost Desktop Downloads'` 등
- → `OKRBEST Desktop`, `OKRBEST Desktop Settings`, ...

### H-2. `patches/app-builder-lib+26.6.0.patch`
- "Mattermost is still running" 알림 텍스트 → "OKRBEST is still running"
- `Mattermost.exe` 실행파일 참조 → `OKRBEST.exe` (이미 productName 변경 반영분과 정합)
- `Programs\mattermost-desktop` 설치 경로 → `okrbest-desktop` (A-1 결정에 따라)
- `LocalAppDataFolder` 슬러그

`patch-package` 메커니즘이므로 patch 파일 직접 수정. 또는 node_modules에서 수정 후 `npx patch-package app-builder-lib`로 재생성.

### H-3. Commit
```
chore(rebrand): update webpack window titles and MSI installer strings
```

---

## Phase I: User-Agent / CSS (UPSTREAM_REBRAND_REVIEW 2.1, 2.2)

### I-1. `src/main/utils.ts` `composeUserAgent()`
```ts
const filteredUserAgent = baseUserAgent.filter((ua) => !ua.startsWith('Mattermost'));
return `${filteredUserAgent.join(' ')} Mattermost/${app.getVersion()}`;
```
→ `OKRBEST/${version}` 토큰 + filter에 OKRBest/OKRBEST 추가

> **주의**: 일부 서버 통합·플러그인이 User-Agent의 "Mattermost" 토큰을 검사할 수 있음. 변경 전 영향 확인 필요. 보수적 옵션은 `Mattermost`와 `OKRBEST` UA 토큰을 모두 포함.

### I-2. `src/renderer/utils.ts:53`
```ts
return 'mattermost';
```
업데이트 타입 아이콘용 CSS 클래스. `'okrbest'`로 변경.

### I-3. `src/renderer/css/downloadsDropdown.scss`
L87 `.mattermost { ... }` → `.okrbest { ... }` (I-2와 동시 변경 필수)

### I-4. Commit
```
refactor(rebrand): update User-Agent token and CSS class identifiers
```

---

## Phase J: 문서 / AI 가이드

### J-1. README.md (REBRAND_STATUS 1.3 — 주장 vs 실제 검증)
실제 상태 점검 필요 — 탐색에서 잔여 Mattermost 콘텐츠 발견. 제목·다운로드 링크·아키텍처 다이어그램 캡션 등 잔여분 정리.

### J-2. CONTRIBUTING.md
- 커뮤니티 링크, Developer Guide URL, CLA 참조 — OKRBEST 자체 정책 미구축이면 일단 upstream 참조 명시 + TODO

### J-3. CHANGELOG.md
헤더 `# Mattermost Desktop Application Changelog` → `# OKRBEST Desktop Application Changelog`. 본문은 upstream 변경 이력이므로 그대로 유지.

### J-4. CLAUDE.md / AGENTS.md (UPSTREAM_REBRAND_REVIEW 1.2)
8개 파일:
- `CLAUDE.md` (루트), `AGENTS.md` (루트)
- `src/main/CLAUDE.md`
- `src/app/CLAUDE.md`
- `src/app/views/CLAUDE.md`
- `src/common/CLAUDE.md`
- `src/common/config/CLAUDE.md`
- `src/renderer/CLAUDE.md`
- `src/app/preload/CLAUDE.md`

각 파일의 제목·repo URL·"Mattermost" 본문 → OKRBEST. 단 `mattermost-desktop://` 같은 *기술적 식별자*는 (Phase C 결정에 따라) 유지/변경.

### J-5. spec-docs/ 검증
다른 spec-docs/*.md 파일에서 잔여 Mattermost 참조 점검 (REBRAND_STATUS·UPSTREAM_REBRAND_REVIEW 외).

### J-6. Commit
```
docs(rebrand): update project docs (README, CLAUDE.md, AGENTS.md, CHANGELOG)
```

---

## Phase K: REBRAND_STATUS / UPSTREAM_REBRAND_REVIEW 동기화

각 Phase A–J commit 직후, 해당 섹션의 상태를 갱신:
- 완료된 항목: "완료" 유지하되 commit hash 인용
- 미완료/유지 결정 항목: "미완료" 또는 "의도적 유지"로 정정
- UPSTREAM_REBRAND_REVIEW.md의 처리 항목은 "처리 완료" 표시 또는 항목 제거

마지막에 단일 commit으로 정리하거나 각 phase commit에 STATUS 동기화 포함.

---

## Phase L: 외부 인프라 검증 체크리스트 (저장소 밖)

코드 변경 불가, 사용자가 외부 콘솔에서 확인. **참고용 체크리스트만 plan에 명시**.

### L-1. GitHub Secrets / Variables
[REBRAND_STATUS.md §3.1](./REBRAND_STATUS.md#31-github-secrets--variables-등록-상태) 의 27개 항목. 각 워크플로우가 참조하는 secret이 GitHub repo Settings → Secrets에 실제 등록되어 있는지 확인.

### L-2. AWS S3 / IAM
- `releases.okr.best` (또는 OKRBEST 릴리스 버킷)
- `okrbest-desktop-daily-builds` (Rainforest)
- `okrbest-cypress-report` (E2E 리포트)
- IAM Role `OKRBEST_DESKTOP_RELEASE_AWS_ROLE_TO_ASSUME`

### L-3. Apple Developer Program
- OKRBEST Team ID (현재 entitlements `UQ8HT4Q2XM`은 Mattermost 소유)
- Developer ID 인증서 (notarization)
- MAS 프로비저닝 프로파일
- App Store Connect API 키 (release-mas 워크플로우)

### L-4. Certum SimplySign
[Certum-SimplySign.md](./Certum-SimplySign.md) 참조. 계정·QR 등록·OTP URI 시크릿.

### L-5. Webhook URL
- `OKRBEST_DESKTOP_RELEASE_WEBHOOK_URL`
- `OKRBEST_DESKTOP_NIGHTLY_WEBHOOK_URL`
- E2E `OKRBEST_DESKTOP_E2E_WEBHOOK_URL`

### L-6. 아이콘 시각 검수 (REBRAND_STATUS 2.3)
패키지 빌드 후 OS별 (Windows/macOS/Linux) 트레이·dock·런처에서 실제 표시 확인.

---

## 4. 의도적 보류 (정책상 변경 금지)

| 항목 | 이유 |
|---|---|
| 카피라이트 헤더의 `Mattermost, Inc.` 라인 | Apache 2.0 §4(c) attribution 보존 |
| `LICENSE.txt` 본문 | Apache 2.0 라이선스 자체 |
| `NOTICE.txt`의 원본 Mattermost·Yuya Ochiai 항목 | Apache 2.0 §4(d) NOTICE 보존 |
| 서버 호환 식별자 ([REBRAND_STATUS §4.1](./REBRAND_STATUS.md#41-서버-호환성)) | `MMUSERID`, `MMCSRF`, `MMAUTHTOKEN`, `com.mattermost.calls`, `com.mattermost.nps`, `com.mattermost.plugin-channel-export` |
| `@mattermost/desktop-api`, `@mattermost/compass-icons`, `@mattermost/eslint-plugin` | 외부 npm 의존성 |
| 내부 클래스 `MattermostServer`, `MattermostView`, `MattermostWebContentsView` | 서버 프로토콜 식별자, 변경 시 기능 영향 |
| `serverHub.ts:382`의 `siteName === 'Mattermost'` 비교 | 서버 응답 값과 비교, 기능 영향 |
| 내부 protocol `mattermost-desktop://` (renderer 페이지 로딩) | A-1=옵션 a 선택 시 경로 변경 검토 가능, 그 외 유지 |
| 테스트 mock 데이터 ([REBRAND_STATUS §1.10](./REBRAND_STATUS.md#110-테스트-파일-정리)) | 호환성/구조상 유지 |

---

## 5. 검증 절차 (각 Phase 완료 시)

1. **Lint**: `npm run lint:js-quiet` — 0 errors
2. **Type check**: `npm run check-types` — 통과
3. **Build config**: `npm run check-build-config` — 통과
4. **Unit test**: `npm run test:unit` — 회귀 없음
5. **잔여 토큰 점검** (해당 Phase 범위 한정):
   ```bash
   grep -rn "Mattermost\|mattermost" <phase 범위 파일들>
   ```
   의도된 잔여만 남았는지 확인
6. **REBRAND_STATUS.md 갱신** (Phase K)
7. **Commit** (Phase별 단일 commit, 명확한 메시지)

---

## 6. 진행 권장 순서 요약

1. **Phase A-2, A-3** (메타데이터 정렬, name 결정 미루고 진행 가능)
2. **Phase D** 정책 결정 → 진행
3. **Phase E** GPO 파일 (독립)
4. **Phase F** 릴리스 스크립트 (독립)
5. **Phase H-1** webpack 타이틀 (독립)
6. **Phase I** User-Agent / CSS (독립)
7. **Phase J** 문서 정리 (독립)
8. **Phase A-1, B** NPM name 결정 → cascade 처리
9. **Phase C** 프로토콜 정책 결정 → 처리
10. **Phase H-2** patch 파일 (B 결과 반영)
11. **Phase G** 워크플로우 (B·H 결과 반영)
12. **Phase K** 누적된 STATUS 동기화 정리
13. **Phase L** 외부 인프라 체크리스트 사용자 확인

---

*이 문서는 리브랜딩 마무리 작업의 실행 계획서이며, 각 Phase 진행 후 [REBRAND_STATUS.md](./REBRAND_STATUS.md) 의 상태를 동기화한다.*
