#!/usr/bin/env bash

diff $1 <(pandoc --wrap=preserve -t markdown+pipe_tables-multiline_tables-grid_tables $1) | \
  patch $1 -
