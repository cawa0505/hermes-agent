#!/usr/bin/env bash
# sync_upstream.sh — 同步 NousResearch/hermes-agent 上游變更到 cawa0505/hermes-agent 的 main 與 cawa/main
set -euo pipefail

REPO_DIR="${1:-$HOME/Workspace/hermes-agent}"

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "錯誤: $REPO_DIR 不是有效的 git 倉庫"
    exit 1
fi

cd "$REPO_DIR"

echo "=== [1/5] 檢查工作區狀態 ==="
STASHED=0
if [ -n "$(git status --porcelain)" ]; then
    echo "檢測到未提交修改，正在暫存 (git stash)..."
    git stash push -m "sync-upstream-auto-stash-$(date +%s)"
    STASHED=1
fi

echo "=== [2/5] 從 upstream 與 origin 抓取最新修訂 ==="
git fetch upstream
git fetch origin

echo "=== [3/5] 更新純淨 main 分支 ==="
git checkout main
git merge --ff-only upstream/main
git push origin main
echo "✓ main 分支已與 upstream/main 保持一致並推送到 origin/main"

echo "=== [4/5] 合併上游變更到客製分支 cawa/main ==="
git checkout cawa/main

if git merge main -m "merge: sync upstream/main into cawa/main"; then
    echo "✓ cawa/main 無衝突合併完成！"
    git push origin cawa/main
    echo "✓ 已成功推送到 origin/cawa/main"
else
    echo "⚠️ 合併發生衝突，請手動解決衝突後再 push："
    echo "   cd $REPO_DIR"
    echo "   git status"
    exit 1
fi

if [ "$STASHED" -eq 1 ]; then
    echo "=== [5/5] 恢復先前暫存的修改 ==="
    git stash pop || echo "⚠️ stash pop 存在局部衝突，請手動檢查"
else
    echo "=== [5/5] 完成，工作區保持乾淨 ==="
fi

echo "🎉 同步完成！最新 upstream 已成功整合進 cawa/main。"
