#!/usr/bin/env bash
# Run Emberfield's headless test suites with user:// isolated from real saves.
#
# Usage: GODOT=/path/to/Godot_v4.6-stable_linux.x86_64 tools/run_tests.sh [workdir]
#
# - workdir (default: a new mktemp dir) receives isolated XDG dirs and all logs.
# - LAN harnesses start the client 0.5 s after the host: the runners use fixed
#   lifetimes (host 3.5-5.5 s), so a late client misses the host's checks.
set -u

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${1:-$(mktemp -d -t emberfield-tests-XXXXXX)}"
LAN_STAGGER="${LAN_STAGGER:-0.5}"
mkdir -p "$WORK/logs"
failures=0

isolate() { # $1 = profile name
	export XDG_DATA_HOME="$WORK/xdg-$1/data" XDG_CONFIG_HOME="$WORK/xdg-$1/config" XDG_CACHE_HOME="$WORK/xdg-$1/cache"
	mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
}

report() { # $1 = name, $2 = exit code
	if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1 (exit $2)"; failures=$((failures + 1)); fi
}

"$GODOT" --headless --version >/dev/null 2>&1 || { echo "Godot not runnable: $GODOT" >&2; exit 2; }

( isolate import; "$GODOT" --headless --editor --quit-after 120 --path "$ROOT" >"$WORK/logs/import.log" 2>&1 )
report "import" $?

python3 -I "$ROOT/tools/provenance/test_check_provenance.py" >"$WORK/logs/provenance_unit.log" 2>&1
report "provenance gate unit tests" $?
python3 -I "$ROOT/tools/provenance/check_provenance.py" --mode dev --quiet >"$WORK/logs/provenance_dev.log" 2>&1
report "provenance gate (dev)" $?
# Release mode is expected to fail until every asset is original/verified; it is reported, not counted.
python3 -I "$ROOT/tools/provenance/check_provenance.py" --mode release --quiet >"$WORK/logs/provenance_release.log" 2>&1
echo "INFO  provenance gate (release): $(tail -1 "$WORK/logs/provenance_release.log")"

for suite in InventoryTransactionTests SurvivalTests LegacySystemTests ProvenanceTests; do
	( isolate "$suite"; timeout 600 "$GODOT" --headless --path "$ROOT" "res://tests/$suite.tscn" >"$WORK/logs/$suite.log" 2>&1 )
	report "$suite" $?
done

for runner in LanPeerRunner LanCombatPeerRunner LanPlayerPeerRunner; do
	( isolate "$runner-host"; timeout 180 "$GODOT" --headless --path "$ROOT" "res://tests/$runner.tscn" -- \
		--role=host --output="$WORK/logs/$runner-host.json" >"$WORK/logs/$runner-host.log" 2>&1 ) &
	host_pid=$!
	sleep "$LAN_STAGGER"
	( isolate "$runner-client"; timeout 180 "$GODOT" --headless --path "$ROOT" "res://tests/$runner.tscn" -- \
		--role=client --output="$WORK/logs/$runner-client.json" >"$WORK/logs/$runner-client.log" 2>&1 )
	client_rc=$?
	wait "$host_pid"
	host_rc=$?
	report "$runner (host)" "$host_rc"
	report "$runner (client)" "$client_rc"
done

echo "Logs: $WORK/logs"
[ "$failures" -eq 0 ] && echo "ALL PASSED" || echo "$failures FAILED"
exit "$failures"
