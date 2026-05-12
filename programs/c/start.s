# Minimal startup code for RV32I processor
# Sets up the stack pointer and jumps to main.

.section .text.init
.global _start

_start:
    la   sp, __stack_top    # set stack pointer to top of DMEM
    call main               # jump to C entry point

halt:
    j    halt               # infinite loop after main returns
