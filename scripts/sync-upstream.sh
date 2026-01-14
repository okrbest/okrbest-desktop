#!/bin/bash
# scripts/sync-upstream.sh
# Upstream 변경사항 동기화 스크립트
# Patch-ID 기반으로 아직 반영되지 않은 커밋만 cherry-pick

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정
UPSTREAM_BRANCH="upstream-master"
TARGET_BRANCH="master"

echo -e "${BLUE}=== Upstream 동기화 스크립트 ===${NC}"
echo ""

# 1. 현재 브랜치 저장
CURRENT_BRANCH=$(git branch --show-current)
echo -e "현재 브랜치: ${YELLOW}$CURRENT_BRANCH${NC}"

# 2. upstream 최신화
echo ""
echo -e "${BLUE}[1/5] Upstream fetch 중...${NC}"
git fetch upstream --prune 2>/dev/null || git fetch origin --prune

# 3. 반영되지 않은 커밋 확인
echo ""
echo -e "${BLUE}[2/5] 반영되지 않은 커밋 확인 중...${NC}"
PENDING_COMMITS=$(git cherry -v $TARGET_BRANCH $UPSTREAM_BRANCH 2>/dev/null | grep "^+" | awk '{print $2}')

if [ -z "$PENDING_COMMITS" ]; then
    echo -e "${GREEN}✓ 모든 upstream 변경이 이미 반영되어 있습니다.${NC}"
    exit 0
fi

# 4. 반영 대기 커밋 목록 표시
echo ""
echo -e "${YELLOW}반영 대기 중인 커밋:${NC}"
echo "----------------------------------------"
git cherry -v $TARGET_BRANCH $UPSTREAM_BRANCH | grep "^+" | while read line; do
    HASH=$(echo $line | awk '{print $2}')
    MSG=$(echo $line | cut -d' ' -f3-)
    echo -e "${RED}+${NC} ${HASH:0:8} $MSG"
done
echo "----------------------------------------"

COMMIT_COUNT=$(echo "$PENDING_COMMITS" | wc -w)
echo ""
echo -e "총 ${YELLOW}$COMMIT_COUNT${NC}개 커밋이 반영 대기 중입니다."

# 5. 사용자 확인
echo ""
read -p "이 커밋들을 $TARGET_BRANCH 브랜치에 cherry-pick 하시겠습니까? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}취소되었습니다.${NC}"
    exit 0
fi

# 6. target 브랜치로 이동
echo ""
echo -e "${BLUE}[3/5] $TARGET_BRANCH 브랜치로 이동 중...${NC}"
git checkout $TARGET_BRANCH

# 7. Cherry-pick 실행
echo ""
echo -e "${BLUE}[4/5] Cherry-pick 실행 중...${NC}"
SUCCESS_COUNT=0
FAIL_COUNT=0

for COMMIT in $PENDING_COMMITS; do
    SHORT_HASH=${COMMIT:0:8}
    COMMIT_MSG=$(git log -1 --format="%s" $COMMIT)
    
    echo -n "  $SHORT_HASH $COMMIT_MSG ... "
    
    if git cherry-pick -x $COMMIT 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${RED}✗ (충돌 발생)${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        
        echo ""
        echo -e "${RED}충돌이 발생했습니다. 다음 중 선택하세요:${NC}"
        echo "  1. 충돌 해결 후 'git cherry-pick --continue' 실행"
        echo "  2. 건너뛰기: 'git cherry-pick --skip'"
        echo "  3. 중단: 'git cherry-pick --abort'"
        exit 1
    fi
done

# 8. 결과 요약
echo ""
echo -e "${BLUE}[5/5] 완료${NC}"
echo "----------------------------------------"
echo -e "성공: ${GREEN}$SUCCESS_COUNT${NC}개"
echo -e "실패: ${RED}$FAIL_COUNT${NC}개"
echo "----------------------------------------"

# 9. 원래 브랜치로 복귀 여부
echo ""
read -p "원래 브랜치($CURRENT_BRANCH)로 돌아가시겠습니까? (Y/n): " RETURN_CONFIRM

if [[ ! "$RETURN_CONFIRM" =~ ^[Nn]$ ]]; then
    git checkout $CURRENT_BRANCH
    echo -e "${GREEN}✓ $CURRENT_BRANCH 브랜치로 복귀했습니다.${NC}"
fi

echo ""
echo -e "${GREEN}=== 동기화 완료 ===${NC}"
echo ""
echo "다음 단계:"
echo "  1. 변경사항 확인: git log --oneline -10"
echo "  2. 원격 푸시: git push origin $TARGET_BRANCH"
