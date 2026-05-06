# fb1ba58 이후 커밋 리브랜딩 영향 검토

> fb1ba585cdd60f5cee79207967ea088b75f34d6c (workflows: only upload artifacts to new bucket) 이후 upstream-master 커밋들 중 OKR Best 리브랜딩에 영향이 있어 수정이 필요한 항목

---

## 1. 수정 필요 (우선순위 높음)

### 1.1 `MATTERMOST_BUILD_GH_TOKEN` 시크릿

**영향 파일:**
- `.github/workflows/run-release-script.yml` (46행)
- `.github/workflows/release.yaml` (243행)

**상태:** `MATTERMOST_BUILD_GH_TOKEN` 그대로 사용 중

**수정:** OKR Best용 GitHub 토큰 시크릿으로 변경
```yaml
# 변경 전
token: ${{ secrets.MATTERMOST_BUILD_GH_TOKEN }}
GITHUB_TOKEN: ${{ secrets.MATTERMOST_BUILD_GH_TOKEN }}

# 변경 후 (OKRBEST_* 시크릿 사용)
token: ${{ secrets.OKRBEST_DESKTOP_BUILD_GH_TOKEN }}
GITHUB_TOKEN: ${{ secrets.OKRBEST_DESKTOP_BUILD_GH_TOKEN }}
```

**참고:** `1b60cccd Rename all MM_* GitHub Secrets to OKRBEST_* across workflows` 커밋에서 다른 워크플로우는 수정되었으나, `run-release-script.yml`은 d3e68574에서 새로 추가되어 누락된 것으로 보임.

---

### 1.2 `CLAUDE.md` (9812e942 Add CLAUDE.md)

**영향 파일:**
- `CLAUDE.md` (루트)
- `src/main/CLAUDE.md`
- `src/app/CLAUDE.md`
- `src/app/views/CLAUDE.md`
- `src/common/CLAUDE.md`
- `src/common/config/CLAUDE.md`
- `src/renderer/CLAUDE.md`
- `src/app/preload/CLAUDE.md`

**상태:** Mattermost 전용 문서로 작성됨

**수정 제안:**
- 제목: `Mattermost Desktop App` → `OKR Best Desktop App`
- Repository: `https://github.com/mattermost/desktop` → `https://github.com/okrbest/okrbest-desktop`
- 본문 내 "Mattermost" → "OKR Best" (문맥에 따라)
- `mattermost-desktop://` 프로토콜은 내부 프로토콜명으로 유지 가능 (기술적 식별자)

---

## 2. 수정 권장 (우선순위 중간)

### 2.1 User-Agent 문자열 (`src/main/utils.ts`)

**위치:** `composeUserAgent()` 함수 (73-80행)

**현재:**
```typescript
const filteredUserAgent = baseUserAgent.filter((ua) => !ua.startsWith('Mattermost'));
return `${filteredUserAgent.join(' ')} Mattermost/${app.getVersion()}`;
```

**수정:** OKR Best 브랜드 반영
```typescript
const filteredUserAgent = baseUserAgent.filter((ua) => !ua.startsWith('Mattermost') && !ua.startsWith('OKRBest'));
return `${filteredUserAgent.join(' ')} OKRBest/${app.getVersion()}`;
```

---

### 2.2 아이콘 클래스명 (`src/renderer/utils.ts` 53행)

**현재:** `return 'mattermost';` (업데이트 타입 아이콘용)

**검토:** CSS 클래스 `.mattermost`가 downloadsDropdown 등에서 사용 중일 수 있음. 클래스명 변경 시 해당 SCSS도 함께 수정 필요. 기능상 문제는 없으나 브랜딩 일관성을 위해 검토 권장.

---

## 3. 참고 (수정 불필요 또는 선택)

### 3.1 Copyright 헤더

대부분의 소스 파일에 `Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.` 유지. 오픈소스 라이선스 및 upstream 추적을 위해 그대로 두는 것이 일반적.

### 3.2 `@mattermost/desktop-api`, `@mattermost/compass-icons`

npm 패키지명은 변경 불가. 그대로 사용.

### 3.3 `MattermostView`, `MattermostServer` 등 클래스명

내부 코드 식별자. 리팩토링 비용 대비 이득이 적어 유지 권장.

### 3.4 `MATTERMOST_WEBHOOK_URL`, `MATTERMOST_USERNAME` (action-okrbest-notify)

`okrbest/action-okrbest-notify` 액션의 입력 파라미터명. Mattermost 호환용으로 유지되며, 실제 값은 `OKRBEST_DESKTOP_*` 시크릿 사용 중.

---

## 4. 아직 master에 미반영된 upstream 커밋 (향후 cherry-pick 시 주의)

| 커밋 | 제목 | 리브랜딩 검토 포인트 |
|------|------|---------------------|
| 72cdde88 | Add in-app notice for auto-update deprecation | i18n 키, 사용자 노출 문구에 Mattermost 언급 여부 확인 |
| 5e6164e6 | Enable Sentry and anonymouse server metrics | Sentry DSN/프로젝트가 Mattermost 전용인지 확인 |
| 96b1d99b | Easy login Support | Mattermost 서버 URL 하드코딩 여부 확인 |

---

## 5. 요약

| 구분 | 항목 | 조치 | 상태 |
|------|------|------|------|
| **필수** | MATTERMOST_BUILD_GH_TOKEN | OKRBEST_DESKTOP_BUILD_GH_TOKEN 등으로 변경 | ✅ 완료 |
| **권장** | CLAUDE.md | OKR Best용으로 문서 수정 | ✅ 완료 |
| **권장** | User-Agent (utils.ts) | Mattermost → OKRBest | ✅ 완료 |
| **권장** | 아이콘 클래스명 | mattermost → okrbest (utils.ts, downloadsDropdown.scss) | ✅ 완료 |
