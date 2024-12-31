import re
import argparse


OP_B_JAL        = int('1101111', 2) # jump and link (J type)
OP_B_JALR       = int('1100111', 2) # jump and link register (I type)
OP_B_BR         = int('1100011', 2) # branch (B type)
OP_B_LUI        = int('0110111', 2) # load upper immediate (U type)
OP_B_REG        = int('0110011', 2) # arith ops with register operands (R type)
OP_B_STORE      = int('0100011', 2) # store (S type)
OP_B_AUIPC      = int('0010111', 2) # add upper immediate PC (U type)
OP_B_IMM        = int('0010011', 2) # arith ops with register/immediate operands (I type)
OP_B_LOAD       = int('0000011', 2) # load (I type)


def main(log_file):
    
    start_pc = None

    total_inst_count = 0

    op_b_jal_count      = 0 # jump and link (J type)
    op_b_jalr_count     = 0 # jump and link register (I type)
    op_b_br_count       = 0 # branch (B type)
    op_b_lui_count      = 0 # load upper immediate (U type)
    op_b_reg_count      = 0 # arith ops with register operands (R type)
    op_b_store_count    = 0 # store (S type)
    op_b_auipc_count    = 0 # add upper immediate PC (U type)
    op_b_imm_count      = 0 # arith ops with register/immediate operands (I type)
    op_b_load_count     = 0 # load (I type)

    check_branch = False
    branch_instr_pc = None
    branches_taken = 0
    branches_not_taken = 0

    prev_load_store = None
    prev_ls_pc = None
    ls_distances = []
    curr_load_store = False

    with open(log_file, 'r') as f:
        
        for line in f:
            if line.startswith('core   0: ') == False:
                raise Exception('unexpected line. doesn\'t start with \'core   0: \'')
            
            line_parts = line.strip('core   0: ')

            line_parts = line_parts.strip('\n')
            
            line_parts = line_parts.split(' ')

            pc = line_parts[1]
            pc = int(pc, 16)

            if not start_pc:
                start_pc = pc

            instruction = line_parts[2].strip('(').strip(')')
            instruction = int(instruction, 16)

            total_inst_count += 1

            if check_branch == True:
                # print(f'branch {pc} {branch_instr_pc}')
                if branch_instr_pc + 4 == pc:
                    branches_not_taken += 1
                else:
                    branches_taken += 1
                check_branch = False

            curr_load_store = None

            if instruction & OP_B_JAL   == OP_B_JAL:
                op_b_jal_count += 1
            elif instruction & OP_B_JALR  == OP_B_JALR:
                op_b_jalr_count += 1
                # prev_load_store = None
                # prev_ls_pc = None
            elif instruction & OP_B_BR    == OP_B_BR:
                op_b_br_count += 1
                check_branch = True
                branch_instr_pc = pc
                # prev_load_store = None
                # prev_ls_pc = None
            elif instruction & OP_B_LUI   == OP_B_LUI:
                op_b_lui_count += 1
            elif instruction & OP_B_REG   == OP_B_REG:
                op_b_reg_count += 1
            elif instruction & OP_B_STORE == OP_B_STORE:
                op_b_store_count += 1
                curr_load_store = OP_B_STORE
            elif instruction & OP_B_AUIPC == OP_B_AUIPC:
                op_b_auipc_count += 1
            elif instruction & OP_B_IMM   == OP_B_IMM:
                op_b_imm_count += 1
            elif instruction & OP_B_LOAD  == OP_B_LOAD:
                op_b_load_count += 1
                curr_load_store = OP_B_LOAD
            else:
                raise Exception('unknown exception')
            
            if curr_load_store:
                if prev_load_store and prev_ls_pc:
                    if prev_load_store == OP_B_LOAD and curr_load_store == OP_B_LOAD:
                        pass
                    else:
                        ls_distances.append((abs(pc-prev_ls_pc))/4)

                prev_load_store = curr_load_store
                prev_ls_pc = pc

    
    total_op_inst_count = op_b_jal_count + op_b_jalr_count + op_b_br_count + op_b_lui_count + op_b_reg_count + op_b_store_count + op_b_auipc_count + op_b_imm_count + op_b_load_count

    if total_inst_count != total_op_inst_count:
        raise Exception('instruction total mismatch')
    

    data = [
        ['', 'Freq', 'Freq (%)'],
        ['OP_B_JAL',  op_b_jal_count  , ((op_b_jal_count  /total_inst_count)*100)],
        ['OP_B_JALR', op_b_jalr_count , ((op_b_jalr_count /total_inst_count)*100)],
        ['OP_B_BR',   op_b_br_count   , ((op_b_br_count   /total_inst_count)*100)],
        ['OP_B_LUI',  op_b_lui_count  , ((op_b_lui_count  /total_inst_count)*100)],
        ['OP_B_REG',  op_b_reg_count  , ((op_b_reg_count  /total_inst_count)*100)],
        ['OP_B_STORE',op_b_store_count, ((op_b_store_count/total_inst_count)*100)],
        ['OP_B_AUIPC',op_b_auipc_count, ((op_b_auipc_count/total_inst_count)*100)],
        ['OP_B_IMM',  op_b_imm_count  , ((op_b_imm_count  /total_inst_count)*100)],
        ['OP_B_LOAD', op_b_load_count , ((op_b_load_count /total_inst_count)*100)],
        ['', '', ''],
        ['Total', total_inst_count, '']
            ]

    print('Types of Instructions')
    print("{:<15} {:<10} {:<10}".format(*data[0]))
    for row in data[1:10]:
        print("{:<15} {:<10} {:.2f}".format(*row))
    print("{:<15} {:<10} {:<10}".format(*data[10]))
    print("{:<15} {:<10} {:<10}".format(*data[11]))

    print('\n\n')

    if op_b_br_count != 0:
        if branches_taken + branches_not_taken != op_b_br_count:
            raise Exception('branches count mismatch')

        data = [
            ['', 'Freq', 'Freq (%)'],
            ['Taken', branches_taken, ((branches_taken/op_b_br_count)*100)],
            ['Not Taken', branches_not_taken, ((branches_not_taken/op_b_br_count)*100)],
            ['','',''],
            ['Total', op_b_br_count, '']
        ]


        print('Branches')
        print("{:<15} {:<10} {:<10}".format(*data[0]))
        for row in data[1:3]:
            print("{:<15} {:<10} {:.2f}".format(*row))
        print("{:<15} {:<10} {:<10}".format(*data[3]))
        print("{:<15} {:<10} {:<10}".format(*data[4]))
    else:
        print('No branch instructions found')

    print('\n\n')

    sum = 0
    for i in ls_distances:
        sum += i
    average_ls_distance = sum/len(ls_distances)
    print('Average distance between potentially dependent load/stores: {:.3f}'.format(average_ls_distance))


    return 0


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Benchmarking tool')
    parser.add_argument('-file', '-f', required=True, help='path to spike log')
    args = parser.parse_args()

    main(args.file)