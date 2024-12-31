

package rv32i_types;

    localparam PR_WIDTH = 6; //64 regs
    localparam AR_WIDTH = 5; //32 regs

    localparam IQUEUE_WIDTH = 66; //64 + 2 bp state bits
    localparam IQUEUE_DEPTH = 16;

    localparam FREE_LIST_WIDTH = PR_WIDTH;
    localparam FREE_LIST_DEPTH = 32;

    localparam ROB_QUEUE_WIDTH = 194;
    localparam ROB_QUEUE_DEPTH = 16;

    localparam RAT_PR_WIDTH = PR_WIDTH + 1; // commit bit
    localparam RAT_AR_WIDTH = AR_WIDTH;

    localparam ALU_RS_COUNT = 4;
    localparam MUL_RS_COUNT = 2;
    localparam DIV_RS_COUNT = 2; 

    localparam LHT_DEPTH = 16; 
    localparam PHT_DEPTH = 32;
    localparam GHR_SIZE = 4;

    localparam BTB_DEPTH = 32;
    

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;
    
    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000
    } funct7_t;

    typedef enum logic [1:0] {
        snt = 2'b00,
        wnt = 2'b01,
        wt  = 2'b10,
        st  = 2'b11
    } bp_state_t;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        struct packed {
            logic [12:12] imm_b_1;
            logic [10:5] imm_b_2;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:1]  imm_b_3;
            logic [11:11] imm_b_4;
            rv32i_opcode opcode;
        } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t; 


    typedef enum logic [2:0] {
        idle = '0,
        burst_one = 3'b001,
        burst_two = 3'b010,
        burst_three = 3'b011,
        burst_four = 3'b100,
        respond = 3'b101
    } adapter_state;

    typedef struct packed {
        logic   [31:0]  addr;
        logic   [3:0]   rmask;
        logic   [3:0]   wmask;
        logic   [31:0]  wdata;
    } s1_s2_stage_reg_t;

    typedef struct packed {
        logic   [31:0]  pc;
        logic   [31:0]  inst;
        bp_state_t   bp_curr_state;
        logic   [$clog2(LHT_DEPTH)-1:0] br_pattern;
        bp_state_t   gshare_bp_curr_state;
        logic   [$clog2(LHT_DEPTH)-1:0] ghr_val;
        logic   tournament_output;
        logic   [31:0] btb_pc_next;
    } iq_struct_t;

    typedef struct packed {
        logic                                commit;
        logic   [AR_WIDTH-1:0]                   rd;
        logic   [PR_WIDTH-1:0]                   pd;
        logic   [AR_WIDTH-1:0]                  rs1; 
        logic   [AR_WIDTH-1:0]                  rs2; 
        logic   [PR_WIDTH-1:0]                  ps1;
        logic   [PR_WIDTH-1:0]                  ps2;
        logic   [31:0]                         inst;
        logic   [31:0]                           pc;
        logic   [31:0]                      pc_next;
        logic   [63:0]                        order;
        logic                                 flush; 
        bp_state_t                          bp_prev_state;
        logic  [$clog2(LHT_DEPTH)-1:0]      prev_pattern;
        logic                               predictor_used;
        logic                               branch_taken;
        logic  [$clog2(LHT_DEPTH)-1:0]      ghr_val;

    } rob_entry_t;
    

    typedef struct packed {
        logic                                   ps1_valid;
        logic                                   ps2_valid;
        logic   [PR_WIDTH-1:0]                  ps1;
        logic   [PR_WIDTH-1:0]                  ps2;
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [AR_WIDTH-1:0]                  rd; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;

        // logic   [AR_WIDTH-1:0]                  rs1; 
        // logic   [AR_WIDTH-1:0]                  rs2; 
    
        logic   [31:0]                          pc;
        logic                                   br_en;
    
        
        logic   [6:0]                           op_code;
        logic   [31:0]                          imm;
        logic   [2:0]                           funct3;   
        logic   [6:0]                           funct7; 

        bp_state_t                              bp_curr_state;
        logic   [$clog2(LHT_DEPTH)-1:0]         br_pattern;  
        logic                                   predictor_used;
        logic   [$clog2(LHT_DEPTH)-1:0] ghr_val;
        logic   [31:0]                  btb_pc_next;

        
        logic                                   data_available; 
        logic       [31:0]                      load_data; 
        
    } res_station_struct_t;

    typedef struct packed {
        logic                                   busy;
        
        logic                                   ps1_valid;
        logic                                   ps2_valid;
        logic   [PR_WIDTH-1:0]                  ps1;
        logic   [PR_WIDTH-1:0]                  ps2;
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [AR_WIDTH-1:0]                  rd; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;

        // logic   [AR_WIDTH-1:0]                  rs1; 
        // logic   [AR_WIDTH-1:0]                  rs2; 
    
        logic   [31:0]                          pc;
        logic                                   br_en;


        logic   [6:0]                           op_code;
        logic   [31:0]                          imm;
        logic   [2:0]                           funct3;   
        logic   [6:0]                           funct7;   

        bp_state_t                           bp_curr_state;
        logic   [$clog2(LHT_DEPTH)-1:0]         br_pattern;  
        logic                                   predictor_used;
        logic   [$clog2(LHT_DEPTH)-1:0] ghr_val;
        logic   [31:0]                  btb_pc_next;




        logic       [31:0]                      age; 

    } res_station_entry_t;

    typedef struct packed {
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [31:0]                          pv; 
        logic   [AR_WIDTH-1:0]                  rd; 
        logic                                   regf_we; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;
        logic   [31:0]                          pc;
        logic                                   update_pc_next;
        logic   [31:0]                          pc_next;
        // logic   [31:0]                          pc_next;

        // logic   [AR_WIDTH-1:0]                  rs1; 
        // logic   [AR_WIDTH-1:0]                  rs2; 
        // logic   [PR_WIDTH-1:0]                  ps1;
        // logic   [PR_WIDTH-1:0]                  ps2; 
        logic                                   branch_taken;
    } execution_out_t;

    typedef struct packed {
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [31:0]                          pv; 
        logic   [AR_WIDTH-1:0]                  rd; 
        logic                                   regf_we; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;
        logic   [31:0]                          pc;
        logic                                   update_pc_next;
        logic   [31:0]                          pc_next;

        logic                                   branch_taken;

        // need just for RVFI
        // logic   [AR_WIDTH-1:0]                  rs1; 
        // logic   [AR_WIDTH-1:0]                  rs2; 
        // logic   [PR_WIDTH-1:0]                  ps1;
        // logic   [PR_WIDTH-1:0]                  ps2;

        // logic  wb_valid; 
        // logic                                   load; //1 if load
    } CDB_t;

    typedef struct packed {
        logic                                   ps1_valid;
        logic                                   ps2_valid;
        logic   [PR_WIDTH-1:0]                  ps1;
        logic   [PR_WIDTH-1:0]                  ps2;
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [AR_WIDTH-1:0]                  rd; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;

    
        logic   [31:0]                          pc;
        logic                                   br_en;
        
        logic   [6:0]                           op_code;
        logic   [31:0]                          imm;
        logic   [2:0]                           funct3;   
        logic   [6:0]                           funct7; 

        bp_state_t                           bp_curr_state;  
        logic   [$clog2(LHT_DEPTH)-1:0]         br_pattern;  
        logic                                   predictor_used;
        logic   [$clog2(LHT_DEPTH)-1:0] ghr_val;
        logic   [31:0]                  btb_pc_next;




        logic                                   data_available; 
        logic       [31:0]                      load_data; 
        
    } ls_queue_entry_t; //need to remove stuff we dont need

    typedef struct packed {
        logic                                   ps1_valid;
        logic                                   ps2_valid;
        logic   [PR_WIDTH-1:0]                  ps1;
        logic   [PR_WIDTH-1:0]                  ps2;
        logic   [PR_WIDTH-1:0]                  pd;
        logic   [AR_WIDTH-1:0]                  rd; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;

    
        logic   [31:0]                          pc;
        logic                                   br_en;
        
        logic   [6:0]                           op_code;
        logic   [31:0]                          imm;
        logic   [2:0]                           funct3;   
        logic   [6:0]                           funct7;   
        logic                                   valid;
        
    } ls_queue_entry_t_2;


    typedef struct packed {
        logic   [31:0]  addr2;
        logic   [31:0]  addr;
        logic   [31:0]  rdata;
        logic   [31:0]  wdata;
        logic   [3:0]   rmask;
        logic   [3:0]   wmask;
        logic   [2:0]                           funct3; 

        logic   [PR_WIDTH-1:0]                  pd;
        logic   [31:0]                          pv; 
        logic   [AR_WIDTH-1:0]                  rd; 
        logic                                   regf_we; 
        logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_entry;
        logic   [31:0]                          pc;
        logic                                   update_pc_next;
        logic   [31:0]                          pc_next;

        logic                                   data_available; 
        logic       [31:0]                      load_data; 
    } split_lsq_t;


    typedef struct packed {
        logic   [31:0]  addr;
        logic   [31:0]  rdata;
        logic   [31:0]  wdata;
        logic   [3:0]   rmask;
        logic   [3:0]   wmask;
    } rvfi_mem_signals_t;


endpackage


package params;



endpackage