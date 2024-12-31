ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

# initialize
li x1, 10
li x2, -2
mul x1, x1, x2
mul x2, x2, x2
li x5, -5
li x6, 6
li x8, -21
li x9, 28
li x11, 8
li x12, 4
li x14, 3
li x15, 1

nop
nop
nop
nop
nop
nop

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2
mul x3, x1, x2
mul x4, x2, x2
mulh x3, x3, x2
mulh x4, x2, x2
mulhsu x4, x5, x6
mulhu x4, x8, x6
mulhu x8, x9, x6

# these instructions should  resolve before the multiply
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15

halt:
    slti x0, x0, -256
