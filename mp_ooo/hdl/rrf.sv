module rrf
import rv32i_types::*;
import params::*;
(
    input   logic           clk,
    input   logic           rst,

    // input   logic                   rat_we,
    // input   logic   [PR_WIDTH-1:0]  pd,
    // input   logic   [AR_WIDTH-1:0]  rs1, rs2, rd,
    // output  logic   [PR_WIDTH-1:0]  ps1, ps2,
    // output  logic                   ps1_valid, ps2_valid,

    // input   logic   [PR_WIDTH-1:0]  cdb_pd,
    // input   logic   [AR_WIDTH-1:0]  cdb_rd,
    // input   logic                   cdb_regf_we

    //connections to rob
    input   logic               valid_front,
    input  rob_entry_t         rob_rdata,
    output   logic               rob_dequeue,   
    input   logic               rob_empty,

    //connections to free list
    output   logic [FREE_LIST_WIDTH-1:0]  free_list_wdata,
    output   logic                       free_list_enqueue,

    output logic        rvfi_valid,
    output logic [63:0] rvfi_order,
    output logic [31:0] rvfi_inst,
    output logic [4:0]  rvfi_rs1_addr,
    output logic [4:0]  rvfi_rs2_addr,
    output logic [31:0] rvfi_rs1_rdata,
    output logic [31:0] rvfi_rs2_rdata,
    output logic [4:0]  rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    output logic [31:0] rvfi_pc_rdata,
    output logic [31:0] rvfi_pc_wdata,
    output logic [31:0] rvfi_mem_addr,
    output logic [31:0] rvfi_mem_rdata,
    output logic [31:0] rvfi_mem_wdata,
    output logic [3:0]  rvfi_mem_rmask,
    output logic [3:0]  rvfi_mem_wmask,


    //connections to regfile (reading)
    output  logic   [PR_WIDTH-1:0]  commit_ps1,
    output  logic   [PR_WIDTH-1:0]  commit_ps2,
    output  logic   [PR_WIDTH-1:0]  commit_pd,

    input   logic   [31:0]          commit_ps1_v,
    input   logic   [31:0]          commit_ps2_v,
    input   logic   [31:0]          commit_pd_v,

    //connection from rob for memory signals
    input   rvfi_mem_signals_t      mem_rvfi_output,

    //connection to rat
    output  logic [PR_WIDTH-1:0]  rrf_rdata[32],

    output          flush,
    output  [31:0]  updated_pc,
    output  [63:0]  updated_order,

    output   logic   [$clog2(PHT_DEPTH)-1:0]  write_idx,
    output   logic   [$clog2(LHT_DEPTH)-1:0]  gshare_write_idx,
    output   logic                           branch_we,
    output   logic                           branch_taken,
    output   bp_state_t                      bp_prev_state,
    output   logic  [$clog2(LHT_DEPTH)-1:0]  prev_pattern,

    // input   logic   [$clog2(LHT_DEPTH)-1:0] ghr,

    // connections to tournament
    output  logic                   misprediction,
    output  logic                   predictor_used

);

    logic   [PR_WIDTH-1:0]  phys_reg_map [32];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                phys_reg_map[i] <= unsigned'(6'(i));
            end 
        end else begin 
            if (valid_front && (rob_rdata.rd != '0)) phys_reg_map[rob_rdata.rd] <= rob_rdata.pd;
        end
    end

    always_comb begin 
        if (valid_front) begin 
            rob_dequeue = 1'b1;
            free_list_enqueue = (rob_rdata.rd == '0) ? 1'b0 : 1'b1;
            free_list_wdata = phys_reg_map[rob_rdata.rd];
        end else begin 
            rob_dequeue = 1'b0;
            free_list_enqueue = 1'b0;
            free_list_wdata = 'x;
        end
    end

    always_comb begin 

        //rrf copy for rat
        rrf_rdata = phys_reg_map;
        if (valid_front) begin 
            rrf_rdata[rob_rdata.rd] = rob_rdata.pd;
        end

        //rvfi connections
        commit_ps1 = rob_rdata.ps1;
        commit_ps2 = rob_rdata.ps2;
        commit_pd = rob_rdata.pd;
        
        rvfi_valid = rob_rdata.commit;
        rvfi_order = rob_rdata.order; 
        rvfi_inst  = rob_rdata.inst; 
        rvfi_rs1_addr = rob_rdata.rs1; 
        rvfi_rs2_addr = rob_rdata.rs2; 
        rvfi_rs1_rdata = commit_ps1_v;
        rvfi_rs2_rdata = commit_ps2_v;
        rvfi_rd_addr = rob_rdata.rd;
        rvfi_rd_wdata = commit_pd_v;
        rvfi_pc_rdata = rob_rdata.pc; 
        rvfi_pc_wdata = rob_rdata.pc_next; 

        rvfi_mem_addr = mem_rvfi_output.addr;
        rvfi_mem_rdata = mem_rvfi_output.rdata;
        rvfi_mem_wdata = mem_rvfi_output.wdata;
        rvfi_mem_rmask = mem_rvfi_output.rmask;
        rvfi_mem_wmask = mem_rvfi_output.wmask;
    end

    
    assign flush = rob_rdata.commit && rob_rdata.flush && ~rob_empty;   

    // assign rrf_rdata = phys_reg_map; 

    assign updated_pc = rob_rdata.pc_next;

    assign updated_order = rob_rdata.order;

    assign write_idx = rob_rdata.pc[$clog2(PHT_DEPTH)-1:0];

    assign gshare_write_idx = rob_rdata.pc[$clog2(LHT_DEPTH)-1:0] ^ rob_rdata.ghr_val;
    
    assign bp_prev_state = rob_rdata.bp_prev_state;

    // assign prev_pattern = rob_rdata.prev_pattern;

    assign predictor_used = rob_rdata.predictor_used;

    assign prev_pattern = rob_rdata.prev_pattern;

    assign misprediction = rob_rdata.flush;

    assign branch_taken = rob_rdata.branch_taken;

    assign branch_we = (rob_rdata.inst[6:0] == op_b_br);


endmodule : rrf
