#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok_count=0
skip_count=0
fail_count=0

resolve_branch() {
  local repo_dir="$1"
  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/main"; then
    echo "main"
    return 0
  fi
  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/master"; then
    echo "master"
    return 0
  fi
  if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/main"; then
    echo "main"
    return 0
  fi
  if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/master"; then
    echo "master"
    return 0
  fi
  return 1
}

for dir in "$SCRIPT_DIR"/*/; do
  [ -d "$dir" ] || continue

  if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "skip: $(basename "$dir") (not a git repo)"
    skip_count=$((skip_count + 1))
    continue
  fi

  branch=""
  if ! branch="$(resolve_branch "$dir")"; then
    echo "skip: $(basename "$dir") (no main/master branch found)"
    skip_count=$((skip_count + 1))
    continue
  fi

  echo "sync: $(basename "$dir") (branch=$branch)"
  if ! git -C "$dir" checkout "$branch"; then
    echo "fail: $(basename "$dir") (checkout $branch failed)"
    fail_count=$((fail_count + 1))
    continue
  fi

  if git -C "$dir" pull; then
    ok_count=$((ok_count + 1))
  else
    echo "fail: $(basename "$dir") (pull failed on $branch)"
    fail_count=$((fail_count + 1))
  fi
done

echo
echo "done: ok=$ok_count skip=$skip_count fail=$fail_count"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
