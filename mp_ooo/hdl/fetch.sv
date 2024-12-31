
module fetch
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    input   logic               icache_ufp_resp,
    input   logic   [31:0]      icache_ufp_rdata,

    output  logic   [31:0]      icache_ufp_addr,
    output  logic               icache_ufp_read,  

    output  iq_struct_t         inst_q_wdata,
    output  logic               inst_q_enqueue,

    // input  logic   [IQUEUE_WIDTH-1:0] inst_q_rdata,
    // output logic               inst_q_dequeue,

    input  logic               inst_q_full,
    // input   logic   [$clog2(IQUEUE_DEPTH)-1:0]  inst_q_head, 
    // input  logic               inst_q_empty 
   
   input    logic                       flush,
   input    logic   [31:0]              updated_pc,

    // connections from decode
    input  logic    [31:0]     predicted_pc_next,
    input  logic               decode_pc_we,

    // connections to 2-level
    output  logic   [$clog2(PHT_DEPTH)-1:0]  read_idx,
    input   logic   [$clog2(LHT_DEPTH)-1:0] curr_pattern,
    input  bp_state_t                      bp_curr_state,

    // connections to execute
    input   logic                       branch_we,
    input   logic                       branch_taken,

    // connections to gshare
    output  logic   [$clog2(LHT_DEPTH)-1:0]  gshare_read_idx,
    input  bp_state_t                      gshare_bp_curr_state,

    //global history register
    output  logic   [$clog2(LHT_DEPTH)-1:0] ghr,

    input   logic   tournament_output

    // connections to btb
    // output  logic   [$clog2(BTB_DEPTH)-1:0] btb_read_idx,
    // input   logic   [31:0]                  btb_pc_next,
    // input   logic                           btb_valid_read


    
);


    logic   [31:0]  pc, pc_next, flush_counter, branch_counter;
    logic   flush_latch, branch_latch;
    logic   [31:0] updated_pc_latch, predicted_pc_latch, pc_next_val;
    logic          br_op;
    // logic   [$clog2(LHT_DEPTH)-1:0] ghr;

    always_ff @(posedge clk) begin 
        if (rst) begin 
            pc <= 32'h1eceb000;
            flush_latch <= 1'b0;
            branch_latch <= 1'b0;
            updated_pc_latch <= '0;
            br_op <= '0;
            ghr <= '0;
            flush_counter <= '0;
            branch_counter <= '0;
        end else begin 
            if (flush) begin 
            flush_latch <= 1'b1;
            flush_counter <= flush_counter + 32'd1;
            updated_pc_latch <= updated_pc;
            br_op <= '0;
            end else if (decode_pc_we) begin 
                branch_latch <= 1'b1;
                predicted_pc_latch <= predicted_pc_next;
                br_op <= '0;
            end else begin 
                if (flush_latch && icache_ufp_resp) flush_latch <= 1'b0;
                if (branch_latch && icache_ufp_resp) branch_latch <= 1'b0;
                if (~br_op && (icache_ufp_rdata[6:0] == op_b_br) && ~tournament_output) begin 
                    br_op <= 1'b1;
                    branch_counter <= branch_counter + 32'd1;
                end 
                if (br_op) br_op <= '0;
                pc <= pc_next;
            end

            if (branch_we) ghr <= {ghr[$clog2(LHT_DEPTH)-2:0], branch_taken};
        end 

        

    end

    always_comb begin

        pc_next = pc;
        icache_ufp_read = 1'b1;
        inst_q_enqueue = 1'b0;
        inst_q_wdata = '0;
        pc_next_val = pc;

            if (inst_q_full) begin 
                icache_ufp_read = '0;
            end else if (icache_ufp_resp) begin
                if (flush_latch) begin 
                    pc_next = updated_pc_latch;
                    inst_q_enqueue = 1'b0;
                    inst_q_wdata = '0;
                end else if (branch_latch) begin 
                    pc_next = predicted_pc_latch;
                    inst_q_enqueue = 1'b0;
                    inst_q_wdata = '0;
                end else begin 
                    if (!br_op || tournament_output) begin
                        pc_next = pc + 'd4;
                        inst_q_enqueue = 1'b1;
                        inst_q_wdata = iq_struct_t'({pc , icache_ufp_rdata, bp_curr_state, curr_pattern, gshare_bp_curr_state, ghr, tournament_output, pc_next_val});
                    // end else begin 
                    //     pc_next = pc;
                    //     icache_ufp_read = 1'b1;
                    //     inst_q_enqueue = 1'b0;
                    //     inst_q_wdata = '0;
                    end
                end
               
            end
        
        icache_ufp_addr = pc_next; 
        read_idx = pc_next[$clog2(PHT_DEPTH)-1:0]; //need to change for 2 level predictor
        gshare_read_idx = pc_next[$clog2(LHT_DEPTH)-1:0] ^ ghr;
        // gshare_read_idx = pc_next[$clog2(LHT_DEPTH)-1:0];
        // btb_read_idx = pc_next[$clog2(BTB_DEPTH)-1:0];
    end

    //how to mask response



endmodule : fetch
