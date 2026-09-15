#!/bin/bash
#
# record-snapshots.sh — (Re)record snapshot references for
# SonyHeadphonesClientSnapshotTests.
#
# Default platform is macOS, matching the AppKit-based snapshot tests in this
# repo (they render macOS views and cannot execute on an iOS simulator).
#
# macOS flow:
#   Run the snapshot tests with SNAPSHOT_TESTING_RECORD=<mode> on the host Mac
#   so references are (re)written to disk. The app is sandboxed, which would
#   block writing reference images next to the sources, so the test host is
#   signed without entitlements for the recording run (CODE_SIGN_ENTITLEMENTS=).
#
# iOS flow (PLATFORM=ios):
#   1. Ensure the requested iOS simulator runtime is installed
#      (downloads it with `xcodebuild -downloadPlatform iOS` when missing).
#   2. Ensure an iPhone 16 Pro device exists for that runtime
#      (creates one with `simctl create` when missing) and boot it.
#   3. Run the snapshot tests on that simulator with
#      SNAPSHOT_TESTING_RECORD=<mode>. This requires iOS-compatible snapshot
#      tests — the script warns when the target still imports AppKit/Cocoa.
#
# Usage:
#   ./scripts/record-snapshots.sh [--dry-run] [--record-mode <mode>] [--platform <macos|ios>]
#
# Configuration (all overridable via environment):
#   PLATFORM        macos (default) or ios
#   DEVICE_NAME     Simulator device name            (default: iPhone 16 Pro, ios only)
#   RUNTIME_VERSION iOS runtime version, e.g. 26.5   (default: 28.0, ios only)
#   SCHEME          Xcode scheme to test             (default: SonyHeadphonesClient)
#   TEST_TARGET     Test bundle to run               (default: SonyHeadphonesClientSnapshotTests)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$PROJECT_DIR/SonyHeadphonesClient.xcodeproj"

DEVICE_NAME="${DEVICE_NAME:-iPhone 16 Pro}"
DEVICE_TYPE="${DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro}"
PLATFORM="${PLATFORM:-macos}"
RUNTIME_VERSION="${RUNTIME_VERSION:-28.0}"
RUNTIME_ID="com.apple.CoreSimulator.SimRuntime.iOS-${RUNTIME_VERSION//./-}"
SCHEME="${SCHEME:-SonyHeadphonesClient}"
TEST_TARGET="${TEST_TARGET:-SonyHeadphonesClientSnapshotTests}"
RECORD_MODE="all"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --record-mode)
            RECORD_MODE="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --help | -h)
            sed -n '2,/^$/p' "$0"
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            echo "usage: $0 [--dry-run] [--record-mode <all|missing|failed|never>] [--platform <macos|ios>]" >&2
            exit 2
            ;;
    esac
done

case "$PLATFORM" in
    macos | ios) ;;
    *)
        echo "error: invalid platform: $PLATFORM (expected macos|ios)" >&2
        exit 2
        ;;
esac

case "$RECORD_MODE" in
    all | missing | failed | never) ;;
    *)
        echo "error: invalid record mode: $RECORD_MODE (expected all|missing|failed|never)" >&2
        exit 2
        ;;
esac

log() { printf '[record-snapshots] %s\n' "$*" >&2; }
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '[record-snapshots] (dry-run) would run: %s\n' "$*" >&2
    else
        "$@"
    fi
}

runtime_installed() {
    xcrun simctl list runtimes -j |
        python3 -c 'import json,sys
data = json.load(sys.stdin)
ids = [r.get("identifier", "") for r in data.get("runtimes", [])]
sys.exit(0 if sys.argv[1] in ids else 1)' "$RUNTIME_ID"
}

ensure_runtime() {
    if runtime_installed; then
        log "iOS $RUNTIME_VERSION runtime is installed ($RUNTIME_ID)."
        return 0
    fi
    log "iOS $RUNTIME_VERSION runtime is missing; downloading the iOS platform..."
    run xcodebuild -downloadPlatform iOS
    if [[ "$DRY_RUN" -eq 1 ]]; then
        return 0
    fi
    if runtime_installed; then
        log "iOS $RUNTIME_VERSION runtime installed successfully."
        return 0
    fi
    cat >&2 <<EOF
error: iOS $RUNTIME_VERSION runtime ($RUNTIME_ID) is still unavailable after
downloading the iOS platform. Apple has not published that runtime yet —
re-run with an installed version, e.g. RUNTIME_VERSION=26.5 $0
EOF
    return 1
}

find_device_udid() {
    xcrun simctl list devices -j |
        DEVICE_NAME="$DEVICE_NAME" RUNTIME_ID="$RUNTIME_ID" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
want_name = os.environ["DEVICE_NAME"]
want_runtime = os.environ["RUNTIME_ID"]
for runtime, devices in data.get("devices", {}).items():
    if want_runtime not in runtime:
        continue
    for d in devices:
        if d.get("name") == want_name and d.get("isAvailable", True):
            print(d["udid"])
            sys.exit(0)
sys.exit(1)'
}

ensure_device() {
    local udid
    if udid="$(find_device_udid)"; then
        log "Found existing device \"$DEVICE_NAME\" ($udid) for iOS $RUNTIME_VERSION."
    else
        log "No \"$DEVICE_NAME\" device for iOS $RUNTIME_VERSION; creating one..."
        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf '[record-snapshots] (dry-run) would run: xcrun simctl create "%s" "%s" "%s"\n' \
                "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME_ID" >&2
            printf '%s' '<new-device-udid>'
            return 0
        fi
        udid="$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$RUNTIME_ID")"
        log "Created device \"$DEVICE_NAME\" ($udid)."
    fi

    local state
    state="$(xcrun simctl list devices -j | python3 -c 'import json,sys
udid = sys.argv[1]
for devices in json.load(sys.stdin).get("devices", {}).values():
    for d in devices:
        if d.get("udid") == udid:
            print(d.get("state", "Unknown"))
            sys.exit(0)' "$udid")"
    if [[ "$state" != "Booted" ]]; then
        log "Booting device ($udid)..."
        run xcrun simctl boot "$udid" || true
    else
        log "Device is already booted."
    fi
    printf '%s' "$udid"
}

warn_if_macos_only_tests() {
    if grep -rql -e 'import AppKit' -e 'import Cocoa' "$PROJECT_DIR/$TEST_TARGET" 2>/dev/null; then
        cat >&2 <<EOF
[record-snapshots] WARNING: $TEST_TARGET imports AppKit/Cocoa, so it can only
[record-snapshots] build for macOS. Recording it on an iOS simulator requires
[record-snapshots] porting the tests to an iOS-compatible snapshotting strategy
[record-snapshots] first; the xcodebuild invocation below is expected to fail
[record-snapshots] until then.
EOF
    fi
}

run_tests() {
    local destination="$1"
    local label="$2"
    shift 2

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "(dry-run) would now record snapshots with mode '$RECORD_MODE' on $label."
        return 0
    fi

    log "Recording snapshots (mode: $RECORD_MODE) on $label..."
    (
        cd "$PROJECT_DIR"
        SNAPSHOT_TESTING_RECORD="$RECORD_MODE" xcodebuild test \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "$destination" \
            -only-testing:"$TEST_TARGET" \
            -skipPackagePluginValidation \
            "$@"
    )
    log "Done. Review the changes under $TEST_TARGET/__Snapshots__ before committing."
}

main() {
    if [[ "$PLATFORM" == "macos" ]]; then
        run_tests "platform=macOS" "macOS (host Mac)" CODE_SIGN_ENTITLEMENTS=
        return 0
    fi

    ensure_runtime
    local udid
    udid="$(ensure_device)"
    warn_if_macos_only_tests
    run_tests "platform=iOS Simulator,id=$udid" "$DEVICE_NAME (iOS $RUNTIME_VERSION)"
}

main "$@"
