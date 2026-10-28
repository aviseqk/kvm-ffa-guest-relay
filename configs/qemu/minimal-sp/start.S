.section .text
.globl _start
.type _start, %function

_start:
	ldr x0, =__stack_top
    	mov sp, x0

	bl sp_main
1:
	wfi
	b 1b
