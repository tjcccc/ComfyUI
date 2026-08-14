#!/bin/sh
# Run from the repo dir regardless of where this was invoked from.
cd "$(dirname "$0")" || exit 1

# Refuse to run outside comfyenv. Without the env active, `python3` resolves to
# python.org 3.14, which does not contain the ComfyUI dependencies.
case "$(python3 -c 'import sys; print(sys.prefix)' 2>/dev/null)" in
	*/envs/comfyenv) ;;
	*)
		echo "ERROR: comfyenv is not active (python3 -> $(command -v python3))."
		echo "       Run: conda activate comfyenv"
		exit 1
		;;
esac

exec python3 main.py "$@"
