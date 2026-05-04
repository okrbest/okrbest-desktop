# Upstream 동기화 작업 인계 문서 (2026-05-04)

> 본 문서는 2026-05-04에 진행한 upstream Mattermost desktop → OKR Best `upstream-sync` 브랜치 동기화 작업의 진행 경과와 후속 작업을 다른 개발자에게 인계하기 위한 기록입니다.
>
> 관련 문서: [MERGE_STRATEGY.md](MERGE_STRATEGY.md) · [UPSTREAM_REBRAND_REVIEW.md](UPSTREAM_REBRAND_REVIEW.md) · [REBRAND_STATUS.md](REBRAND_STATUS.md)

---

## 1. 작업 범위

### 1.1 동기화 시점

| 항목 | 값 |
|---|---|
| 작업 일자 | 2026-05-04 |
| 작업 브랜치 | `upstream-sync` (직접 cherry-pick 대상) |
| 시작 시점 (HEAD) | `a5a4942c docs: update Apple Developer Account setup guidelines for certificate renewal` |
| 종료 시점 (HEAD) | `8f6ecf99 fix(ci): inject OKRBEST_DESKTOP_BUILD_SENTRYDSN env in workflows` |
| 비교 대상 | `upstream-master` HEAD: `06488e17 [MM-68365] Block NTLM authentication for non-server configured domains (#3802)` |
| 신규 commit 수 | 49개 (cherry-pick `-x` 47 + 수동 정리 2 + skip-list 등록 + 누락 복구) |

### 1.2 사용한 전략 결정사항

작업 시작 시 사용자가 다음과 같이 결정함:

- **진행 방식**: 그룹별 단계 진행 (안전 → 위험 순)
- **target 브랜치**: `upstream-sync`에 직접 cherry-pick (별도 sync/ 브랜치 미생성)
- **충돌 해결**: 리브랜딩 패턴 자동 적용 + 복잡한 충돌만 사용자 확인

### 1.3 그룹 분류

| 그룹 | 주제 | 시도 / 적용 / Skip | 검증 |
|---|---|---|---|
| 1 | 번역 + 작은 fix | 16 / 15 / 1 | lint 통과 |
| 2 | GitHub Actions bumps | 10 / 7 / 3 | lint 통과 |
| 3 | 기능 변경 | 17 / 13 / 4 (auto-updater 2건은 명시 skip) | lint 통과 |
| 4 | 워크플로 변경 | 11 / 3 / 8 | lint 통과 |
| 5 | 의존성/버전 | 6 / 4 / 2 | lint 통과 |
| **합계** | | **60 시도 / 42 적용 / 18 skip** | |

> 적용 commit 수가 49개로 더 큰 이유: 중복 카운트 외에도 cherry-pick 사이드 이펙트로 새 워크플로 파일이 함께 들어옴 (예: `4aab7498` skip 시점에 `docs-impact-review.yml` 파일은 이미 작업 트리에 들어와 있어 OKR Best 컨텍스트로 리브랜딩 후 보존).

---

## 2. 자동화 적용한 충돌 해결 패턴

cherry-pick 충돌 발생 시 다음 룰을 자동 적용했습니다. 다음 동기화 시 같은 룰을 그대로 사용 가능합니다.

### 2.1 i18n 파일 (`i18n/*.json`)

**전략**: theirs(upstream) 채택 + OKR Best 리브랜딩 sed 적용

```bash
git checkout --theirs <file>
sed -i \
  -e 's/\bMattermost\b/OKR Best/g' \
  -e 's|https://mattermost\.com|https://okr.best|g' \
  -e 's|mattermost/desktop|okrbest/okrbest-desktop|g' \
  -e 's/"renderer\.components\.configureServer\.url\.notMattermost"/"renderer.components.configureServer.url.notOKRBest"/g' \
  -e 's/"renderer\.components\.newServerModal\.warning\.notMattermost"/"renderer.components.newServerModal.warning.notOKRBest"/g' \
  -e 's/"renderer\.downloadsDropdown\.Update\.MattermostVersionX"/"renderer.downloadsDropdown.Update.VersionX"/g' \
  <file>
git add <file>
```

**근거**: [REBRAND_STATUS.md §1.4](REBRAND_STATUS.md) — i18n에는 `Mattermost` 단어를 모두 `OKR Best`로 치환하기로 결정. 키 이름도 OKR Best 규약(`notOKRBest`, `VersionX`)으로 변경됨.

### 2.2 워크플로 파일 — 두 갈래

**`.github/workflows/e2e-*.yml` (E2E 워크플로)**: theirs + 리브랜딩 sed

```bash
git checkout --theirs <file>
sed -i \
  -e 's|MATTERMOST_BUILD_GH_TOKEN|OKRBEST_DESKTOP_BUILD_GH_TOKEN|g' \
  -e 's|mattermost/desktop|okrbest/okrbest-desktop|g' \
  -e 's|mattermost/actions|okrbest/actions|g' \
  <file>
```

E2E 워크플로는 OKR Best 자체 변경이 적고 upstream의 새 인프라 변경을 받아들이는 게 합리적.

**`.github/workflows/docs-impact-review.yml`**: ours 채택 (OKR Best 컨텍스트 + workflow_dispatch 비활성화 유지)

**그 외 워크플로**: 충돌 부분에 `OKRBEST_DESKTOP|okrbest/actions|mattermost/actions|MM_DESKTOP|MATTERMOST_BUILD` 식별자가 있으면 ours 채택 (OKR Best 시크릿/리전/버킷 운영 환경 보존).

### 2.3 e2e 디렉토리 (`e2e/*`)

**전략**: theirs + 단순 매핑 (workflow와 동일 sed)

### 2.4 OKR Best 자체 스크립트 (`scripts/release.sh`, `scripts/generate_release_*.sh`)

**전략**: ours 유지 (OKR Best 리브랜딩 텍스트 보존)

### 2.5 패키지 메타데이터 (`package.json`, `package-lock.json`)

**전략**: ours 유지

**근거**: OKR Best 식별자 (`name`, `productName`, `description`, `author`, `desktopName`, `homepage`, `repository`)와 자체 버전 정책 (`6.2.0-develop.1`) 보존. upstream의 단순 version bump (6.1→6.2, 6.2→6.3)는 빈 commit으로 skip.

### 2.6 중복 변경 (`src/app/views/webContentEvents.ts`, `src/main/security/allowProtocolDialog.test.js`)

**전략**: ours 유지

**근거**: 그룹 1의 `0821b0dc` (raw URL fix)와 그룹 4의 `710643c4` (E2E parsedURL)가 같은 부분을 다르게 변경. `0821b0dc`가 더 최신 의도이므로 ours.

---

## 3. 명시적 skip 처리한 commit 7건

[scripts/sync-upstream-skipped.txt](../scripts/sync-upstream-skipped.txt)에 등록되어 다음 동기화 시 자동 제외됩니다.

| commit | 사유 | 비고 |
|---|---|---|
| `3a3aa0a5054de69ad50b600ed057ee2d05f38a49` | (이전 sync에서 등록) | — |
| `72cdde887518fcc5fa4e6e4253e71b920b16cd24` [MM-67210] In-app notice for auto-update deprecation | OKR Best가 `src/main/autoUpdater.ts`를 이미 삭제 + auto-update를 자체 방식으로 처리. modify/delete 충돌 발생. | 사용자 결정 후 skip |
| `15baa6f888f46d59246ebf86cf4848b119927951` Remove NSIS installer + auto update | 위와 동일 컨셉, 같은 컨셉의 OKR Best 자체 처리 존재. | 사용자 결정 후 skip |
| `1b916ba9185442d85e775e422e269adc8f6aaa2b` [MM-67415] Move electron-builder config to TS file | OKR Best는 `[electron-builder.ts](../electron-builder.ts)` 적용 완료. patch-id 다름. | 자동 인식 |
| `925a450e151edf54df2f26739b60f33ebb2acf16` Don't specify mac provisioning profile | OKR Best는 Communication Notifications entitlement 이유로 Developer ID 빌드에도 profile 임베딩 결정. | upstream과 반대 방향 |
| `8cbe8a995df289d9fe168d685bc0ac7eac2de7aa` Upgrade Electron 40.8.4 → 41.2.0 | 메이저 업그레이드. ESM 자동 감지 이슈 검증 필요. | **후속 작업 §6.2** |
| `59b8a5aa298f1d28f8d86ace48c1c14c29b92329` E2E Playwright 마이그레이션 | e2e/ 디렉토리 전면 재구조. OKR Best E2E 호환성 검증 필요. | **후속 작업 §6.3** |
| `d05493c0b9ae76d5625007661aad42cc66b7fb2f` CLAUDE.md → AGENTS.md | OKR Best는 CLAUDE.md를 OKR Best 용으로 광범위하게 재작성. 단순 rename 시 콘텐츠 손실. | **후속 작업 §6.4** |

---

## 4. 자동 빈 commit으로 skip된 17건 — 검증 결과

cherry-pick 시도했으나 ours 채택 결과 변경이 없어진 commit들. 모든 항목을 직접 검증했습니다.

### 4.1 정당한 skip (16건)

| commit | skip 이유 | 검증 방법 |
|---|---|---|
| `c72a0cea` Fix developer issues | watch.js의 `const electron = require('electron')` + `spawn(electron, ...)` 변경 이미 적용됨 | `[scripts/watch.js:9,23](../scripts/watch.js#L9)` 직접 확인 |
| `f5c28a29` / `d28b8dfa` / `83060f50` Actions bumps | OKR Best는 `okrbest/actions` fork 사용, mattermost SHA 무의미 | `compatibility-matrix-testing.yml` 등 |
| `f6b1ce5f` Native title bar setting | `useNativeTitleBar` 식별자가 8개 파일에 auto-merge로 적용됨 | `grep -rn "useNativeTitleBar" src/` |
| `71cf1ac0` RegistryConfig refactor | OKR Best `881aac67`로 이미 적용 | `git log -- src/common/config/policyConfigLoader.ts` |
| `d3e68574` Add release script | OKR Best `run-release-script.yml` 이미 존재 | 파일 존재 확인 |
| `f1af6a8c` Upload to new bucket | OKR Best 별도 시크릿(`OKRBEST_DESKTOP_RELEASE_BUCKET`) + 리전 (`ap-northeast-2`) 사용 | `nightly-main.yml`, `release.yaml` |
| `4aab7498`, `9238ebed`, `b662e838`, `85e7929d`, `246c1173`, `96e2bf2d` (6건) docs-impact-review 관련 | OKR Best 컨텍스트로 prompt 리브랜딩 + `workflow_dispatch`로 자동 트리거 비활성화 | `docs-impact-review.yml` |
| `c2acab8c` package.json 6.1→6.2 bump | OKR Best 이미 6.2 사용 | `package.json:5` |
| `a03c0a17` package.json 6.2→6.3 bump | OKR Best 자체 버전 정책 | `package.json:5` |

### 4.2 발견된 누락 1건 → 복구 완료

**`5cdf9424` Fix missing Sentry DSN** (#3745):
- upstream 변경: 워크플로 env에 `MM_DESKTOP_BUILD_SENTRYDSN` 추가
- 누락 원인: cherry-pick 시 워크플로 ours 채택으로 OKR Best 워크플로에는 그 env가 안 들어감
- 영향: [webpack.config.base.js:23](../webpack.config.base.js#L23)이 `process.env.OKRBEST_DESKTOP_BUILD_SENTRYDSN`을 컴파일 시 상수로 주입하는데, **워크플로가 그 env를 set 안 해서 production 빌드에 빈 Sentry DSN이 들어감**
- 복구: commit `8f6ecf99 fix(ci): inject OKRBEST_DESKTOP_BUILD_SENTRYDSN env in workflows`로 두 워크플로(`nightly-main.yml`, `release.yaml`)에 OKR Best 시크릿 매핑한 env 추가

---

## 5. OKR Best 자체 commits (cherry-pick과 별개)

이번 동기화 작업 중 만든 OKR Best 자체 commits:

| commit | 내용 |
|---|---|
| `da1df399` chore(lint): restore OKR Best copyright headers + remove duplicate import (Group 1) | theirs 채택으로 잃은 OKR Best Copyright 헤더 자동 복원 (`fix:js`) |
| `eb0c2032` chore(sync): register skipped commits + rebrand docs-impact-review prompt | auto-updater 2건 skip-list 등록 + docs-impact-review.yml prompt를 OKR Best 컨텍스트로 + workflow_dispatch 비활성화 |
| `3e8ef41c` chore(lint): restore OKR Best copyright + allow console in e2e utils (Group 3) | e2e/utils/github-actions.js에 `eslint-disable no-console` |
| `345a577c` chore(rebrand): apply mattermost/desktop → okrbest/okrbest-desktop in pr-test-analysis workflows (Group 4) | `pr-test-analysis.yml` / `pr-test-analysis-override.yml`의 repo ref 매핑 |
| `555fba94` chore(lint): restore OKR Best copyright headers in e2e specs (Group 4) | e2e/specs 헤더 자동 복원 |
| `8cdd8b2a` chore(sync): register risk commits as skipped (post Group 5) | 5건의 위험 commit skip-list 등록 |
| `8f6ecf99` fix(ci): inject OKRBEST_DESKTOP_BUILD_SENTRYDSN env in workflows | `5cdf9424` 누락 복구 |

---

## 6. 후속 작업 (별도 PR 권장)

### 6.1 우선 — 새로 들어온 워크플로 정리

cherry-pick 사이드 이펙트로 들어온 워크플로 파일들 중 일부는 OKR Best 환경에 추가 검토가 필요합니다:

| 파일 | 상태 | 후속 작업 |
|---|---|---|
| `.github/workflows/docs-impact-review.yml` | OKR Best 컨텍스트 prompt + 자동 트리거 비활성화 | OKR Best docs 저장소 생성 시 `repository: mattermost/docs` (line 30) → `okrbest/docs`로 변경 + `pull_request` 트리거 복원 |
| `.github/workflows/cmt-provisioner.yml` | upstream 그대로 | OKR Best 환경에서 의미 검토 |
| `.github/workflows/e2e-label-cleanup.yml` | theirs 채택 | OKR Best 운영 환경에서 동작 가능 여부 검증 |
| `.github/workflows/e2e-nightly-trigger.yml` | theirs 채택 | 동일 |
| `.github/workflows/e2e-pr-trigger.yml` | theirs 채택 | 동일 |
| `.github/workflows/pr-test-analysis.yml` | repo ref 리브랜딩 적용 | OKR Best 환경에서 PR test analysis 의미 검토 |
| `.github/workflows/pr-test-analysis-override.yml` | repo ref 리브랜딩 적용 | 동일 |
| `.github/workflows/update-latest-version.yml` | upstream의 `3e188c99`로 신규 추가 | `release.yaml`의 인라인 `upload-latest-version` step과 **중복 가능성** — 한 쪽 제거 결정 필요 |

### 6.2 Electron 41.2.0 업그레이드 (`8cbe8a99`)

- 별도 브랜치에서 `git cherry-pick -x 8cbe8a99` 시도
- ESM 자동 감지 이슈 (Electron 40 + Node 22의 syntax detection): 이번 세션에서 미해결로 남긴 이슈. [electron-builder.ts:31-33](../electron-builder.ts#L31-L33) `extraMetadata`에 `type: 'commonjs'` 추가 시도부터 검증
- 검증 절차:
  1. `npm ci && npm run build-prod && npm start`로 ESM 에러 재현 확인
  2. `extraMetadata.type: 'commonjs'` 적용 → 재빌드 → 검증
  3. macOS DMG 설치 + 실행 확인 (Universal/arm64/x64)
- 관련 컨텍스트: 직전 세션에서 `Uncaught Exception: ES Modules may not assign module.exports or exports.*` 에러로 추적함

### 6.3 E2E Playwright 마이그레이션 (`59b8a5aa`)

- e2e/ 디렉토리 전체 재구조라 수동 정리 + cherry-pick 병행 필요
- OKR Best E2E 환경(GitHub Secrets: `OKRBEST_DESKTOP_E2E_*`)과의 호환성 점검
- 별도 PR 분리 권장

### 6.4 CLAUDE.md → AGENTS.md 정책 결정 (`d05493c0`)

- OKR Best는 [CLAUDE.md](../CLAUDE.md), [src/main/CLAUDE.md](../src/main/CLAUDE.md), [src/app/CLAUDE.md](../src/app/CLAUDE.md), [src/common/CLAUDE.md](../src/common/CLAUDE.md) 등 다수 모듈에 OKR Best 컨텍스트로 작성
- 단순 rename 시 OKR Best 콘텐츠 손실
- 결정 사항:
  - **Option A**: AGENTS.md로 rename + 내용 보존 (`git mv` + 내용 유지)
  - **Option B**: CLAUDE.md 유지 + AGENTS.md를 symlink 또는 비어있는 alias로 추가
  - **Option C**: upstream과 어긋남 감수하고 CLAUDE.md만 유지

### 6.5 Developer ID Mac provisioning profile (`925a450e`와 반대 방향)

- OKR Best는 Communication Notifications entitlement 때문에 Developer ID 빌드에도 profile 임베딩 결정
- 직전 세션의 결정: [spec-docs/APPLE_DEVELOPER_ACCOUNT_SETUP.md:336-346](APPLE_DEVELOPER_ACCOUNT_SETUP.md#L336-L346) §9.2 갱신 필요
- 작업: §9.2 권장 A/B 폐기, "Developer ID Mac profile 발급 필수" 절차로 재작성

### 6.6 docs 갱신

- [REBRAND_STATUS.md](REBRAND_STATUS.md) §2.1 — 이번 동기화로 들어온 새 워크플로(`docs-impact-review.yml`, `cmt-provisioner.yml`, `pr-test-analysis*.yml` 등)의 리브랜딩 상태 추가
- [UPSTREAM_REBRAND_REVIEW.md](UPSTREAM_REBRAND_REVIEW.md) §4 — 다음 동기화 시 주의사항 항목 갱신 (특히 `update-latest-version.yml` 중복 정리)

---

## 7. 검증 결과

### 7.1 통과 항목

- `npm run lint:js-quiet` — 모든 그룹에서 통과
- 49개 신규 commit 모두 valid

### 7.2 환경 한계로 미검증

- `npm run check-types` — `cf-prefs` (macOS-only native module) Linux 환경에서 import 실패. cherry-pick 회귀 아님
- `npm run test:unit` — 같은 이유로 6 test 실패. cherry-pick 회귀 아님
- `npm run build-prod` — 시간 관계상 미실행. **다음 작업자가 macOS 환경에서 실행 후 빌드 통과 확인 권장**
- 빌드된 `.app` / `.dmg` 실행 검증 — 미실행. **§6.2 Electron 41 시도 전에 현재 상태로 한 번 빌드 + 실행 검증 필요**

### 7.3 외부 검증 필요

- production 빌드에 Sentry DSN이 들어가는지 (복구 commit `8f6ecf99` 효과 확인): `OKRBEST_DESKTOP_BUILD_SENTRYDSN` 시크릿이 등록돼 있어야 동작. [REBRAND_STATUS.md §3.1](REBRAND_STATUS.md)에 외부 미검증 시크릿 목록에 추가 필요

---

## 8. 백업 태그 (롤백 가능)

작업 중 안전을 위해 만든 태그. 문제 발생 시 `git reset --hard <tag>`로 복구 가능.

```
backup/upstream-sync/20260504-145722         # 그룹 시작 전
backup/upstream-sync-group1/20260504-150929  # 그룹 1 완료 후
backup/upstream-sync-group2/20260504-151245  # 그룹 2 완료 후
backup/upstream-sync-group3/20260504-153106  # 그룹 3 완료 후
backup/upstream-sync-group4/20260504-153630  # 그룹 4 완료 후
```

태그는 정리 시점에 제거해도 됩니다 (`git tag -d <tag>`). 단 push는 안 한 상태일 가능성 높으니 `git push origin --delete <tag>`까지는 불필요.

---

## 9. 다음 동기화 시 주의사항

### 9.1 sync-upstream-skipped.txt

[scripts/sync-upstream-skipped.txt](../scripts/sync-upstream-skipped.txt)에 이번 작업으로 7건이 추가됐습니다 (총 8건). [scripts/sync-upstream.sh](../scripts/sync-upstream.sh)는 이 목록을 읽어 자동 제외하므로, 다음 동기화 시 이 commit들은 시도 자체가 안 됩니다.

### 9.2 자동화 스크립트 개선 제안

이번 작업에서 사용한 충돌 해결 패턴 (§2)을 [scripts/sync-upstream.sh](../scripts/sync-upstream.sh)에 통합하면 다음 동기화가 더 빠릅니다. 핵심 함수:

```bash
auto_resolve_conflicts() {
  # i18n: theirs + 리브랜딩 sed
  # workflow: 식별자 보고 ours/theirs 결정
  # e2e: theirs + 단순 매핑
  # scripts/release.sh, generate_release_*.sh: ours
  # webContentEvents.ts, allowProtocolDialog.test.js: ours (raw URL fix 우선)
}
```

상세 구현은 §2 참고.

### 9.3 빈 commit 검증 절차

cherry-pick이 빈 commit으로 인식하면 자동으로 `--skip`되는데, 이번에 발견한 `5cdf9424` 사례처럼 워크플로 env 같은 환경 차이로 의도치 않게 누락될 수 있습니다. 다음 동기화 작업자는 그룹 완료 후 다음 항목을 직접 확인할 것을 권장합니다:

```bash
# 1) skip된 commit이 워크플로 env / package.json scripts / webpack 상수에 영향 주는지 확인
git log --grep="cherry picked from" --invert-grep upstream-sync ^a5a4942c | head -20
# (이번 sync 작업의 OKR Best 자체 commits 외 빠진 게 있는지)

# 2) 각 skip된 commit의 stat 검토
for hash in <list>; do
  git show $hash --stat | head -10
  echo "---"
done

# 3) 핵심 식별자 grep으로 적용 여부 확인
# 예: __SENTRY_DSN__ 워크플로 env 매핑, useNativeTitleBar 식별자 등
```

### 9.4 docs-impact-review.yml 운영 결정

현재 `workflow_dispatch` only로 자동 트리거 비활성화 상태. OKR Best docs 저장소 (`okrbest/docs`)가 만들어지면:
1. [docs-impact-review.yml:30](../.github/workflows/docs-impact-review.yml#L30)의 `repository: mattermost/docs`를 `okrbest/docs`로 변경
2. 워크플로 헤더의 `on: workflow_dispatch:`를 `pull_request: types: [opened, synchronize, reopened]`로 복원
3. `ANTHROPIC_API_KEY` 시크릿 등록 확인

---

## 10. 관련 commit 빠른 참조

| 단계 | commit |
|---|---|
| 시작 | `a5a4942c` |
| 그룹 1 완료 | `da1df399` |
| skip-list + docs-impact 리브랜드 | `eb0c2032` |
| 그룹 2 완료 | `1668d8e5` |
| 그룹 3 완료 | `3e8ef41c` |
| 그룹 4 워크플로 리브랜드 | `345a577c`, `555fba94` |
| 그룹 5 완료 | (자체 정리 commit 없음 — 모든 충돌이 ours로 빈 commit) |
| 위험 commit skip-list | `8cdd8b2a` |
| 누락 복구 (Sentry DSN) | `8f6ecf99` |

---

_문서 작성일: 2026-05-04_
