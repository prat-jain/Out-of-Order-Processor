ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

# initialize
add x1, x1, 10
add x2, x1, 0
add x3, x4, 0
add x4, x3, 0
add x5, x6, 0

li x11,  2
li x12,  5

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2
# mul x3, x1, x2

# these instructions should  resolve before the multiply
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15

halt:
    slti x0, x0, -256
