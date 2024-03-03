#!/usr/bin/env bash

set -eo pipefail

usage() {
  cat <<EOF
USAGE: $0 [options]

Download JSON representing the first 100 contributors to the firrtl-spec
repository.

OPTIONS:
    -g                    An optional GitHub token to authenticate with
    -h                    Display available options
EOF
}

OPT_GITHUB_TOKEN=
while getopts "g:h" option; do
  case $option in
    g)
      OPT_GITHUB_TOKEN=$OPTARG
      ;;
    h)
      usage
      exit 0
  esac
done

CURL_ARGS=
if [[ $OPT_GITHUB_TOKEN ]]; then
  CURL_ARGS="-H \"Authorization: Bearer $OPT_GITHUB_TOKEN\""
fi

RESPONSE=$(eval curl $CURL_ARGS https://api.github.com/repos/chipsalliance/firrtl-spec/contributors?per_page=100)

echo $RESPONSE | \
  jq '.[] | {login, html_url} | select(.login | contains("chiselbot") | not)' | \
  jq -s 'sort_by(.login) | {contributors: .}'
