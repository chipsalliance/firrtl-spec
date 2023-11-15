#!/usr/bin/env sh

curl -X GET https://api.github.com/repos/chipsalliance/firrtl-spec/contributors?per_page=100 | \
  jq '.[] | {login, html_url}' | \
  jq -s 'sort_by(.login) | {contributors: .}'
