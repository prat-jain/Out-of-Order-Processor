// This class generates random valid RISC-V instructions to test your
// RISC-V cores.

class RandInst;
    // You will increment this number as you generate more random instruction
    // types. Once finished, NUM_TYPES should be 9, for each opcode type in
    // rv32i_opcode.
    localparam NUM_TYPES = 10;

    // Note that the `instr_t` type is from ../pkg/types.sv, there are TODOs
    // you must complete there to fully define `instr_t`.
    rand instr_t instr;
    rand bit [NUM_TYPES-1:0] instr_type;

    // Make sure we have an even distribution of instruction types.
    constraint solve_order_c { solve instr_type before instr; }

    // Hint/TODO: you will need another solve_order constraint for funct3
    // to get 100% coverage with 500 calls to .randomize().

    rand logic[2:0] funct3_val;

    constraint solve_order_funct3_c { solve funct3_val before instr; }

    // Pick one of the instruction types.
    constraint instr_type_c {
        $countones(instr_type) == 1; // Ensures one-hot.
    }

    

    // Constraints for actually generating instructions, given the type.
    // Again, see the instruction set listings to see the valid set of
    // instructions, and constrain to meet it. Refer to ../pkg/types.sv
    // to see the typedef enums.
   

    constraint instr_c {
        // Reg-imm instructions
        instr_type[0] -> {
            instr.i_type.opcode == op_b_imm;

            // Implies syntax: if funct3 is arith_f3_sr, then funct7 must be
            // one of two possibilities.

            instr.i_type.funct3 == funct3_val;

            instr.i_type.funct3 == arith_f3_sr -> {
                // Use r_type here to be able to constrain funct7.
                instr.r_type.funct7 inside {base, variant};
            }

            // This if syntax is equivalent to the implies syntax above
            // but also supports an else { ... } clause.
            if (instr.i_type.funct3 == arith_f3_sll) {
                instr.r_type.funct7 == base;
            }
        }

        // Reg-reg instuctions
        instr_type[1] -> {
            // TODO: Fill this out!
            instr.r_type.opcode == op_b_reg;

            instr.r_type.funct3 == funct3_val;

            instr.r_type.funct3 == arith_f3_add -> {
                instr.r_type.funct7 inside {base, variant};
            }

            instr.r_type.funct3 == arith_f3_sll -> {
                instr.r_type.funct7 inside {base};
            }

            instr.r_type.funct3 == arith_f3_slt -> {
                instr.r_type.funct7 inside {base};
            }

            instr.r_type.funct3 == arith_f3_sltu -> {
                instr.r_type.funct7 inside {base};
            }

            instr.r_type.funct3 == arith_f3_xor -> {
                instr.r_type.funct7 inside {base};
            }

            instr.r_type.funct3 == arith_f3_sr -> {
                instr.r_type.funct7 inside {base, variant};
            }

            instr.r_type.funct3 == arith_f3_or -> {
                instr.r_type.funct7 inside {base};
            }

            instr.r_type.funct3 == arith_f3_and -> {
                instr.r_type.funct7 inside {base};
            }

        }

        // Store instructions -- these are easy to constrain!
        instr_type[2] -> {
            instr.s_type.opcode == op_b_store;
            instr.s_type.funct3 inside {store_f3_sb, store_f3_sh, store_f3_sw};
            instr.r_type.rs1 == 0;
            instr.s_type.imm_s_bot[1:0] == 0;
        }

        // Load instructions
        instr_type[3] -> {
            instr.i_type.opcode == op_b_load;
            instr.i_type.funct3 inside {load_f3_lb, load_f3_lbu, load_f3_lh, load_f3_lhu, load_f3_lw};
            instr.r_type.rs1 == 0;
            instr.i_type.i_imm[1:0] == 0;
        // TODO: Constrain funct3 as well.
        }

        // // TODO: Do all 9 types!
        // instr_type[4] -> {
        //     instr.b_type.opcode == op_b_br;
        //     instr.b_type.funct3 inside {branch_f3_beq, branch_f3_bne, branch_f3_blt, branch_f3_bge, branch_f3_bltu, branch_f3_bgeu};
        // }


        instr_type[4] -> {
            instr.i_type.opcode == op_b_lui;
        }

        instr_type[5] -> {
            instr.r_type.funct7 == 7'd1;
            instr.r_type.opcode == op_b_reg;
            instr.i_type.funct3 == funct3_val;
            instr.r_type.funct3[2] == 1'b0;
  
   
        }

        instr_type[6] -> {
            instr.r_type.funct7 == 7'd1;
            instr.r_type.opcode == op_b_reg;
            instr.r_type.funct3 == funct3_val;
            instr.r_type.funct3[2] == 1'b1;

        }

        instr_type[7] -> {
            instr.i_type.opcode == op_b_auipc;
        }


        instr_type[8] -> {
            instr.i_type.opcode == op_b_jalr;
            instr.i_type.funct3 inside {3'b000}; //only valid funct3 val for this instr
        }

        instr_type[9] -> {
            instr.i_type.opcode == op_b_jal;
        }
        
    }

    `include "../../hvl/vcs/instr_cg.svh"

    // Constructor, make sure we construct the covergroup.
    function new();
        instr_cg = new();
    endfunction : new

    // Whenever randomize() is called, sample the covergroup. This assumes
    // that every time you generate a random instruction, you send it into
    // the CPU.
    function void post_randomize();
        instr_cg.sample(this.instr);
    endfunction : post_randomize

    // A nice part of writing constraints is that we get constraint checking
    // for free -- this function will check if a bit vector is a valid RISC-V
    // instruction (assuming you have written all the relevant constraints).
    function bit verify_valid_instr(instr_t inp);
        bit valid = 1'b0;
        this.instr = inp;
        for (int i = 0; i < NUM_TYPES; ++i) begin
            this.instr_type = 1 << i;
            if (this.randomize(null)) begin
                valid = 1'b1;
                break;
            end
        end
        return valid;
    endfunction : verify_valid_instr

endclass : RandInst