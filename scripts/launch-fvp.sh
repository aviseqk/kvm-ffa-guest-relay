#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FVP="FVP_Base_RevC-2xAEMvA"

BL1="$ROOT/out/tf-a/fvp/debug/bl1.bin" 
FIP="$ROOT/out/tf-a/fvp/debug/fip.bin" 

LOG_DIR="$ROOT/out/logs/fvp"
mkdir -p $LOG_DIR

FVP_TERMINAL_CONFIG=(
    -C 'bp.terminal_0.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_1.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_2.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_3.terminal_command=kitty --title "%title" telnet localhost %port'
)

"$FVP" \
	-C bp.secure_memory=false \
	-C pctl.startup=0.0.0.0 \
	-C cache_state_modelled=0 \
	-C bp.ve_sysregs.mmbSiteDefault=0 \
	-C bp.ve_sysregs.exit_on_shutdown=1 \
	-C bp.pl011_uart0.untimed_fifos=1 \
	-C bp.pl011_uart0.unbuffered_output=1 \
	-C bp.pl011_uart0.out_file="$LOG_DIR/uart0.log" \
	-C bp.pl011_uart1.untimed_fifos=1 \
	-C bp.pl011_uart1.unbuffered_output=1 \
	-C bp.pl011_uart1.out_file="$LOG_DIR/uart1.log" \
	-C bp.secureflashloader.fname="$BL1" \
	-C bp.flashloader0.fname="$FIP" \
	"${FVP_TERMINAL_CONFIG[@]}"
