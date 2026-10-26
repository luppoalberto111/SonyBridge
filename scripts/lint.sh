#!/bin/bash
#
# lint.sh — Run SwiftLint over the repository and fail when it reports any
# violations.
#
# SwiftLint exits 0 when it only finds warnings, so this script captures the
# report, counts warnings/errors and exits non-zero if there are any. In
# GitHub Actions the report is emitted with the github-actions-logging
# reporter, which surfaces every violation as an annotation on the run.
#
# Usage:
#   ./scripts/lint.sh
#
# Configuration (all overridable via environment):
#   SWIFTLINT         SwiftLint executable (default: swiftlint)
#   SWIFTLINT_CONFIG  Path to the config  (default: <repo>/.swiftlint.yml)
#   LINT_REPORTER     SwiftLint reporter  (default: github-actions-logging in
#                                          CI, xcode otherwise)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SWIFTLINT="${SWIFTLINT:-swiftlint}"
CONFIG="${SWIFTLINT_CONFIG:-$PROJECT_DIR/.swiftlint.yml}"

if ! command -v "$SWIFTLINT" >/dev/null 2>&1; then
  echo "error: SwiftLint is not installed. Install it with 'brew install swiftlint' or set SWIFTLINT." >&2
  exit 127
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "error: SwiftLint config not found at $CONFIG" >&2
  exit 1
fi

if [[ -n "${LINT_REPORTER:-}" ]]; then
  REPORTER="$LINT_REPORTER"
elif [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  REPORTER="github-actions-logging"
else
  REPORTER="xcode"
fi

is_ci=0
if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
  is_ci=1
fi

announce() {
  if [[ "$is_ci" -eq 1 ]]; then
    echo "::error title=SwiftLint::$1"
  else
    echo "error: $1" >&2
  fi
}

LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/swiftlint.XXXXXX")"
trap 'rm -f "$LOG_FILE"' EXIT

echo "SwiftLint version: $("$SWIFTLINT" version)"

set +e
"$SWIFTLINT" lint \
  --config "$CONFIG" \
  --quiet \
  --reporter "$REPORTER" 2>&1 | tee "$LOG_FILE"
lint_status=${PIPESTATUS[0]}
set -e

warning_count=$(grep -cE '^::warning |: warning: ' "$LOG_FILE" || true)
error_count=$(grep -cE '^::error |: error: ' "$LOG_FILE" || true)

summary="SwiftLint found ${warning_count} warning(s) and ${error_count} error(s)."

if [[ "$warning_count" -gt 0 || "$error_count" -gt 0 ]]; then
  announce "$summary See the log above for details."
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "## SwiftLint"
      echo
      echo "$summary"
      echo
      echo '```'
      grep -E '^::warning |^::error |: warning: |: error: ' "$LOG_FILE" || true
      echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 1
fi

if [[ "$lint_status" -ne 0 ]]; then
  announce "SwiftLint exited with status ${lint_status} without reporting violations."
  exit "$lint_status"
fi

echo "SwiftLint found no violations."
