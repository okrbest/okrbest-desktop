#!/bin/bash
# scripts/check-upstream.sh
# Upstream 동기화 상태 확인 스크립트 (cherry-pick 없이 확인만)

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 설정
UPSTREAM_BRANCH="upstream-master"
TARGET_BRANCH="master"

echo -e "${BLUE}=== Upstream 동기화 상태 확인 ===${NC}"
echo ""

# 1. Fetch (선택적)
if [[ "$1" == "--fetch" || "$1" == "-f" ]]; then
    echo -e "${CYAN}Fetching upstream...${NC}"
    git fetch upstream --prune 2>/dev/null || git fetch origin --prune
    echo ""
fi

# 2. 전체 상태 확인
echo -e "${YELLOW}[Upstream → Master 동기화 상태]${NC}"
echo "----------------------------------------"

# 반영 완료 커밋 (-)
SYNCED=$(git cherry -v $TARGET_BRANCH $UPSTREAM_BRANCH 2>/dev/null | grep "^-" | wc -l)

# 반영 대기 커밋 (+)
PENDING=$(git cherry -v $TARGET_BRANCH $UPSTREAM_BRANCH 2>/dev/null | grep "^+" | wc -l)

echo -e "반영 완료: ${GREEN}$SYNCED${NC}개"
echo -e "반영 대기: ${RED}$PENDING${NC}개"
echo "----------------------------------------"
echo ""

# 3. 반영 대기 커밋 상세
if [ "$PENDING" -gt 0 ]; then
    echo -e "${YELLOW}[반영 대기 커밋 목록]${NC}"
    echo "----------------------------------------"
    git cherry -v $TARGET_BRANCH $UPSTREAM_BRANCH | grep "^+" | while read line; do
        HASH=$(echo $line | awk '{print $2}')
        MSG=$(echo $line | cut -d' ' -f3-)
        DATE=$(git log -1 --format="%ci" $HASH | cut -d' ' -f1)
        echo -e "${RED}+${NC} ${HASH:0:8} ${CYAN}$DATE${NC} $MSG"
    done
    echo "----------------------------------------"
    echo ""
    echo -e "동기화 실행: ${CYAN}./scripts/sync-upstream.sh${NC}"
else
    echo -e "${GREEN}✓ 모든 upstream 변경이 동기화되어 있습니다.${NC}"
fi

echo ""

# 4. Master에만 있는 커밋 (OKR Best 자체 커밋)
echo -e "${YELLOW}[Master 전용 커밋 (OKR Best 자체 변경)]${NC}"
echo "----------------------------------------"
OKR_COMMITS=$(git cherry -v $UPSTREAM_BRANCH $TARGET_BRANCH 2>/dev/null | grep "^+" | wc -l)
if [ "$OKR_COMMITS" -gt 0 ]; then
    git cherry -v $UPSTREAM_BRANCH $TARGET_BRANCH | grep "^+" | head -10 | while read line; do
        HASH=$(echo $line | awk '{print $2}')
        MSG=$(echo $line | cut -d' ' -f3-)
        echo -e "${GREEN}+${NC} ${HASH:0:8} $MSG"
    done
    if [ "$OKR_COMMITS" -gt 10 ]; then
        echo -e "  ... 외 $((OKR_COMMITS - 10))개"
    fi
else
    echo "(없음)"
fi
echo "----------------------------------------"
echo ""
echo -e "총 OKR Best 자체 커밋: ${GREEN}$OKR_COMMITS${NC}개"
