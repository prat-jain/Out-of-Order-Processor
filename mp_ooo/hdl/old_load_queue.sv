// module load_queue
// import rv32i_types::*;
// import params::*;
// #(
//     parameter   WIDTH   = 64,   // Width of each entry in bits
//     parameter   DEPTH   = 8   // Depth of the FIFO (number of entries)
// )(
//     input   logic                       clk,
//     input   logic                       rst,

//     // connections to decode
//     input   ls_queue_entry_t            wdata,
//     input   logic                       load_enqueue,

//     output  logic                       load_full,
    
//     // connections to reg file
//     output  logic   [5:0]               ps1_ls,
//     output  logic   [5:0]               ps2_ls,

//     input   logic   [31:0]              ps1_v_ls,
//     input   logic   [31:0]              ps2_v_ls,

//     // connections to dcache
//     output  logic   [3:0]               dcache_ufp_rmask,
//     input   logic                       dcache_ufp_resp,
//     output  logic   [31:0]              dcache_ufp_addr,
//     input   logic   [31:0]              dcache_ufp_rdata,

//     // connections to cdb
//     output  CDB_t                       load_cdb,
//     input   CDB_t                       alu_cdb,
//     input   CDB_t                       mul_cdb,        
//     input   CDB_t                       div_cdb,

//     // connection to rob
//     output  rvfi_mem_signals_t          curr_mem_operation,
//     input   logic                       flush

// );
    
//     ls_queue_entry_t    load_queue   [DEPTH];

//     logic   [$clog2(DEPTH)-1:0]  load_head;
//     logic   [$clog2(DEPTH)-1:0]  load_tail;

//     logic                        load_overflow;
//     logic                        load_empty;
    
//     ls_queue_entry_t             load_rdata;
//     logic                        load_dequeue;

//     logic   [31:0]  load_request_addr, load_request_addr2;
//     logic   [3:0]   load_request_rmask;

//     logic   [31:0]  latch_addr, latch_wdata;
//     logic   [3:0]   latch_rmask, latch_wmask;

//     logic   ready, ready_latch;

//     assign load_empty = (load_head == load_tail) && ~load_overflow;
//     assign load_full = (load_head == load_tail) && load_overflow;

//     always_comb begin
//         load_rdata = '0; 
//         if (!load_empty) begin
//             load_rdata = (load_queue[load_head + 1].ps1_valid && load_queue[load_head + 1].ps2_valid && dcache_ufp_resp)  ? load_queue[load_head + 1] : load_queue[load_head]; 
//         end
//     end

//     always_ff @(posedge clk) begin 
//         if (rst || flush) begin
//             load_head        <= '0;
//             for(int i = '0; i < DEPTH; ++i) begin
//                 load_queue[i] <= '0;
//             end
//         end else if (load_dequeue && !load_empty) begin
//             load_head        <= load_head + 2'b1;
//             load_queue[load_head].valid <= 1'b0;
//         end
//     end

//     always_ff @(posedge clk) begin 
//         if (rst || flush) begin
//             load_tail        <= '0;
//             load_overflow    <= '0;
//         end else begin
//             if (load_enqueue && !load_full) begin
//                 load_queue[load_tail]         <= wdata;
//                 load_queue[load_tail].valid   <= 1'b1;         
//                 load_tail                <=  load_tail + 1'b1;
//                 load_overflow            <= ((load_tail + 1'b1) == load_head);
//             end
//             if (load_overflow && load_enqueue) load_overflow <= '0;


//             if (alu_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (load_queue[i].valid) begin
//                         if (load_queue[i].ps1 == alu_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
//                         if (load_queue[i].ps2 == alu_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (div_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (load_queue[i].valid) begin
//                         if (load_queue[i].ps1 == div_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
//                         if (load_queue[i].ps2 == div_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (mul_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (load_queue[i].valid) begin
//                         if (load_queue[i].ps1 == mul_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
//                         if (load_queue[i].ps2 == mul_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (load_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (load_queue[i].valid) begin
//                         if (load_queue[i].ps1 == load_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
//                         if (load_queue[i].ps2 == load_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end


//         end
//     end

//     always_comb begin
//         load_request_addr2 = ps1_v_ls + load_rdata.imm; 
//         load_request_addr = {load_request_addr2[31:2], 2'b00}; 
//         load_request_rmask = '0;

//         if (load_rdata.op_code == op_b_load) begin
//             unique case (load_rdata.funct3) 
//                 load_f3_lb, load_f3_lbu: load_request_rmask = 4'b0001 << load_request_addr2[1:0]; //request_addr has addr
//                 load_f3_lh, load_f3_lhu: load_request_rmask = 4'b0011 << load_request_addr2[1:0];
//                 load_f3_lw             : load_request_rmask = 4'b1111;
//                 default                : load_request_rmask = '0;
//             endcase
//         end 
//     end

//     //wait for response and drive cdb
//     always_comb begin 
//         curr_mem_operation = '0; 
//         load_dequeue = 1'b0;

//         load_cdb.rd = load_rdata.rd;
//         load_cdb.pd = load_rdata.pd;
//         load_cdb.pv = '0;
//         load_cdb.regf_we = '0;
//         load_cdb.rob_entry = load_rdata.rob_entry;
//         load_cdb.pc = load_rdata.pc;

//         if (dcache_ufp_resp) begin
//             curr_mem_operation.addr  = load_request_addr2;
//             curr_mem_operation.rdata = dcache_ufp_rdata;
//             curr_mem_operation.rmask = load_request_rmask;

//             load_dequeue = 1'b1;
//             load_cdb.regf_we = 1'b1;

//             unique case(load_rdata.funct3) 
//                 load_f3_lb : load_cdb.pv = {{24{dcache_ufp_rdata[7 +8 *load_request_addr2[1:0]]}}, dcache_ufp_rdata[8 *load_request_addr2[1:0] +: 8 ]};
//                 load_f3_lbu: load_cdb.pv = {{24{1'b0}}                          , dcache_ufp_rdata[8 *load_request_addr2[1:0] +: 8 ]};
//                 load_f3_lh : load_cdb.pv = {{16{dcache_ufp_rdata[15+16*load_request_addr2[1]  ]}}, dcache_ufp_rdata[16*load_request_addr2[1]   +: 16]};
//                 load_f3_lhu: load_cdb.pv = {{16{1'b0}}                          , dcache_ufp_rdata[16*load_request_addr2[1]   +: 16]};
//                 load_f3_lw : load_cdb.pv = dcache_ufp_rdata;
//                 default    : load_cdb.pv = '0;
//             endcase

//         end 
//     end

// endmodule : load_queue