#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────
# 변경 사항 전부 add → 커밋 메시지 입력 → 현재 브랜치로 push
# 사용법: ./git-quick-push.sh
# ───────────────────────────────────────────────────────────

git status
echo
read -rp "Commit message: " msg
if [[ -z "$msg" ]]; then
  echo "❌  빈 메시지, 종료합니다."
  exit 1
fi

git add -A
git commit -m "$msg"

branch=$(git symbolic-ref --short HEAD)
echo
echo "➡️  pushing to origin/$branch ..."
git push origin "$branch"