#!/usr/bin/env bash

set -eo pipefail

usage() {
  cat <<EOF
USAGE:
    $0 -i FILE [-g TOKEN]
    $0 -h

Download JSON representing the first 100 contributors to the firrtl-spec
repository.

OPTIONS:
    -g TOKEN  An optional GitHub token to authenticate with
    -i FILE   Existing contributors JSON file to preserve (required)
    -h        Display available options
EOF
}

OPT_GITHUB_TOKEN=
OPT_INPUT_FILE=
while getopts "g:i:h" option; do
  case $option in
    g) OPT_GITHUB_TOKEN=$OPTARG ;;
    i) OPT_INPUT_FILE=$OPTARG ;;
    h) usage; exit 0 ;;
  esac
done

if [[ -z "$OPT_INPUT_FILE" ]]; then
  echo "Error: an input file must be specified with -i" >&2
  exit 1
fi

CURL_ARGS=(-fsSL)
if [[ -n "$OPT_GITHUB_TOKEN" ]]; then
  CURL_ARGS+=(-H "Authorization: Bearer $OPT_GITHUB_TOKEN")
fi

curl "${CURL_ARGS[@]}" \
  'https://api.github.com/repos/chipsalliance/firrtl-spec/contributors?per_page=100' |
  jq --slurpfile old "$OPT_INPUT_FILE" '
    {
      contributors:
        ([$old[0].contributors[], .[]]
         | map(
             select((.login? | type) == "string")
             | {login, html_url}
             | select(.login | ascii_downcase | contains("chiselbot") | not)
           )
         | map({key: (.login | ascii_downcase), value: .})
         | from_entries
         | [.[]]
         | sort_by(.login))
    }
  '
