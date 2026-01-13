#!/bin/bash
# scripts/update-copyright.sh
# 소스 파일 저작권 헤더 일괄 변경 스크립트

set -e

cd "$(dirname "$0")/.."

echo "=== OKR Best 저작권 헤더 일괄 변경 ==="
echo ""
echo "작업 디렉토리: $(pwd)"
echo ""

# 대상 파일 찾기
FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  -not -path "./node_modules/*" \
  -not -path "./dist/*" \
  -not -path "./release/*" \
  -not -path "./.git/*" \
  2>/dev/null)

TOTAL=$(echo "$FILES" | grep -c . || echo "0")
CHANGED=0
SKIPPED=0

echo "총 $TOTAL 개 파일 검사 중..."
echo ""

for file in $FILES; do
  # 파일에 기존 헤더가 있는지 확인
  if head -2 "$file" 2>/dev/null | grep -q "// Copyright (c) 2016-present Mattermost"; then
    # 이미 OKR Best 저작권이 있는지 확인
    if head -4 "$file" 2>/dev/null | grep -q "OKR Best"; then
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
    
    # 헤더 교체 (perl 사용)
    perl -i -0pe 's|// Copyright \(c\) 2016-present Mattermost, Inc\. All Rights Reserved\.\n// See LICENSE\.txt for license information\.|// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.\n// Copyright (c) 2024-present OKR Best. All Rights Reserved.\n// See LICENSE.txt for license information.\n// Modified for OKR Best project.|' "$file"
    
    CHANGED=$((CHANGED + 1))
    echo "✓ $file"
  fi
done

echo ""
echo "=== 완료 ==="
echo "검사: $TOTAL 개 파일"
echo "변경: $CHANGED 개 파일"
echo "스킵: $SKIPPED 개 파일 (이미 변경됨)"
