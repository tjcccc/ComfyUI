#!/usr/bin/env bash
# Merge upstream/master into personal while preserving personal's AGENTS.md.
# Run from any directory. A clean merge is committed; nothing is pushed.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
cd -- "$repo_root"

if [[ "$(git branch --show-current)" != personal ]]; then
    printf 'Stopped: switch to the personal branch before running this script.\n' >&2
    exit 1
fi

for operation in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply sequencer; do
    if [[ -e "$(git rev-parse --git-path "$operation")" ]]; then
        printf 'Stopped: another Git operation is already in progress (%s).\n' "$operation" >&2
        printf 'Finish or abort that operation before running this script.\n' >&2
        exit 1
    fi
done

dirty=false
while IFS= read -r status_line; do
    # Allow this newly created script to run before it has been committed.
    if [[ -n "$status_line" && "$status_line" != '?? update-personal.sh' ]]; then
        dirty=true
    fi
done < <(git status --porcelain=v1 --untracked-files=all)
if [[ "$dirty" == true ]]; then
    printf 'Stopped: commit or stash your local changes first.\n' >&2
    git status --short
    exit 1
fi

original_head="$(git rev-parse HEAD)"
if ! git cat-file -e "$original_head:AGENTS.md"; then
    printf 'Stopped: personal must have a committed AGENTS.md to preserve.\n' >&2
    exit 1
fi

printf 'Fetching upstream master...\n'
git fetch --no-tags upstream refs/heads/master:refs/remotes/upstream/master

printf 'Merging into personal...\n'
merge_status=0
git merge --no-commit --no-ff --no-autostash refs/remotes/upstream/master || merge_status=$?

if [[ ! -f "$(git rev-parse --git-path MERGE_HEAD)" ]]; then
    if [[ "$merge_status" -eq 0 ]]; then
        printf 'Already up to date.\n'
    else
        printf 'Stopped: Git could not start the merge. See its error above.\n' >&2
    fi
    exit "$merge_status"
fi

# HEAD still points to personal's pre-merge commit, including on conflicts.
if ! git restore --source="$original_head" --staged --worktree -- AGENTS.md; then
    printf 'Stopped: could not restore AGENTS.md. The merge remains open.\n' >&2
    exit 1
fi

conflicts=()
while IFS= read -r -d '' path; do
    conflicts+=("$path")
done < <(git diff --name-only --diff-filter=U -z)

if [[ "${#conflicts[@]}" -gt 0 ]]; then
    printf '\nStopped: merge conflicts remain in these files:\n' >&2
    for path in "${conflicts[@]}"; do
        printf '  %q\n' "$path" >&2
    done
    printf '\nAGENTS.md was preserved. No merge commit was created.\n' >&2
    printf 'Resolve the files, stage them with git add, then run:\n' >&2
    printf '  git commit -m "chore: merge upstream master"\n' >&2
    printf 'To cancel this merge instead, run: git merge --abort\n' >&2
    exit 1
fi

if ! git diff --quiet "$original_head" -- AGENTS.md; then
    printf 'Stopped: AGENTS.md differs from personal. The merge remains open.\n' >&2
    exit 1
fi

git diff --cached --stat
if ! git commit -m "chore: merge upstream master"; then
    printf 'Stopped: the merge commit failed. Fix the error, then run git commit.\n' >&2
    exit 1
fi
printf '\nUpdated personal from upstream/master; AGENTS.md preserved. Nothing pushed.\n'
