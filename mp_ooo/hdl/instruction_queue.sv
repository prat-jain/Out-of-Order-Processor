module instruction_queue
import rv32i_types::*;
import params::*;
#(
    parameter   WIDTH   = 64,   // Width of each entry in bits
    parameter   DEPTH   = 4   // Depth of the FIFO (number of entries)
)(
    input   logic               clk,
    input   logic               rst,

    input   iq_struct_t         wdata,
    input   logic               enqueue,

    output  iq_struct_t         rdata,
    input   logic               dequeue,

    output  logic               full,
    output  logic               empty,

    input   logic               flush,

    // connections from decode
    // input  logic    [31:0]     predicted_pc_next,
    input  logic               decode_pc_we

    // input  bp_state_t                          bp_curr_state,  
    // input  logic   [$clog2(IQUEUE_DEPTH)-1:0]  iqueue_write_idx,
);

    iq_struct_t         queue   [DEPTH];

    logic   [$clog2(DEPTH)-1:0] head;
    logic   [$clog2(DEPTH)-1:0] tail;

    logic                       overflow;
    logic   [$clog2(DEPTH)-1:0] tail_next;
    // logic   enqueue_latch;

    // read logic (dequeue)
    always_ff @(posedge clk) begin 
        if (rst || flush || decode_pc_we) begin
            head        <= '0;
        end else if (dequeue && !empty) begin
            // rdata       <= queue[head];
            head        <= head + 2'b1;
        end
        
    end

    always_comb begin //forwarding
        rdata = (!empty) ? queue[head] : 'x;
        // if (dequeue && (head == iqueue_write_idx)) rdata.bp_curr_state = bp_curr_state;
    end

    assign tail_next = tail + 2'b1;

    //write logic (enqueue)
    always_ff @(posedge clk) begin 
        if (rst || flush || decode_pc_we) begin
            tail        <= '0;
            overflow    <= '0;
        end else begin 
            if (enqueue && !full) begin
                queue[tail]         <= wdata;
                tail                <= tail_next;
                overflow            <= (tail_next == head);
            end

            // if (enqueue_latch) queue[iqueue_write_idx].bp_curr_state <= bp_curr_state; //if enqueued in prev cycle, 
        end 
        
        if (overflow && dequeue) overflow <= '0;

        // enqueue_latch <= enqueue;
    end
    
    assign empty = (head == tail) && ~overflow;
    assign full = (head == tail) && overflow;


endmodule : instruction_queue
