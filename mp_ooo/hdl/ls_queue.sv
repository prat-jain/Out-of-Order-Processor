// module ls_queue
// import rv32i_types::*;
// import params::*;
// #(
//     parameter   WIDTH   = 64,   // Width of each entry in bits
//     parameter   DEPTH   = 8   // Depth of the FIFO (number of entries)
// )(
//     input   logic               clk,
//     input   logic               rst,

//     // connections to decode
//     input   ls_queue_entry_t    wdata,
//     input   logic               enqueue,

//     output  logic               full,
//     // output  logic               empty,
    
//     // connections to reg file
//     output  logic   [5:0]       ps1_ls,
//     output  logic   [5:0]       ps2_ls,

//     input   logic   [31:0]      ps1_v_ls,
//     input   logic   [31:0]      ps2_v_ls,

//     // connections to dcache
//     output  logic   [3:0]               dcache_ufp_rmask,
//     output  logic   [3:0]               dcache_ufp_wmask,
//     input   logic                       dcache_ufp_resp,
//     output  logic   [31:0]              dcache_ufp_addr,
//     output  logic   [31:0]              dcache_ufp_wdata,
//     input   logic   [31:0]              dcache_ufp_rdata,

//     // connections to cdb
//     output  CDB_t                       load_cdb,
//     input   CDB_t                       alu_cdb,
//     input   CDB_t                       mul_cdb,        
//     input   CDB_t                       div_cdb,

//     // connection to rob
//     output  rvfi_mem_signals_t                  curr_mem_operation,
//     // input   logic   [PR_WIDTH-1:0]              rob_top_pd       
//     // input   rob_entry_t                 rob_rdata,
//     input   logic   [$clog2(ROB_QUEUE_DEPTH)-1:0] rob_head,

//     input   logic                       flush

// );
//     logic               empty;
//     ls_queue_entry_t    queue   [DEPTH];
//     logic               valid   [DEPTH];


//     logic   [$clog2(DEPTH)-1:0] head;
//     logic   [$clog2(DEPTH)-1:0]  tail;

//     logic                       overflow;
//     logic   [$clog2(DEPTH)-1:0] tail_next;

//     ls_queue_entry_t    rdata;
//     logic               dequeue;

//     logic   [31:0]  request_addr, request_addr2, request_wdata;
//     logic   [3:0]   request_rmask, request_wmask;
//     logic   [31:0]  latch_addr, latch_wdata;
//     logic   [3:0]   latch_rmask, latch_wmask;

//     logic   ready, flush_latch, ready_latch;

//     always_ff @(posedge clk) begin 
//         if (rst) begin 
//             latch_addr <= '0;
//             latch_rmask <= '0;
//             latch_wmask <= '0;
//             latch_wdata <= '0;
//             ready_latch <= '0;
//         end else begin 
//             if (flush && ~flush_latch) begin 
//                 latch_addr <= dcache_ufp_addr;
//                 latch_rmask <= dcache_ufp_rmask;
//                 latch_wmask <= dcache_ufp_wmask;
//                 latch_wdata <= dcache_ufp_wdata;
//             end

//             ready_latch <= ready;
//         end
//     end


//     // valid entry logic
//     always_ff @(posedge clk) begin 
//         if (rst) begin
//             for (int i = 0; i < DEPTH; i++) valid[i] <= '0;
//             flush_latch <= 1'b0;
//         end else if (flush && ready_latch) begin 
//             if (~dcache_ufp_resp) flush_latch <= 1'b1;
//             for (int i = 0; i < DEPTH; i++) valid[i] <= '0;
//         end else begin
//             if (flush_latch && dcache_ufp_resp) flush_latch <= 1'b0;

//             if (dequeue && !empty) 
//                 valid[head] <= '0;
            
//             if (enqueue && !full) 
//                 valid[tail] <= 1'b1;
            
//         end
//     end


//     // read logic (dequeue)
//     always_ff @(posedge clk) begin 
//         if (rst || flush) begin
//             head        <= '0;
//         end else if (dequeue && !empty) begin
//             // rdata       <= queue[head];
//             head        <= head + 2'b1;
//         end
//     end

//     assign rdata = (!empty) ? queue[head] : '0; //top queue entry

//     assign tail_next = tail + 2'b1;

//     //write logic (enqueue)
//     always_ff @(posedge clk) begin 
//         if (rst || flush) begin
//             tail        <= '0;
//             overflow    <= '0;
//         end else begin
        
//             if (enqueue && !full) begin
//                 queue[tail]         <= wdata;
//                 tail                <= tail_next;
//                 overflow            <= (tail_next == head);
//             end

//             if (overflow && dequeue) overflow <= '0;

//             if (alu_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (valid[i]) begin
//                         if (queue[i].ps1 == alu_cdb.pd) queue[i].ps1_valid <= 1'b1;
//                         if (queue[i].ps2 == alu_cdb.pd) queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (div_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (valid[i]) begin
//                         if (queue[i].ps1 == div_cdb.pd) queue[i].ps1_valid <= 1'b1;
//                         if (queue[i].ps2 == div_cdb.pd) queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (mul_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (valid[i]) begin
//                         if (queue[i].ps1 == mul_cdb.pd) queue[i].ps1_valid <= 1'b1;
//                         if (queue[i].ps2 == mul_cdb.pd) queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end

//             if (load_cdb.regf_we) begin //check stations with ALU CDB
//                 for (int i = 0; i < DEPTH; i++) begin
//                     if (valid[i]) begin
//                         if (queue[i].ps1 == load_cdb.pd) queue[i].ps1_valid <= 1'b1;
//                         if (queue[i].ps2 == load_cdb.pd) queue[i].ps2_valid <= 1'b1;
//                     end
//                 end 
//             end
//         end
//     end

    
//     assign empty = (head == tail) && ~overflow;
//     assign full = (head == tail) && overflow;


//     assign ps1_ls = rdata.ps1;
//     assign ps2_ls = rdata.ps2;

//     //address and data calculation
//     always_comb begin
//         request_addr2 = ps1_v_ls + rdata.imm; 
//         request_addr = {request_addr2[31:2], 2'b00}; 
//         request_rmask = '0;
//         request_wmask = '0;
//         request_wdata = '0;

//         if (rdata.op_code == op_b_load) begin
//             unique case (rdata.funct3) 
//                 load_f3_lb, load_f3_lbu: request_rmask = 4'b0001 << request_addr2[1:0]; //request_addr has addr
//                 load_f3_lh, load_f3_lhu: request_rmask = 4'b0011 << request_addr2[1:0];
//                 load_f3_lw             : request_rmask = 4'b1111;
//                 default                : request_rmask = '0;
//             endcase
//         end 
        
//         if (rdata.op_code == op_b_store) begin
//             unique case (rdata.funct3) 
//                 store_f3_sb: begin 
//                     request_wmask = 4'b0001 << request_addr2[1:0]; 
//                     request_wdata[8*request_addr2[1:0] +: 8 ] = ps2_v_ls[7:0];
//                 end 

//                 store_f3_sh: begin
//                     request_wmask = 4'b0011 << request_addr2[1:0];
//                     request_wdata[16*request_addr2[1]   +: 16] = ps2_v_ls[15:0];
//                 end 

//                 store_f3_sw: begin
//                     request_wmask = 4'b1111;
//                     request_wdata = ps2_v_ls;
//                 end

//                 default: begin 
//                     request_wmask = '0;
//                     request_wdata = '0;
//                 end
//             endcase
//         end

//     end

//     //load store request to memory
//     always_comb begin
//         ready = (rdata.ps1_valid && rdata.ps2_valid) && ~empty && valid[head] && ~dcache_ufp_resp;
        
//         if (rdata.op_code == op_b_store) begin  
//             ready = ((rob_head == rdata.rob_entry) && (rdata.ps1_valid && rdata.ps2_valid) && ~empty && ~dcache_ufp_resp);
//         end

//         if (flush_latch) begin 
//             dcache_ufp_rmask = latch_rmask;
//             dcache_ufp_wmask = latch_wmask;
//             dcache_ufp_addr =  latch_addr;
//             dcache_ufp_wdata = latch_wdata;
//         end else begin 
//             dcache_ufp_rmask = ready ? request_rmask: '0;
//             dcache_ufp_wmask = ready ? request_wmask: '0;
//             dcache_ufp_addr =  ready ? request_addr : '0; // setting request addr sequentially
//             dcache_ufp_wdata = ready ? request_wdata: '0;
//         end
        
//     end

//     //wait for response and drive cdb
//     always_comb begin 

//         curr_mem_operation = '0; 

//         dequeue = 1'b0;

//         load_cdb.rd = rdata.rd;
//         load_cdb.pd = rdata.pd;
//         load_cdb.pv = '0;
//         load_cdb.regf_we = '0;
//         load_cdb.rob_entry = rdata.rob_entry;
//         load_cdb.pc = rdata.pc;

//         if (dcache_ufp_resp && ~flush_latch) begin
//             curr_mem_operation.addr = request_addr2;
//             curr_mem_operation.rdata = dcache_ufp_rdata;
//             curr_mem_operation.wdata = request_wdata;
//             curr_mem_operation.rmask = request_rmask;
//             curr_mem_operation.wmask = request_wmask;

//             dequeue = 1'b1;
//             load_cdb.regf_we = 1'b1;

//             if (rdata.op_code == op_b_load) begin

//                 unique case(rdata.funct3) 
//                     load_f3_lb : load_cdb.pv = {{24{dcache_ufp_rdata[7 +8 *request_addr2[1:0]]}}, dcache_ufp_rdata[8 *request_addr2[1:0] +: 8 ]};
//                     load_f3_lbu: load_cdb.pv = {{24{1'b0}}                          , dcache_ufp_rdata[8 *request_addr2[1:0] +: 8 ]};
//                     load_f3_lh : load_cdb.pv = {{16{dcache_ufp_rdata[15+16*request_addr2[1]  ]}}, dcache_ufp_rdata[16*request_addr2[1]   +: 16]};
//                     load_f3_lhu: load_cdb.pv = {{16{1'b0}}                          , dcache_ufp_rdata[16*request_addr2[1]   +: 16]};
//                     load_f3_lw : load_cdb.pv = dcache_ufp_rdata;
//                     default    : load_cdb.pv = '0;
//                 endcase
//             end
           
//         end 
//     end


// endmodule : ls_queue