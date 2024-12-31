.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness in divider units

    # This test is NOT exhaustive, but will test division and remainder operations

_start:

    lui x1, 0x1eceb
    addi x1, x1, 0x00

    # Load and store using LW (Load Word) and SW (Store Word)
    lw x6, 0(x1)        # Load word from address 0 into x6

halt:
    slti x0, x0, -256  # Exit instruction (not a valid operation, just to stop execution)

