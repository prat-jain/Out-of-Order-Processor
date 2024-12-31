module stack #(
    parameter DATA_WIDTH = 32,       // Width of the data in bits
    parameter STACK_DEPTH = 16      // Depth of the stack
) (
    input  logic                  clk,           // Clock signal
    input  logic                  rst,         // Reset signal (active high)
    input  logic                  push,          // Push enable
    input  logic                  pop,           // Pop enable
    input  logic [DATA_WIDTH-1:0] push_data,     // Data to push
    output logic [DATA_WIDTH-1:0] pop_data,      // Data from the top of the stack
    output logic                  full,          // Full flag
    output logic                  empty          // Empty flag
);

    // Local parameters
    localparam ADDR_WIDTH = $clog2(STACK_DEPTH); // Address width based on stack depth

    // Internal signals
    logic [DATA_WIDTH-1:0] stack_mem [0:STACK_DEPTH-1]; // Stack memory
    logic [ADDR_WIDTH-1:0] sp;                          // Stack pointer

    // Full and empty flag logic
    assign full  = (sp == 4'd7);
    assign empty = (sp == '0);

    // Pop data is the top of the stack (if not empty)
    assign pop_data = empty ? '0 : stack_mem[sp - 1];

    // Sequential logic for stack operations
    always_ff @(posedge clk) begin
        if (rst) begin
            sp <= '0; // Reset stack pointer
        end else begin
            if (push && !empty && pop && !full) begin
                stack_mem[sp] <= push_data;
            end else begin
                if (pop && !empty) begin
                    stack_mem[sp] <= '1;
                    sp <= sp - 1'b1;              // Decrement stack pointer
                end
                if (push && !full) begin
                    stack_mem[sp] <= push_data; // Push data onto stack
                    sp <= sp + 1'b1;              // Increment stack pointer
                end
            end
        end
    end

endmodule
