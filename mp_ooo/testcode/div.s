.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness in divider units

    # This test is NOT exhaustive, but will test division and remainder operations

_start:

# initialize
li x1, 100       # x1 = 100 (numerator for signed division)
li x2, -25       # x2 = -25 (denominator for signed division)
div x3, x1, x2   # x3 = x1 / x2 = 100 / -25 = -4 (signed division result)
rem x4, x1, x2   # x4 = x1 % x2 = 100 % -25 = 0 (signed remainder result)

li x5, 50        # x5 = 50 (numerator for unsigned division)
li x6, 10        # x6 = 10 (denominator for unsigned division)
divu x7, x5, x6  # x7 = x5 / x6 = 50 / 10 = 5 (unsigned division result)
remu x8, x5, x6  # x8 = x5 % x6 = 50 % 10 = 0 (unsigned remainder result)

# additional signed divisions for testing
li x9, -200      # x9 = -200
li x10, 25       # x10 = 25
div x11, x9, x10 # x11 = -200 / 25 = -8 (signed division result)
rem x12, x9, x10 # x12 = -200 % 25 = -200 - (-8 * 25) = 0 (signed remainder)

# additional unsigned divisions for testing
li x13, 50       # x13 = 50
li x14, 15       # x14 = 15
divu x15, x13, x14 # x15 = 50 / 15 = 3 (unsigned division)
remu x16, x13, x14 # x16 = 50 % 15 = 5 (unsigned remainder)

nop
nop
nop
nop
nop
nop

# these instructions should resolve before the divide
add x17, x5, x6   # x17 = x5 + x6 = 50 + 10 = 60
xor x18, x7, x8   # x18 = x7 ^ x8 = 5 ^ 0 = 5
sll x19, x9, x10  # x19 = x9 << x10 = -200 << 25
and x20, x13, x14 # x20 = x13 & x14 = 50 & 15 = 14

# Testing multiple division instructions together
div x21, x15, x16 # x21 = 3 / 5 = 0 (unsigned division)
rem x22, x15, x16 # x22 = 3 % 5 = 3 (unsigned remainder)

# these instructions should resolve before the divide
add x23, x18, x19 # x23 = x18 + x19
xor x24, x20, x23 # x24 = x20 ^ x23
sll x25, x20, x23 # x25 = x20 << x23
and x26, x20, x25 # x26 = x20 & x25

halt:
    slti x0, x0, -256  # Exit instruction (not a valid operation, just to stop execution)

