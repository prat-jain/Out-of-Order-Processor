.section .text
.global _start

_start:

    lui x1, 0x1eceb

    addi x1, x1, 0x00

    # Load and store using LW (Load Word) and SW (Store Word)
    lw x6, 0(x1)        # Load word from address 0 into x6
    lw x7, 4(x1)        # Load word from address 4 into x7

    sw x6, 16(x1)       # Store value in x6 to address 16
    sw x7, 20(x1)       # Store value in x7 to address 20

    # Load and store using LH (Load Half) and SH (Store Half)
    lh x8, 0(x1)        # Load halfword from address 0 into x8
    lh x9, 4(x1)        # Load halfword from address 4 into x9

    sh x8, 16(x1)       # Store halfword from x8 to address 16
    sh x9, 20(x1)       # Store halfword from x9 to address 20

    # Load and store using LB (Load Byte) and SB (Store Byte)
    lb x10, 0(x1)       # Load byte from addressrdata 0 into x10
    lb x12, 1(x1)       # Load byte from address 1 into x12


    sb x10, 16(x1)      # Store byte from x10 to address 16
    sb x12, 20(x1)      # Store byte from x12 to address 20
 

    # Load and store using LBU (Load Byte Unsigned) and LHU (Load Half Unsigned)
    lbu x13, 0(x1)      # Load unsigned byte from address 0 into x13
    lhu x14, 0(x1)      # Load unsigned halfword from address 0 into x14

    # jal temp1
    # Store unsigned half from x14 to address 24
    sh x14, 24(x1)      # Store halfword from x14 to address 24


     ##############################
    # Immediate Arithmetic Tests #
    ##############################

    li x2, 100                   # Load immediate into x2
    #                      # 4th NOP
    
    addi x3, x2, 10               # Add immediate to x2 (x3 = x2 + 10)
    #                      # 4th NOP
    
    xori x4, x3, -1               # XOR immediate (bitwise NOT operation)
                         # 4th NOP
    
    andi x5, x4, 0xFF             # AND immediate
                        # 4th NOP

    ###########################
    # Register Arithmetic Tests #
    ###########################

    add x6, x2, x3                # Add x2 and x3
                        # 4th NOP
    
    sub x7, x6, x2                # Subtract x2 from x6

    or x9, x8, x5                 # OR x8 and x5

    and x10, x9, x4               # AND x9 and x4
                          # 4th NOP

    ##############################
    # Shift Operations            #
    ##############################
    
    sll x11, x3, x2               # Shift left logical
                         # 4th NOP
    
    srl x12, x3, x2               # Shift right logical


temp1:
    xor x8, x6, x7                # XOR x6 and x7
#                          # 4th NOP
    

    sra x13, x3, x2               # Shift right arithmetic
#                       # 4th NOP

#     ################################
#     # Load/Store Tests              #
#     ################################

#     # Loading values from memory
    lw x14, 0(x1)                 # Load word from memory address in x1
#                         # 4th NOP
    lh x15, 0(x1)                 # Load halfword

    lb x16, 0(x1)                 # Load byte
    lb x17, 1(x1)                 # Load byte
    lb x18, 2(x1)                 # Load byte
    lb x19, 3(x1)                 # Load byte
    lh x20, 2(x1)                 # Load byte
    lh x21, 0(x1)                 # Load byte

    # Storing values in memory
    sw x2, 0(x1)                  # Store word in memory
#                         # 4th NOP
    
    sh x3, 4(x1)                  # Store halfword
# #                       # 4th NOP
    
    sb x4, 6(x1)                  # Store byte
                    #    4th NOP


    addi x1, x0, 4
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


    auipc x10, 0x2       # x10 = PC + (0x2 << 12) (x10 becomes the value of PC + 8192)


    slt x11, x3, x4      # x11 = (x3 < x4) ? 1 : 0 (x11 becomes 1 because 5 < 15)


    slti x12, x4, 10     # x12 = (x4 < 10) ? 1 : 0 (x12 becomes 0 because 15 is not < 10)


    sltu x13, x3, x6     # x13 = (unsigned(x3) < unsigned(x5)) ? 1 : 0 (x13 becomes 1 because 5 < 20)

    sltiu x14, x4, 16    # x14 = (unsigned(x4) < 16) ? 1 : 0 (x14 becomes 1 because 15 < 16)


    # End the simulation (this instruction will vary based on your simulator)
    slti x0, x0, -256 # this is the magic instruction to end the simulation
