#!/usr/bin/env sh

curl -X GET https://api.github.com/repos/chipsalliance/firrtl-spec/contributors | \
  jq '.[].login' | \
  sort -u | \
  sed 's/"\(.*\)"/- [`@\1`](https:\/\/github.com\/\1)/'
