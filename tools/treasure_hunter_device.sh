#!/bin/sh
set -eu

PACKAGE_ID=com.megacombat.treasurehunter
DEFAULT_XAPK=/home/thanh/Downloads/Treasure+Hunter+-+MMORPG_4.3.6_APKPure.xapk
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CAPTURE_DIR=${CAPTURE_DIR:-$PROJECT_ROOT/docs/original-captures}

usage() {
	cat <<'EOF'
Usage: tools/treasure_hunter_device.sh <command> [argument]

Commands:
  status                    List connected Android devices.
  install [xapk]            Install the base APK and ARM64 split from the XAPK.
  launch                    Stop and launch Treasure Hunter.
  shot [name]               Save a PNG screenshot under docs/original-captures.
  record [seconds]          Record gameplay (default 30, maximum 180 seconds).
  tcpip [port]              Enable ADB over Wi-Fi while USB is connected.
  pair <host:port> [code]   Pair using Android Wireless debugging.
  connect <host:port>       Connect to a device already exposing wireless ADB.

Set ANDROID_SERIAL when more than one device is connected.
EOF
}

adb_device() {
	if [ -n "${ANDROID_SERIAL:-}" ]; then
		adb -s "$ANDROID_SERIAL" "$@"
	else
		adb "$@"
	fi
}

require_device() {
	device_count=$(adb devices | awk 'NR > 1 && $2 == "device" {count++} END {print count + 0}')
	if [ -n "${ANDROID_SERIAL:-}" ]; then
		adb_device get-state >/dev/null
		return
	fi
	if [ "$device_count" -ne 1 ]; then
		echo "Expected exactly one authorized device, found $device_count." >&2
		echo "Unlock the phone, enable USB debugging, accept the RSA prompt, then run status." >&2
		exit 1
	fi
}

install_xapk() {
	xapk_path=${1:-$DEFAULT_XAPK}
	if [ ! -f "$xapk_path" ]; then
		echo "XAPK not found: $xapk_path" >&2
		exit 1
	fi
	command -v unzip >/dev/null 2>&1 || {
		echo "unzip is required." >&2
		exit 1
	}
	require_device

	free_kb=$(df -Pk /tmp | awk 'NR == 2 {print $4}')
	if [ "$free_kb" -lt 400000 ]; then
		echo "At least 400 MB free in /tmp is required for safe XAPK extraction." >&2
		exit 1
	fi

	device_abi=$(adb_device shell getprop ro.product.cpu.abi | tr -d '\r')
	case "$device_abi" in
		arm64-v8a) ;;
		*) echo "Warning: supplied split is ARM64, device ABI is $device_abi." >&2 ;;
	esac

	temp_dir=$(mktemp -d /tmp/treasure-hunter-xapk.XXXXXX)
	trap 'find "$temp_dir" -depth -delete 2>/dev/null || true' EXIT HUP INT TERM
	unzip -q -j "$xapk_path" \
		com.megacombat.treasurehunter.apk \
		config.arm64_v8a.apk \
		-d "$temp_dir"

	adb_device install-multiple -r -d \
		"$temp_dir/com.megacombat.treasurehunter.apk" \
		"$temp_dir/config.arm64_v8a.apk"
	echo "Installed $PACKAGE_ID from $xapk_path"
}

launch_game() {
	require_device
	adb_device shell am force-stop "$PACKAGE_ID"
	adb_device shell monkey -p "$PACKAGE_ID" -c android.intent.category.LAUNCHER 1 >/dev/null
	echo "Launched $PACKAGE_ID"
}

take_screenshot() {
	require_device
	mkdir -p "$CAPTURE_DIR"
	stamp=$(date +%Y%m%d-%H%M%S)
	name=${1:-gameplay-$stamp}
	output=$CAPTURE_DIR/$name.png
	adb_device exec-out screencap -p >"$output"
	echo "$output"
}

record_gameplay() {
	require_device
	duration=${1:-30}
	case "$duration" in
		''|*[!0-9]*) echo "Duration must be an integer from 1 to 180." >&2; exit 1 ;;
	esac
	if [ "$duration" -lt 1 ] || [ "$duration" -gt 180 ]; then
		echo "Duration must be from 1 to 180 seconds." >&2
		exit 1
	fi

	mkdir -p "$CAPTURE_DIR"
	stamp=$(date +%Y%m%d-%H%M%S)
	remote_path=/sdcard/ths-capture-$stamp.mp4
	local_path=$CAPTURE_DIR/gameplay-$stamp.mp4
	adb_device shell screenrecord --time-limit "$duration" "$remote_path"
	adb_device pull "$remote_path" "$local_path"
	adb_device shell rm -f "$remote_path"
	echo "$local_path"
}

command=${1:-}
case "$command" in
	status)
		adb devices -l
		;;
	install)
		install_xapk "${2:-$DEFAULT_XAPK}"
		;;
	launch)
		launch_game
		;;
	shot)
		take_screenshot "${2:-}"
		;;
	record)
		record_gameplay "${2:-30}"
		;;
	tcpip)
		require_device
		adb_device tcpip "${2:-5555}"
		;;
	pair)
		if [ -z "${2:-}" ]; then
			echo "pair requires host:pairing-port and optionally the pairing code." >&2
			exit 1
		fi
		if [ -n "${3:-}" ]; then
			adb pair "$2" "$3"
		else
			adb pair "$2"
		fi
		;;
	connect)
		if [ -z "${2:-}" ]; then
			echo "connect requires host:port." >&2
			exit 1
		fi
		adb connect "$2"
		;;
	*)
		usage
		exit 1
		;;
esac
