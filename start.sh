#!/bin/sh
# Run from the repo dir regardless of where this was invoked from.
cd "$(dirname "$0")" || exit 1

# Refuse to run outside comfyenv. Resolve Python through CONDA_PREFIX instead
# of PATH, where python.org may appear before the active Conda environment.
COMFY_PYTHON="${CONDA_PREFIX:-}/bin/python"
case "${CONDA_PREFIX:-}" in
	*/envs/comfyenv)
		if [ ! -x "$COMFY_PYTHON" ]; then
			echo "ERROR: comfyenv has no usable Python at $COMFY_PYTHON."
			exit 1
		fi
		;;
	*)
		echo "ERROR: comfyenv is not active."
		echo "       Run: conda activate comfyenv"
		exit 1
		;;
esac

# Catch stale pinned packages after a ComfyUI update before they fail during
# imports with a misleading missing-module or missing-attribute exception.
if ! "$COMFY_PYTHON" - <<'PY'
import re
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path

pin_pattern = re.compile(r"^([A-Za-z0-9_.-]+)==([^;\s]+)$")
mismatches = []

for raw_line in Path("requirements.txt").read_text(encoding="utf-8").splitlines():
    line = raw_line.partition("#")[0].strip()
    match = pin_pattern.fullmatch(line)
    if match is None:
        continue
    package, required = match.groups()
    try:
        installed = version(package)
    except PackageNotFoundError:
        installed = "not installed"
    if installed != required:
        mismatches.append((package, installed, required))

if mismatches:
    print("ERROR: pinned ComfyUI dependencies are out of sync:", file=sys.stderr)
    for package, installed, required in mismatches:
        print(f"       {package}: installed {installed}, required {required}", file=sys.stderr)
    raise SystemExit(1)
PY
then
	echo "       Repair with: $COMFY_PYTHON -m pip install -r $PWD/requirements.txt"
	exit 1
fi

exec "$COMFY_PYTHON" main.py "$@"
