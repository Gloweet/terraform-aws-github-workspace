#!/usr/bin/env bash
set -euo pipefail

# Push locally-present *.sops* files (SOPS-encrypted secrets kept out of git
# via .gitignore) to the matching repo on pve. These never come from
# `git clone`/`git pull` since they're intentionally untracked -- this is
# the out-of-band channel for them.
#
# Override REMOTE_HOST / REMOTE_PATH via env vars if needed, e.g.:
#   REMOTE_PATH=/git/gloweet/terraform-aws-github-workspace-staging ./scripts/push-sops-secrets.sh

REMOTE_HOST="${REMOTE_HOST:-root@192.168.1.197}"
REMOTE_PATH="${REMOTE_PATH:-/git/gloweet/terraform-aws-github-workspace}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

mapfile -t FILES < <(find . -iname '*.sops*' -not -path './.git/*' | sed 's|^\./||')

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No .sops files found under $SCRIPT_DIR -- nothing to push."
  exit 0
fi

echo "Pushing ${#FILES[@]} .sops file(s) to $REMOTE_HOST:$REMOTE_PATH ..."
printf '%s\n' "${FILES[@]}" | rsync -avz --files-from=- ./ "$REMOTE_HOST:$REMOTE_PATH/"

# Repo on pve is owned by the 'ai' user (webmux runs as ai, not root); rsync
# over ssh as root would otherwise leave root-owned files behind.
ssh "$REMOTE_HOST" "chown -R ai:ai '$REMOTE_PATH'"

echo "Done."
