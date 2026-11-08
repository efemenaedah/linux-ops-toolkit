
#!/usr/bin/env bash

set -uo pipefail

PROJECT_DIR="$HOME/linux-ops-toolkit"
LOG_FILE="$PROJECT_DIR/logs/health_checks.log"

mkdir -p "$PROJECT_DIR/logs"
touch "$LOG_FILE"

echo "Running error-handling test..."

# Record the current log size so we can inspect only new entries.
INITIAL_LINES=$(wc -l < "$LOG_FILE")

# Run a command that deliberately fails and capture its exit status.
bash -c '
set -Eeuo pipefail
trap '\''rc=$?; printf "[%s] ERROR TEST: Command failed (exit code %s)\n" "$(date "+%Y-%m-%d %H:%M:%S %Z")" "$rc" >> "$1"; exit "$rc"'\'' ERR
echo "Deliberately triggering a failure..."
false
' _ "$LOG_FILE"

TEST_EXIT_CODE=$?

# Read only log entries added during this test.
NEW_LOG_ENTRIES=$(tail -n +"$((INITIAL_LINES + 1))" "$LOG_FILE")

if [[ "$TEST_EXIT_CODE" -ne 1 ]]; then
    echo "FAIL: Expected exit code 1; got $TEST_EXIT_CODE."
    exit 1
fi

if ! grep -q "ERROR TEST: Command failed (exit code 1)" <<< "$NEW_LOG_ENTRIES"; then
    echo "FAIL: Expected error message was not written to the log."
    exit 1
fi

echo "PASS: Failure was detected."
echo "PASS: Error was recorded in the log."
echo "PASS: Exit code was 1, as expected."
echo "All error-handling tests passed."
