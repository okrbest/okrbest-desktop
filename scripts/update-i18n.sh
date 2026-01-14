#!/bin/bash
# scripts/update-i18n.sh
# i18n 파일에서 Mattermost 브랜드명을 OKR Best로 변경

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== i18n 브랜드명 변경 스크립트 ===${NC}"
echo ""

cd "$(dirname "$0")/.."

# 변경 전 백업
echo -e "${YELLOW}[1/4] 백업 생성 중...${NC}"
cp -r i18n i18n.backup
echo -e "${GREEN}✓ i18n.backup 폴더에 백업 완료${NC}"

# 변경할 패턴들
echo ""
echo -e "${YELLOW}[2/4] 브랜드명 변경 중...${NC}"

# 1. "Mattermost Academy" → "OKR Best Academy"
echo "  - Mattermost Academy → OKR Best Academy"
find i18n -name "*.json" -exec sed -i 's/Mattermost Academy/OKR Best Academy/g' {} \;

# 2. "Mattermost 아카데미" → "OKR Best 아카데미"
echo "  - Mattermost 아카데미 → OKR Best 아카데미"
find i18n -name "*.json" -exec sed -i 's/Mattermost 아카데미/OKR Best 아카데미/g' {} \;

# 3. "for Mattermost" → "for OKR Best" (알림 설정 관련)
echo "  - for Mattermost → for OKR Best"
find i18n -name "*.json" -exec sed -i 's/for Mattermost/for OKR Best/g' {} \;

# 4. "Mattermost의 경우" → "OKR Best의 경우" (한국어)
echo "  - Mattermost의 경우 → OKR Best의 경우"
find i18n -name "*.json" -exec sed -i 's/Mattermost의 경우/OKR Best의 경우/g' {} \;

# 5. "a Mattermost developer" → "a developer"
echo "  - a Mattermost developer → a developer"
find i18n -name "*.json" -exec sed -i 's/a Mattermost developer/a developer/g' {} \;

# 6. "Mattermost 개발자" → "개발자"
echo "  - Mattermost 개발자 → 개발자"
find i18n -name "*.json" -exec sed -i 's/Mattermost 개발자/개발자/g' {} \;

# 7. "your Mattermost admin" → "your admin"
echo "  - your Mattermost admin → your admin"
find i18n -name "*.json" -exec sed -i 's/your Mattermost admin/your admin/g' {} \;

# 8. "Mattermost 관리자" → "관리자"
echo "  - Mattermost 관리자 → 관리자"
find i18n -name "*.json" -exec sed -i 's/Mattermost 관리자/관리자/g' {} \;

echo -e "${GREEN}✓ 브랜드명 변경 완료${NC}"

# 변경 결과 확인
echo ""
echo -e "${YELLOW}[3/4] 변경 결과 확인...${NC}"
REMAINING=$(grep -r "Mattermost" i18n/*.json 2>/dev/null | wc -l)
echo -e "남은 Mattermost 문자열: ${YELLOW}$REMAINING${NC}개"

if [ "$REMAINING" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}[참고] 남은 문자열 (서버 관련 기술 용어):${NC}"
    grep -h "Mattermost" i18n/en.json 2>/dev/null | head -10
fi

# 백업 삭제 여부
echo ""
echo -e "${YELLOW}[4/4] 정리${NC}"
echo -e "백업 폴더 위치: ${BLUE}i18n.backup${NC}"
echo -e "백업 삭제: ${BLUE}rm -rf i18n.backup${NC}"

echo ""
echo -e "${GREEN}=== 완료 ===${NC}"
echo ""
echo "다음 단계:"
echo "  1. 변경 확인: grep -r 'OKR Best' i18n/en.json"
echo "  2. 앱 테스트: npm run build && npm run start"
echo "  3. 커밋: git add i18n/ && git commit -m 'i18n: 브랜드명 OKR Best로 변경'"
