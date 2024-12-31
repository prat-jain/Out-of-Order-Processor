module store_queue
import rv32i_types::*;
import params::*;
#(
    parameter   WIDTH   = 64,   // Width of each entry in bits
    parameter   DEPTH   = 4   // Depth of the FIFO (number of entries)
)(
    input   logic                       clk,
    input   logic                       rst,

    // connections to decode
    input   ls_queue_entry_t            wdata,
    input   logic                       store_enqueue,

    output  logic                       store_full,
    
    // connections to reg file
    output  logic   [5:0]               ps1_ls,
    output  logic   [5:0]               ps2_ls,

    input   logic   [31:0]              ps1_v_ls,
    input   logic   [31:0]              ps2_v_ls,

    // connections to cdb
    input   CDB_t                       alu_cdb,
    input   CDB_t                       mul_cdb,        
    input   CDB_t                       div_cdb,
    input   CDB_t                       load_cdb,

    input    logic                       store_ack, 
    output     logic                     store_req,
    output  split_lsq_t                  store_queue_req, 

    input   logic       [31:0]           load_store_age, 

    output   logic       [31:0]          store_age_order[DEPTH],
    output   logic                       store_valid_order   [DEPTH],
    output   logic                       store_ps2_valid_order   [DEPTH],
    output   logic                       store_valid   [DEPTH],
    output   logic       [31:0]          store_addr    [DEPTH],
    output   logic       [31:0]          store_val    [DEPTH],
    output   logic       [2:0]           store_funct3 [DEPTH],



    output logic   [5:0]    ps1_st_addr1,
    output logic   [5:0]    ps1_st_addr2,
    output logic   [5:0]    ps1_st_addr3,
    output logic   [5:0]    ps1_st_addr4,
    input  logic   [31:0]   ps1_v_st_addr1,
    input  logic   [31:0]   ps1_v_st_addr2,
    input  logic   [31:0]   ps1_v_st_addr3,
    input  logic   [31:0]   ps1_v_st_addr4,

    output    logic   [5:0]    ps2_st_addr1,
    output    logic   [5:0]    ps2_st_addr2,
    output    logic   [5:0]    ps2_st_addr3,
    output    logic   [5:0]    ps2_st_addr4,
    input   logic   [31:0] ps2_v_st_addr1  ,
    input   logic   [31:0] ps2_v_st_addr2  ,
    input   logic   [31:0] ps2_v_st_addr3  ,
    input   logic   [31:0] ps2_v_st_addr4  ,

    // connection to rob
    input   logic                       flush,
    input   logic   [$clog2(ROB_QUEUE_DEPTH)-1:0] rob_head

);

    ls_queue_entry_t    store_queue   [DEPTH];
    
    logic   [$clog2(DEPTH)-1:0]  store_head;
    logic   [$clog2(DEPTH)-1:0]  store_tail;

    logic                        store_overflow;
    logic                        store_empty;
    
    ls_queue_entry_t             store_rdata;
    logic                        store_dequeue;

    logic   [31:0]  store_request_addr, store_request_addr2;
    logic   [3:0]   store_request_wmask;
    logic   [31:0]  store_request_wdata; 

    logic ready; 

always_comb begin
    for (int i = 0; i < DEPTH; i++) begin
        store_valid_order[i] = store_queue[i].ps1_valid; 
        store_ps2_valid_order[i] = store_queue[i].ps2_valid; 
        store_funct3[i] = store_queue[i].funct3;
    end
    ps1_st_addr1 = store_queue[0].ps1;  
    ps1_st_addr2 = store_queue[1].ps1; 
    ps1_st_addr3 = store_queue[2].ps1; 
    ps1_st_addr4 = store_queue[3].ps1; 
    store_addr[0] = ps1_v_st_addr1 + store_queue[0].imm; 
    store_addr[1] = ps1_v_st_addr2 + store_queue[1].imm; 
    store_addr[2] = ps1_v_st_addr3 + store_queue[2].imm; 
    store_addr[3] = ps1_v_st_addr4 + store_queue[3].imm; 

    ps2_st_addr1 = store_queue[0].ps2;  
    ps2_st_addr2 = store_queue[1].ps2; 
    ps2_st_addr3 = store_queue[2].ps2; 
    ps2_st_addr4 = store_queue[3].ps2; 
    store_val[0] = ps2_v_st_addr1; 
    store_val[1] = ps2_v_st_addr2; 
    store_val[2] = ps2_v_st_addr3; 
    store_val[3] = ps2_v_st_addr4; 
end

always_ff @(posedge clk) begin
    if(rst || flush) begin
        store_head <= '0;
        store_tail <= '0;
        store_overflow <= '0;
        for(int i = '0; i < DEPTH; ++i) begin
            store_queue[i] <= '0;
            store_valid[i] <= '0;
        end
     end
     else begin
        // DEQUEUE LOGIC_________________________________________________ 
        if (store_dequeue && !store_empty) begin
            store_head <= store_head + 2'b1;
            store_valid[store_head] <= 1'b0;
        end
        // ENQUEUE LOGIC_________________________________________________
        if (store_enqueue && !store_full) begin
            store_queue[store_tail] <= wdata;
            store_valid[store_tail] <= 1'b1;         
            store_tail <= store_tail + 1'b1;
            store_overflow <= ((store_tail + 1'b1) == store_head);
            store_age_order[store_tail] <= load_store_age; 
        end

        if (store_overflow && store_dequeue) store_overflow <= '0;

        // VALUE FORWARD_________________________________________________ 
        if (alu_cdb.regf_we) begin 
                for (int i = 0; i < DEPTH; i++) begin
                    if (store_valid[i]) begin
                        if (store_queue[i].ps1 == alu_cdb.pd) store_queue[i].ps1_valid <= 1'b1;
                        if (store_queue[i].ps2 == alu_cdb.pd) store_queue[i].ps2_valid <= 1'b1;
                    end
                end 
            end

            if (div_cdb.regf_we) begin 
                for (int i = 0; i < DEPTH; i++) begin
                    if (store_valid[i]) begin
                        if (store_queue[i].ps1 == div_cdb.pd) store_queue[i].ps1_valid <= 1'b1;
                        if (store_queue[i].ps2 == div_cdb.pd) store_queue[i].ps2_valid <= 1'b1;
                    end
                end 
            end

            if (mul_cdb.regf_we) begin 
                for (int i = 0; i < DEPTH; i++) begin
                    if (store_valid[i]) begin
                        if (store_queue[i].ps1 == mul_cdb.pd) store_queue[i].ps1_valid <= 1'b1;
                        if (store_queue[i].ps2 == mul_cdb.pd) store_queue[i].ps2_valid <= 1'b1;
                    end
                end 
            end

            if (load_cdb.regf_we) begin 
                for (int i = 0; i < DEPTH; i++) begin
                    if (store_valid[i]) begin
                        if (store_queue[i].ps1 == load_cdb.pd) store_queue[i].ps1_valid <= 1'b1;
                        if (store_queue[i].ps2 == load_cdb.pd) store_queue[i].ps2_valid <= 1'b1;
                    end
                end 
            end
            // VALUE FORWARD_________________________________________________
     end
 end

assign store_empty = (store_head == store_tail) && ~store_overflow;
assign store_full = (store_head == store_tail) && store_overflow;
assign ps1_ls = store_rdata.ps1;
assign ps2_ls = store_rdata.ps2;

always_comb begin
    store_request_addr2 = ps1_v_ls + store_rdata.imm; 
    store_request_addr = {store_request_addr2[31:2], 2'b00}; 
    store_request_wmask = '0;
    store_request_wdata = '0;

    if (store_rdata.op_code == op_b_store) begin
        unique case (store_rdata.funct3) 
            store_f3_sb: begin 
                store_request_wmask = 4'b0001 << store_request_addr2[1:0]; 
                store_request_wdata[8*store_request_addr2[1:0] +: 8 ] = ps2_v_ls[7:0];
            end 

            store_f3_sh: begin
                store_request_wmask = 4'b0011 << store_request_addr2[1:0];
                store_request_wdata[16*store_request_addr2[1]   +: 16] = ps2_v_ls[15:0];
            end 

            store_f3_sw: begin
                store_request_wmask = 4'b1111;
                store_request_wdata = ps2_v_ls;
            end

            default: begin 
                store_request_wmask = '0;
                store_request_wdata = '0;
            end
        endcase
    end
end

assign store_rdata = (!store_empty) ? store_queue[store_head] : '0;
assign ready = (store_rdata.ps1_valid && store_rdata.ps2_valid) && ~store_empty && store_valid[store_head] && (rob_head == store_rdata.rob_entry);
assign store_dequeue = store_valid[store_head] & store_ack; 
assign store_req = ready && ~flush; 

always_comb begin 

        store_queue_req = '0; 
        store_queue_req.addr2 = store_request_addr2; 
        store_queue_req.addr = store_request_addr; 
        store_queue_req.wmask = store_request_wmask; 
        store_queue_req.wdata = store_request_wdata; 

        store_queue_req.rd = store_rdata.rd;
        store_queue_req.pd = store_rdata.pd;
        store_queue_req.rob_entry = store_rdata.rob_entry;
        store_queue_req.pc = store_rdata.pc;

end

endmodule 