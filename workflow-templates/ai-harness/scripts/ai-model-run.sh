#!/usr/bin/env bash
# Runs ONE agent through LiteLLM, which now owns model routing and failover
# server-side (litellm proxy's `router_settings.fallbacks`). The chain that
# used to live here - Claude -> OpenCode Go -> OpenRouter, with a local quota
# probe (scripts/model-quota.mjs, removed) deciding which to skip - is
# configured once on the proxy (gitops-demo's docs/proxmox/LITELLM_LXC_SETUP.md),
# not duplicated per repo or per script.
#
# Prerequisite (local use only - CI has its own setup, see
# .github/actions/setup-opencode): a "litellm" provider pointed at the LXC in
# your opencode config (~/.config/opencode/opencode.json), e.g.:
#
#   "litellm": {
#     "npm": "@ai-sdk/openai-compatible",
#     "options": {
#       "baseURL": "http://192.168.1.135:4000/v1",
#       "apiKey": "<LITELLM_MASTER_KEY, or a scoped virtual key>"
#     },
#     "models": { "claude-sonnet-5": {}, "claude-opus-5": {} }
#   }
#
# Each attempt runs in its OWN `opencode run` process, so the model context is
# never shared between this runner and its caller.
#
# Usage:
#   bash scripts/ai-model-run.sh --agent <name> --prompt <text> [--model m] [--log f]
#
# Exit 0 when the call completes cleanly, 1 otherwise. There is no more
# client-side rotation: a failure here means LiteLLM itself exhausted its own
# fallback chain (or every fallback target also failed) - that is the signal
# to look at the proxy (`https://litellm.antoninmarxer.com/ui`, or the LXC's
# own logs), not to retry locally.
set -euo pipefail

AGENT=""
PROMPT=""
MODEL="${MODEL:-litellm/claude-sonnet-5}"
LOG="/tmp/ai-model-run.log"

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
  echo
  echo "  --agent <name>   opencode agent to run (required)"
  echo "  --prompt <text>  prompt for that agent (required)"
  echo "  --model <m>      default: litellm/claude-sonnet-5"
  echo "  --log <f>        default /tmp/ai-model-run.log"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) AGENT="${2:-}"; shift 2 ;;
    --prompt) PROMPT="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --log) LOG="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -n "$AGENT" && -n "$PROMPT" ]] || { echo "missing --agent and/or --prompt" >&2; usage; }

# A long model call can be silent in the log for many minutes. This writes a
# wall-clock heartbeat every HEARTBEAT_INTERVAL seconds while the attempt is in
# flight, so `tail -f` and the orchestrator show a sign of life instead of an
# apparently frozen run.
HEARTBEAT_INTERVAL="${HEARTBEAT_INTERVAL:-120}"
HEARTBEAT_PID=""
start_heartbeat() {
  ( while sleep "$HEARTBEAT_INTERVAL"; do
      printf '== [heartbeat %s] %s: still running\n' "$(date -u +%H:%M:%SZ)" "$1" >>"$LOG"
    done ) &
  HEARTBEAT_PID=$!
}
stop_heartbeat() {
  if [[ -n "$HEARTBEAT_PID" ]]; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
    HEARTBEAT_PID=""
  fi
}

echo "== ai-model-run: ${AGENT} via ${MODEL} (LiteLLM owns the fallback chain)" | tee -a "$LOG"
start_heartbeat "${AGENT} on ${MODEL}"
set +e
opencode run --agent "$AGENT" --model "$MODEL" --auto --print-logs "$PROMPT" 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
set -e
stop_heartbeat

if [[ $rc -ne 0 ]]; then
  echo "== ${AGENT}: failed on ${MODEL} (exit ${rc}) - LiteLLM's own fallback chain is exhausted; check the proxy, not this script" | tee -a "$LOG"
fi
exit "$rc"
