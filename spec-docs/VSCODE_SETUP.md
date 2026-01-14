# VS Code 개발 환경 설정 가이드

이 문서는 OKR Best Desktop 프로젝트에서 ESLint 충돌 없이 개발하기 위한 VS Code 설정 방법을 안내합니다.

## 목차

- [문제 상황](#문제-상황)
- [해결 방법](#해결-방법)
- [필수 확장 프로그램](#필수-확장-프로그램)
- [권장 설정](#권장-설정)
- [문제 해결](#문제-해결)

---

## 문제 상황

### 증상

파일 저장 시 다음과 같은 ESLint 오류가 반복적으로 발생:

```
Strings must use singlequote.
There should be no space before '}'.
Expected indentation of 4 spaces but found 2.
```

### 원인

1. **Prettier vs ESLint 충돌**: Prettier가 먼저 코드를 포맷한 후 ESLint가 실행되어 규칙 충돌 발생
2. **개인 설정 우선 적용**: 사용자의 VS Code 전역 설정이 프로젝트 설정을 덮어씀
3. **실행 순서 문제**: `Format Document` → `ESLint Fix` 순으로 실행되어 Prettier 변경사항이 ESLint 규칙 위반

```
[문제 상황]
저장 시: Prettier 포맷 실행 → ESLint 수정 실행
                ↓
        Prettier가 double quote로 변경
                ↓
        ESLint가 single quote 규칙 위반 감지
                ↓
        반복되는 오류 발생!
```

---

## 해결 방법

### 방법 1: 프로젝트 설정 사용 (권장)

프로젝트에 포함된 `.vscode/settings.json` 파일이 자동으로 적용됩니다.

**확인 사항:**
1. VS Code에서 프로젝트 폴더를 직접 열기 (`File` → `Open Folder`)
2. 워크스페이스가 아닌 단일 폴더로 열기

### 방법 2: 개인 설정 수정

프로젝트 설정이 적용되지 않는 경우, 개인 설정을 수정합니다.

1. `Ctrl+Shift+P` (Mac: `Cmd+Shift+P`) → "Preferences: Open User Settings (JSON)" 선택
2. 다음 설정 추가:

```json
{
    // JavaScript/TypeScript 파일에서 ESLint를 기본 포맷터로 사용
    "[javascript]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[typescript]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[javascriptreact]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[typescriptreact]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    
    // ESLint 포맷팅 활성화
    "eslint.format.enable": true,
    
    // 저장 시 자동 포맷 비활성화 (ESLint가 대신 처리)
    "editor.formatOnSave": false,
    
    // 저장 시 ESLint 자동 수정
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "always"
    }
}
```

### 방법 3: 워크스페이스 설정 확인

1. `Ctrl+,` (Mac: `Cmd+,`)로 설정 열기
2. 상단 탭에서 "Workspace" 선택
3. 검색창에 `formatter` 입력
4. "Editor: Default Formatter" 설정 확인

---

## 필수 확장 프로그램

### 1. ESLint (필수)

- **ID**: `dbaeumer.vscode-eslint`
- **설치**: Extensions 탭에서 "ESLint" 검색 후 설치

```bash
# 명령줄 설치
code --install-extension dbaeumer.vscode-eslint
```

### 2. i18n Ally (권장)

- **ID**: `lokalise.i18n-ally`
- **용도**: 다국어 번역 파일 관리

```bash
code --install-extension lokalise.i18n-ally
```

### 3. Code Spell Checker (권장)

- **ID**: `streetsidesoftware.code-spell-checker`
- **용도**: 영문 맞춤법 검사

```bash
code --install-extension streetsidesoftware.code-spell-checker
```

### 일괄 설치

```bash
code --install-extension dbaeumer.vscode-eslint
code --install-extension lokalise.i18n-ally
code --install-extension streetsidesoftware.code-spell-checker
```

---

## 권장 설정

### 프로젝트 ESLint 규칙

이 프로젝트의 주요 ESLint 규칙:

| 규칙 | 설정 | 설명 |
|------|------|------|
| `quotes` | `'single'` | 문자열은 작은따옴표 사용 |
| `object-curly-spacing` | `'never'` | 객체 중괄호 내부 공백 없음 |
| `indent` | `4` | 들여쓰기 4칸 |
| `semi` | `'always'` | 세미콜론 필수 |

### 올바른 코드 예시

```typescript
// ✓ 올바른 예
import {app, BrowserWindow} from 'electron';

const config = {name: 'OKR Best', version: '1.0.0'};

// ✗ 잘못된 예
import { app, BrowserWindow } from "electron";

const config = { name: "OKR Best", version: "1.0.0" };
```

---

## 문제 해결

### 1. 설정 적용 후에도 오류가 계속되는 경우

**VS Code 재시작:**
```
Ctrl+Shift+P → "Developer: Reload Window"
```

**ESLint 서버 재시작:**
```
Ctrl+Shift+P → "ESLint: Restart ESLint Server"
```

### 2. Prettier가 계속 실행되는 경우

Prettier 확장 프로그램을 비활성화하거나 제거:

1. Extensions 탭 열기 (`Ctrl+Shift+X`)
2. "Prettier" 검색
3. "Disable (Workspace)" 클릭

또는 설정에서 명시적으로 비활성화:

```json
{
    "prettier.enable": false
}
```

### 3. ESLint 확장이 작동하지 않는 경우

**npm 의존성 설치 확인:**
```bash
npm install
```

**ESLint 버전 확인:**
```bash
npx eslint --version
```

**VS Code Output 패널 확인:**
1. `View` → `Output`
2. 드롭다운에서 "ESLint" 선택
3. 오류 메시지 확인

### 4. 특정 파일에서만 오류가 발생하는 경우

**수동 ESLint 수정:**
```bash
# 단일 파일
npx eslint --fix src/path/to/file.ts

# 전체 프로젝트
npm run fix:js
```

### 5. 설정 우선순위 확인

VS Code 설정 우선순위 (낮음 → 높음):
1. 기본 설정 (Default Settings)
2. 사용자 설정 (User Settings)
3. 워크스페이스 설정 (Workspace Settings) - `.vscode/settings.json`

워크스페이스 설정이 가장 높은 우선순위를 가지므로, 프로젝트의 `.vscode/settings.json` 파일이 정상적으로 로드되면 문제가 해결됩니다.

---

## 프로젝트 .vscode/settings.json 파일

현재 프로젝트에 포함된 설정:

```json
{
    "i18n-ally.localesPaths": ["i18n"],
    
    // ESLint를 기본 포맷터로 사용 (JavaScript/TypeScript)
    "[javascript]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[typescript]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[javascriptreact]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    "[typescriptreact]": {
        "editor.defaultFormatter": "dbaeumer.vscode-eslint"
    },
    
    // Prettier 대신 ESLint가 포맷팅 담당
    "eslint.format.enable": true,
    "editor.formatOnSave": false,
    
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "always"
    },
    
    "i18n-ally.keystyle": "nested"
}
```

---

## 요약

| 문제 | 해결책 |
|------|--------|
| Prettier vs ESLint 충돌 | ESLint를 기본 포맷터로 설정 |
| 저장 시 자동 포맷 충돌 | `editor.formatOnSave: false` |
| 개인 설정 우선 적용 | 워크스페이스 설정 사용 |
| ESLint 미작동 | ESLint 확장 설치 및 재시작 |

문제가 지속되면 프로젝트의 Discord 또는 이슈 트래커에 문의하세요.
