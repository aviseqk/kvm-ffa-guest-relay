#!/usr/bin/env bash

set -euo pipefail

PORT="$1"
PANE="$TMUX_PANE"

tmux split-window \
    -t "$PANE" \
    "telnet localhost $PORT"

tmux select-layout -t "$PANE" tiled
