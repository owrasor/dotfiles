#!/usr/bin/env bash
set -euo pipefail

repo_root=$(realpath "$(dirname "$0")/..")
output=$(mktemp)
trap 'rm -f "$output"' EXIT

set +e
XDG_CONFIG_HOME="$(dirname "$repo_root")" \
	nvim --headless \
		"+e $repo_root/tests/fixtures/markdown-render-repro.md" \
		+"sleep 500m" \
		+q >"$output" 2>&1
status=$?
set -e

if [ "$status" -ne 0 ] || rg -q "attempt to call method 'range'|Error in command line|Error detected while processing|vim.schedule callback" "$output"; then
	cat "$output"
	exit 1
fi
