#!/usr/bin/env bash

diff $1 <(pandoc --wrap=preserve -t markdown+pipe_tables-grid_tables-multiline_tables-simple_tables --columns=1024 $1) | \
  patch $1 -
