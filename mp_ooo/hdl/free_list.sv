module free_list
import rv32i_types::*;
import params::*;
#(
    parameter   WIDTH   = FREE_LIST_WIDTH,   // Width of each entry in bits
    parameter   DEPTH   = FREE_LIST_DEPTH   // Depth of the FIFO (number of entries)
)(
    input   logic               clk,
    input   logic               rst,

    input   logic   [WIDTH-1:0] wdata,
    input   logic               enqueue,

    output  logic   [WIDTH-1:0] rdata,
    input   logic               dequeue,

    output  logic               full,
    output  logic               empty,

    input   logic               flush
);

    logic   [WIDTH-1:0]         queue   [DEPTH];

    logic   [$clog2(DEPTH)-1:0] head;
    logic   [$clog2(DEPTH)-1:0] tail;

    logic                       overflow;
    logic   [$clog2(DEPTH)-1:0] tail_next;

    // read logic (dequeue)
    always_ff @(posedge clk) begin 
        if (rst) begin
            head        <= '0;
        end else if (flush) begin 
            head <= '0;
        end else if (dequeue && !empty) begin
            // rdata       <= queue[head];
            head        <= head + 2'b1;
        end
    end

    assign rdata =  (!empty) ? queue[head] : 'x;

    assign tail_next = tail + 2'b1;

    //write logic (enqueue)
    always_ff @(posedge clk) begin 
        if (rst) begin
            tail        <= '0;
            overflow    <= 1'b1;
            for (int i = 0; i < 32; i++) begin
                queue[i] <= unsigned'(6'(i)) + 6'd32;
            end
        end else if (flush) begin 
            tail <= '0;
            overflow <= 1'b1;
            if (enqueue) begin
                queue[tail] <= wdata;
                // tail <= 5'b1;
            end
        end else begin 
            if (enqueue && !full) begin
                queue[tail]         <= wdata;
                tail                <= tail_next;
                overflow            <= (tail_next == head);
            end
            if (overflow && dequeue) overflow <= '0;
        end
    end
    
    assign empty = (head == tail) && ~overflow;
    assign full = (head == tail) && overflow;


endmodule : free_list
