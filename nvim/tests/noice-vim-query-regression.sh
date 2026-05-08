#!/usr/bin/env bash
set -euo pipefail

repo_root=$(realpath "$(dirname "$0")/..")
config="$repo_root/lua/plugins/noice.lua"

if ! rg -q 'cmdline = \{ pattern = "", icon = ".*", lang = "vim" \}' "$config"; then
	printf 'noice cmdline deixou de usar lang = "vim" mesmo com a query global corrigida\n' >&2
	exit 1
fi

output=$(mktemp)
trap 'rm -f "$output"' EXIT

set +e
XDG_CONFIG_HOME="$(dirname "$repo_root")" \
	nvim --headless \
		'+lua local ok, err = pcall(vim.treesitter.query.get, "vim", "highlights"); if not ok then error(err) end' \
		+q >"$output" 2>&1
status=$?
set -e

if [ "$status" -ne 0 ] || rg -q "Query error|Invalid node type|E5108" "$output"; then
	cat "$output"
	exit 1
fi
