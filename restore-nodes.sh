#!/bin/sh
# Re-enable custom nodes that were disabled by renaming them to "<name>.disabled".
#
# ComfyUI skips any entry under custom_nodes/ whose name ends in ".disabled"
# (see nodes.py, the `module_path.endswith(".disabled")` check), so disabling and
# restoring a node is just a rename. This script does the rename safely.
#
#   ./restore-nodes.sh                 list what is currently disabled
#   ./restore-nodes.sh <name>          restore one (with or without the suffix)
#   ./restore-nodes.sh --all           restore everything
#   ./restore-nodes.sh --disable <name>  turn a node back off
#
# Note: nodes switched off from inside ComfyUI-Manager use a different mechanism
# and are not listed here - re-enable those in the Manager UI.

set -eu

cd "$(dirname "$0")" || exit 1
NODES_DIR="custom_nodes"

[ -d "$NODES_DIR" ] || { echo "ERROR: $NODES_DIR not found next to this script." >&2; exit 1; }

# Emit one path per disabled entry. Uses a glob rather than `find | while`, so
# callers can loop in the current shell and see failures in the exit status.
list_disabled() {
	for d in "$NODES_DIR"/*.disabled; do
		[ -e "$d" ] || continue
		echo "$d"
	done
}

warn_if_running() {
	if pgrep -f "python3 main.py" >/dev/null 2>&1; then
		echo
		echo "NOTE: ComfyUI looks like it is running. Restart it for this to take effect."
	fi
}

# restore_one <path-to-.disabled>
restore_one() {
	src="$1"
	dst="${src%.disabled}"

	if [ ! -e "$src" ]; then
		echo "ERROR: no such disabled node: $src" >&2
		return 1
	fi
	if [ -e "$dst" ]; then
		echo "ERROR: $dst already exists - refusing to overwrite." >&2
		echo "       Remove or rename one of them, then run again." >&2
		return 1
	fi

	mv "$src" "$dst"
	echo "restored: $(basename "$dst")"
}

disable_one() {
	src="${1%.disabled}"
	dst="$src.disabled"

	if [ ! -e "$src" ]; then
		echo "ERROR: no such node: $src" >&2
		return 1
	fi
	if [ -e "$dst" ]; then
		echo "ERROR: $dst already exists - refusing to overwrite." >&2
		return 1
	fi

	mv "$src" "$dst"
	echo "disabled: $(basename "$dst")"
}

# Resolve a user-supplied name to a path under custom_nodes/, tolerating a
# leading "custom_nodes/" and a trailing ".disabled".
resolve() {
	name="$1"
	name="${name#"$NODES_DIR"/}"
	name="${name%/}"
	name="${name%.disabled}"
	case "$name" in
	"" | "." | ".." | */*)
		echo "ERROR: node name must be one entry directly under $NODES_DIR." >&2
		return 1
		;;
	esac
	echo "$NODES_DIR/$name"
}

case "${1:-}" in
"")
	disabled="$(list_disabled)"
	if [ -z "$disabled" ]; then
		echo "Nothing is disabled."
		exit 0
	fi
	echo "Disabled custom nodes:"
	echo "$disabled" | while IFS= read -r d; do
		echo "  $(basename "$d" .disabled)"
	done
	echo
	echo "Restore with: $0 <name>   (or --all)"
	;;

--all)
	any=0
	failed=0
	for d in "$NODES_DIR"/*.disabled; do
		[ -e "$d" ] || continue
		any=1
		restore_one "$d" || failed=1
	done
	if [ "$any" -eq 0 ]; then
		echo "Nothing is disabled."
		exit 0
	fi
	warn_if_running
	exit "$failed"
	;;

--disable)
	[ $# -ge 2 ] || { echo "ERROR: --disable needs a node name." >&2; exit 1; }
	resolved="$(resolve "$2")" || exit 1
	disable_one "$resolved"
	warn_if_running
	;;

-h | --help)
	sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
	;;

*)
	resolved="$(resolve "$1")" || exit 1
	restore_one "$resolved.disabled"
	warn_if_running
	;;
esac
