#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<EOF
Usage: $(basename "$0") [-h] FILE

Apply the terminology fixes to a Markdown file in place.

Options:
  -h  Show this help text.

Examples:
  $(basename "$0") README.md
EOF
}

while getopts ":h" option; do
  case "$option" in
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
  echo "Expected exactly one Markdown file." >&2
  usage >&2
  exit 2
fi

file=$1
echo "Fixing terminology in $file"
tmp=$(mktemp "${TMPDIR:-/tmp}/firrtl-spec-lint-fix.XXXXXX")
trap 'rm -f "$tmp"' EXIT
pandoc \
  --from=markdown+gfm_auto_identifiers+inline_code_attributes+table_captions+pipe_tables \
  --lua-filter="$script_dir/lint-terminology.lua" \
  --wrap=preserve \
  --to=markdown+pipe_tables-grid_tables-multiline_tables-simple_tables \
  --columns=1024 \
  --output="$tmp" \
  "$file"
cat "$tmp" >"$file"
