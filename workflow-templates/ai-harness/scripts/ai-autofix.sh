#!/usr/bin/env bash
# Chains an independent AI review of a PR with a separate-context auto-fix run.
#
# Two SEPARATE `opencode run` processes, on purpose: the reviewer and the fixer
# must not share a model context, or the fixer would inherit the reviewer's
# framing instead of reading the PR fresh. Each half goes through
# scripts/ai-model-run.sh, which calls LiteLLM - model routing and failover
# (Claude -> OpenCode Go -> OpenRouter) now live on the proxy, not here.
#
# Usage:
#   bash scripts/ai-autofix.sh --pr 23 --ticket GLOW-181 [--repo <owner>/<repo>]
#                                [--model m] [--log /tmp/ai.log] [--dry-run]
#
# Stops (non-zero) if the review step fails - the fixer never runs on a review
# that did not land. A "request-changes" decision is NOT a failure: it is
# exactly the signal that fixes are wanted.
set -euo pipefail

PR=""
TICKET=""
# Defaults to the current git remote, so a clone of any bootstrapped repo works
# without editing this script.
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)}"
MODEL=""
LOG="/tmp/ai-autofix.log"
DRY_RUN="false"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/ai-model-run.sh"

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  echo
  echo "  --pr <n>      PR number to review and then fix (required)"
  echo "  --ticket <id> Linear ticket / GitHub issue the PR closes (required)"
  echo "  --repo <r>    default: the current repository (gh repo view)"
  echo "  --model <m>   primary model for both halves (default: litellm/claude-sonnet-5)"
  echo "  --log <f>     default /tmp/ai-autofix.log"
  echo "  --dry-run     print the plan, run nothing"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR="${2:-}"; shift 2 ;;
    --ticket) TICKET="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    *) usage ;;
  esac
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "PR:     #${PR:-<missing>}"
  echo "ticket: ${TICKET:-<missing>}"
  echo "repo:   ${REPO}"
  echo "log:    ${LOG}"
  echo
  echo "each half runs through scripts/ai-model-run.sh -> LiteLLM (${MODEL:-litellm/claude-sonnet-5}), which owns the Claude -> OpenCode Go -> OpenRouter fallback chain"
  exit 0
fi

[[ -n "$PR" && -n "$TICKET" ]] || { echo "missing --pr and/or --ticket" >&2; usage; }

REVIEW_PROMPT="Review PR #${PR} in ${REPO}. Fan out to the relevant review-* specialists for this diff, then post one consolidated review comment and apply the approve / comment / request-changes decision."
DEVELOP_PROMPT="${TICKET}: continue the existing open PR for this ticket and address its review comments, run the real gates, then push the fixes. You are the fixer in a SEPARATE context from the reviewer that just posted on the PR - do not assume anything about its reasoning, read its comments fresh from the PR with gh, and fix what it reports."

run_half() {
  local agent="$1" prompt="$2"
  local args=(--agent "$agent" --prompt "$prompt" --log "$LOG")
  [[ -n "$MODEL" ]] && args+=(--model "$MODEL")
  bash "$RUNNER" "${args[@]}"
}

# --- end-to-end idempotency -------------------------------------------------
# The loop is skip-safe in both directions:
#   - review half: skipped when the PR head sha already carries an ai-review marker
#   - fixer half:  skipped when a commit already references the review artifact
# An unreadable PR (no gh, no network) never causes a skip - it just costs one run.
head_sha() { gh pr view "$PR" --repo "$REPO" --json headRefOid --jq '.headRefOid' 2>/dev/null || true; }
last_reviewed_head() {
  gh api "repos/$REPO/issues/$PR/comments" --jq '.[].body' 2>/dev/null |
    grep -oE 'ai-review head=[a-f0-9]+' | tail -1 | cut -d= -f2 || true
}
artifact_id() { echo "ai-review_$(printf '%s' "$1" | cut -c1-12)"; }
review_actioned() {
  gh pr view "$PR" --repo "$REPO" --json commits \
    --jq '.commits[] | "\(.messageHeadline) \(.messageBody)"' 2>/dev/null | grep -qF "$1"
}

echo "== ai-autofix: review PR #${PR}, then fix ${TICKET}" | tee "$LOG"

HEAD="$(head_sha)"
REVIEWED_HEAD=""
if [[ -n "$HEAD" ]]; then
  REVIEWED_HEAD="$(last_reviewed_head)"
  echo "== head ${HEAD:0:12}; last reviewed ${REVIEWED_HEAD:0:12}" | tee -a "$LOG"
fi

if [[ -n "$HEAD" && "$HEAD" == "$REVIEWED_HEAD" ]]; then
  echo "== [1/2] review: SKIPPED - head ${HEAD:0:12} already reviewed (marker present)" | tee -a "$LOG"
else
  echo "== [1/2] review-coordinator on PR #${PR}" | tee -a "$LOG"
  if ! run_half review-coordinator "$REVIEW_PROMPT"; then
    echo "== review failed on all usable models; not running the fixer (nothing to act on)" | tee -a "$LOG"
    exit 1
  fi
  [[ -n "$HEAD" ]] && REVIEWED_HEAD="$HEAD"
fi

ARTIFACT=""
[[ -n "$REVIEWED_HEAD" ]] && ARTIFACT="$(artifact_id "$REVIEWED_HEAD")"

if [[ -n "$ARTIFACT" ]] && review_actioned "$ARTIFACT"; then
  echo "== [2/2] fixer: SKIPPED - ${ARTIFACT} already actioned by a commit (nothing to do)" | tee -a "$LOG"
  echo "== done. No new work: review and fix already both applied." | tee -a "$LOG"
  exit 0
fi

echo "== [2/2] develop-coordinator on ${TICKET}${ARTIFACT:+ (reviews ${ARTIFACT})}" | tee -a "$LOG"
FIXER_PROMPT="$DEVELOP_PROMPT"
if [[ -n "$ARTIFACT" ]]; then
  FIXER_PROMPT="${DEVELOP_PROMPT} You are the fixer for the review artifact ${ARTIFACT}: reference it in your final commit message, e.g. '... (reviews ${ARTIFACT})', so a re-run knows this review has been actioned."
fi
run_half develop-coordinator "$FIXER_PROMPT"

echo "== done. Review + fixes on PR #${PR}; full log: ${LOG}" | tee -a "$LOG"
