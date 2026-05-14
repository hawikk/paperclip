#!/usr/bin/env bash
# Scoped merge wrapper — uses GITHUB_RELEASE_BOT_TOKEN only for gh pr merge.
# All other gh commands (reads, status checks) continue under the default identity.
# Prevents widening hawikk/GITHUB_TOKEN write permissions to paperclipai/paperclip.
#
# Usage:
#   scripts/release-merge.sh --repo <owner/repo> --pr <number> [--squash|--merge|--rebase]
#
# Environment:
#   GITHUB_RELEASE_BOT_TOKEN  Required. Board-provisioned token with MergePullRequest scope.
#                             Must be installed by the Paperclip operator in the adapter config
#                             for ReleaseEngineer (d464fdd0) and CTO (325e35c6).

set -euo pipefail

usage() {
  echo "Usage: $0 --repo <owner/repo> --pr <number> [--squash|--merge|--rebase]" >&2
  exit 1
}

REPO=""
PR_NUMBER=""
MERGE_METHOD="--squash"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    REPO="$2"; shift 2 ;;
    --pr)      PR_NUMBER="$2"; shift 2 ;;
    --squash)  MERGE_METHOD="--squash"; shift ;;
    --merge)   MERGE_METHOD="--merge"; shift ;;
    --rebase)  MERGE_METHOD="--rebase"; shift ;;
    *) usage ;;
  esac
done

[[ -z "$REPO" || -z "$PR_NUMBER" ]] && usage

if [[ -z "${GITHUB_RELEASE_BOT_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_RELEASE_BOT_TOKEN is not set." >&2
  echo "Paperclip operator action required: install the board-provisioned token in the" >&2
  echo "adapter config for ReleaseEngineer (d464fdd0) and CTO (325e35c6)." >&2
  exit 2
fi

echo "Merging PR #${PR_NUMBER} in ${REPO} (${MERGE_METHOD}) via release-bot identity..."

# GH_TOKEN scoped only to this single command; default identity is restored immediately after.
GH_TOKEN="$GITHUB_RELEASE_BOT_TOKEN" gh pr merge "$PR_NUMBER" \
  --repo "$REPO" \
  $MERGE_METHOD \
  --delete-branch

echo "Merge complete."
