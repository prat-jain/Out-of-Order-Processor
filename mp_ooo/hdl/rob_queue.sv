module rob_queue
import rv32i_types::*;
import params::*;
#(
    parameter   WIDTH   = 64,   // Width of each entry in bits
    parameter   DEPTH   = 4   // Depth of the FIFO (number of entries)
)(
    input   logic               clk,
    input   logic               rst,

    input   rob_entry_t         wdata,
    input   logic               enqueue,

    output  rob_entry_t         rdata,
    input   logic               dequeue,

    // connections to CDB
    input   logic               alu_commit_we,
    input   logic   [$clog2(DEPTH)-1:0] alu_commit_entry,
    input   logic                alu_branch_taken,

    input   logic               update_pc_next, //flush
    input   logic   [31:0]      pc_next_val,

    input   logic               mul_commit_we,
    input   logic   [$clog2(DEPTH)-1:0] mul_commit_entry,

    input   logic               div_commit_we,
    input   logic   [$clog2(DEPTH)-1:0] div_commit_entry,

    input   logic               ls_commit_we,
    input   logic   [$clog2(DEPTH)-1:0] ls_commit_entry,

    input   logic               st_commit_we,
    input   logic   [$clog2(DEPTH)-1:0] st_commit_entry,

    // connections to rrf
    output  logic               valid_front,
    output  logic   [$clog2(DEPTH)-1:0]  tail, //to determine rob entry for RS, combinational

    output  logic               full,
    output  logic               empty,

    // connections to ls queue for rvfi stuff
    input   rvfi_mem_signals_t          curr_mem_operation,
    input   rvfi_mem_signals_t          curr_mem_operation_store,
    output  rvfi_mem_signals_t          mem_rvfi_output,

    //flush signal
    input   logic                       flush,

    output  logic   [$clog2(DEPTH)-1:0] head
);

    rvfi_mem_signals_t rvfi_mem_signals[DEPTH];

    rob_entry_t         queue   [DEPTH];


    logic                       overflow;
    logic   [$clog2(DEPTH)-1:0] tail_next;

    always_ff @(posedge clk) begin 
        if (rst || flush) begin 
            for (int i = 0; i < DEPTH; i++) rvfi_mem_signals[i] <= '0;
        end else begin
            if (enqueue && !full) rvfi_mem_signals[tail] <= '0;
            
            if (ls_commit_we) rvfi_mem_signals[ls_commit_entry] <= curr_mem_operation;
            if (st_commit_we) rvfi_mem_signals[st_commit_entry] <= curr_mem_operation_store;
        end
    end

    assign mem_rvfi_output = (!empty) ? rvfi_mem_signals[head] : '0;

    // read logic (dequeue)
    always_ff @(posedge clk) begin 
        if (rst || flush) begin
            head        <= '0;
        end else if (dequeue && !empty) begin
            // rdata       <= queue[head];
            head        <= head + 2'b1;
        end
        
    end

    assign valid_front = queue[head].commit; //ready to commit

    assign rdata = (!empty) ? queue[head] : '0;

    assign tail_next = tail + 2'b1;

    //write logic (enqueue)
    always_ff @(posedge clk) begin 
        if (rst || flush) begin
            for (int i = 0; i < ROB_QUEUE_DEPTH; i++) begin 
                queue[i].commit <= 1'b0;
                queue[i].flush <= 1'b0;
            end
            
            tail        <= '0;
            overflow    <= '0;
        end else begin 
            
            if (enqueue && !full) begin
                queue[tail]         <= wdata;
                tail                <= tail_next;
                overflow            <= (tail_next == head);
            end

            if (alu_commit_we) begin 
                queue[alu_commit_entry].commit <= 1'b1; //commit entry != tail, CAN NEVER BE SAME
                queue[alu_commit_entry].flush <= update_pc_next;
                queue[alu_commit_entry].branch_taken <= alu_branch_taken;
                
                if (update_pc_next) queue[alu_commit_entry].pc_next <= pc_next_val;
            end 

            if (mul_commit_we) queue[mul_commit_entry].commit <= 1'b1; //commit entry != tail, CAN NEVER BE SAME
            if (div_commit_we) queue[div_commit_entry].commit <= 1'b1; //commit entry != tail, CAN NEVER BE SAME
            if (ls_commit_we)  queue[ls_commit_entry].commit <= 1'b1; //commit entry != tail, CAN NEVER BE SAME
            if (st_commit_we)  queue[st_commit_entry].commit <= 1'b1; //commit entry != tail, CAN NEVER BE SAME


            if (overflow && dequeue) overflow <= '0;
        end
    end

    
    assign empty = (head == tail) && ~overflow;
    assign full = (head == tail) && overflow;


endmodule : rob_queue
