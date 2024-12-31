.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:
    addi x1, x0, 4
                 # s in between to prevent hazard
    
    
    
    
    addi x3, x1, 8
    xor x11, x11, x11
    
    
    
    
    

    add x10, x2, x3       # x1 = x2 + x3
    
    
    
    
    

    sub x4, x3, x1       # x4 = x5 - x6
    
    
    
    
    

    and x7, x8, x9       # x7 = x8 & x9
    
    
    
    
    

    or x10, x11, x12     # x10 = x11 | x12
    
    
    
    
    

    xor x13, x14, x15    # x13 = x14 ^ x15
    
    
    
    
    

    addi x16, x17, 10    # x16 = x17 + 10 (Immediate)
    
    
    
    
    

    andi x18, x19, 0xFF  # x18 = x19 & 0xFF (Immediate)
    
    
    
    
    

    ori x20, x21, 0xAB   # x20 = x21 | 0xAB (Immediate)
    
    
    
    
    

    xori x22, x23, 0x55  # x22 = x23 ^ 0x55 (Immediate)
    
    
    
    
    

    lui x9, 0x1          # x9 = 0x1 << 12 (x9 becomes 4096)
    
    

    slt x11, x3, x4      # x11 = (x3 < x4) ? 1 : 0 (x11 becomes 1 because 5 < 15)
    
    
    
    
    

   slti x12, x4, 10     # x12 = (x4 < 10) ? 1 : 0 (x12 becomes 0 because 15 is not < 10)
    
    
    
    
    

    sltu x13, x3, x6     # x13 = (unsigned(x3) < unsigned(x5)) ? 1 : 0 (x13 becomes 1 because 5 < 20)
    
    
    
    
    
    sltiu x14, x4, 16    # x14 = (unsigned(x4) < 16) ? 1 : 0 (x14 becomes 1 because 15 < 16)
    
    
    
    
    

    slti x0, x0, -256 # this is the magic instruction to end the simulation