#!/usr/bin/env bash
# workspace-status.sh — 列出 workspace 各 repo 的 git 與 openspec 狀態
# 用法:
#   workspace-status.sh              全部
#   workspace-status.sh 5            只看第 5 個
#   workspace-status.sh hermes       依 repo 名
set -euo pipefail

ROOT="${1:-/home/zeng/Workspace}"
SHOW="${2:-all}"

printf '%-24s %-18s %5s %5s %s\n' REPO BRANCH AHEAD BEHIND STATUS
printf '%s\n' "$(printf '=%.0s' {1..72})"

for d in $(ls "$ROOT" 2>/dev/null); do
    [ -d "$ROOT/$d/.git" ] || continue
    repo="$ROOT/$d"
    branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "(no branch)")

    if git -C "$repo" rev-parse "origin/$branch" >/dev/null 2>&1; then
        oh="origin/$branch"
    else
        oh="origin/HEAD"
    fi

    ahead=$(git -C "$repo" rev-list --count "$oh"..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$repo" rev-list --count HEAD.."$oh" 2>/dev/null || echo 0)

    # git status 簡化截斷（最多 60 字）
    status=$(git -C "$repo" status --short 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g;s/^ //')
    [ -z "$status" ] && status="-"
    [ ${#status} -gt 60 ] && status="${status:0:57}..."
    printf '%-24s %-18s %5s %5s %s\n' "$d" "$branch" "$ahead" "$behind" "$status"

    # openspec change 狀態（只印在 openspec/changes 內有實際 change 者）
    if [ -d "$repo/openspec/changes" ]; then
        # 列出非 archive 的 change 目錄（-A 排除 . 和 ..）
        ch=$(ls -A "$repo/openspec/changes" 2>/dev/null | grep -v '^archive$' | sort || true)
        if [ -n "$ch" ]; then
            oc=$(printf '%s\n' "$ch" | tr '\n' ' ')
            printf '%s\n' "        openspec: $oc"
        fi
    fi
done

echo ""
echo "提示: 逐 repo 深入檢查用"
echo "  cd $ROOT/cardea && openspec changes list"
