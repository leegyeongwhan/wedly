#!/bin/bash

# Claude와 Antigravity 설정 동기화 스크립트
# 사용법: ./sync-agent-configs.sh

set -e

echo "🔄 Claude ↔ Antigravity 설정 동기화 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -d ".claude" ] || [ ! -d ".agent" ]; then
    echo "❌ 오류: .claude 또는 .agent 디렉토리를 찾을 수 없습니다."
    echo "   프로젝트 루트에서 실행해주세요."
    exit 1
fi

echo ""
echo "📋 동기화 매핑:"
echo "  CLAUDE.md                    → .agent/workflows/project-overview.md"
echo "  .claude/instructions.md      → .agent/references/development-guidelines.md"
echo "  .claude/commands/*.md        → .agent/workflows/*.md"
echo "  .claude/skills/*             → .agent/references/*.md"
echo ""

# 변경사항 확인 함수
check_changes() {
    local source=$1
    local target=$2
    
    if [ ! -f "$target" ]; then
        echo "  ➕ 새 파일: $target"
        return 0
    fi
    
    if [ "$source" -nt "$target" ]; then
        echo "  🔄 업데이트 필요: $target"
        return 0
    fi
    
    return 1
}

# 변경사항 카운터
changes=0

# 1. CLAUDE.md → project-overview.md
echo "${YELLOW}1. 프로젝트 개요 확인...${NC}"
if check_changes "CLAUDE.md" ".agent/workflows/project-overview.md"; then
    ((changes++))
    echo "   💡 CLAUDE.md가 변경되었습니다. 수동으로 .agent/workflows/project-overview.md를 업데이트하세요."
fi

# 2. instructions.md → development-guidelines.md
echo "${YELLOW}2. 개발 가이드라인 확인...${NC}"
if check_changes ".claude/instructions.md" ".agent/references/development-guidelines.md"; then
    ((changes++))
    echo "   💡 instructions.md가 변경되었습니다. 수동으로 .agent/references/development-guidelines.md를 업데이트하세요."
fi

# 3. Commands 확인
echo "${YELLOW}3. Commands 확인...${NC}"
for cmd_file in .claude/commands/*.md; do
    cmd_name=$(basename "$cmd_file" .md)
    
    # 매핑 정의
    case "$cmd_name" in
        "ask")
            target=".agent/workflows/task-request.md"
            ;;
        "commit")
            target=".agent/workflows/commit.md"
            ;;
        "verify")
            target=".agent/workflows/verify.md"
            ;;
        "review-pr")
            target=".agent/workflows/review-pr.md"
            ;;
        *)
            target=".agent/workflows/$cmd_name.md"
            ;;
    esac
    
    if check_changes "$cmd_file" "$target"; then
        ((changes++))
        echo "   💡 $cmd_file이 변경되었습니다. 수동으로 $target를 업데이트하세요."
    fi
done

# 4. Skills 확인
echo "${YELLOW}4. Skills 확인...${NC}"

# coding-conventions
if check_changes ".claude/skills/coding-conventions/SKILL.md" ".agent/references/coding-conventions.md"; then
    ((changes++))
    echo "   💡 coding-conventions가 변경되었습니다. 수동으로 .agent/references/coding-conventions.md를 업데이트하세요."
fi

# weddly-architecture
if check_changes ".claude/skills/weddly-architecture/SKILL.md" ".agent/references/architecture.md"; then
    ((changes++))
    echo "   💡 weddly-architecture가 변경되었습니다. 수동으로 .agent/references/architecture.md를 업데이트하세요."
fi

# supabase-postgres-best-practices
if check_changes ".claude/skills/supabase-postgres-best-practices/SKILL.md" ".agent/references/postgres-best-practices.md"; then
    ((changes++))
    echo "   💡 postgres-best-practices가 변경되었습니다. 수동으로 .agent/references/postgres-best-practices.md를 업데이트하세요."
fi

echo ""
if [ $changes -eq 0 ]; then
    echo "${GREEN}✅ 모든 파일이 동기화되어 있습니다!${NC}"
else
    echo "${YELLOW}⚠️  $changes개의 파일이 업데이트가 필요합니다.${NC}"
    echo ""
    echo "📝 참고:"
    echo "  - 이 스크립트는 변경사항을 감지만 합니다."
    echo "  - 실제 동기화는 수동으로 진행해야 합니다."
    echo "  - Claude 파일을 수정한 후 해당 Antigravity 파일도 업데이트하세요."
fi

echo ""
echo "🔍 추가 정보:"
echo "  - Claude 설정: .claude/"
echo "  - Antigravity 설정: .agent/"
echo "  - 두 디렉토리는 독립적으로 유지됩니다."
