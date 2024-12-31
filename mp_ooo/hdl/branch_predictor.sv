
module branch_predictor
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to execution 
    input   logic               branch_taken, //1 if branch taken, 0 if not 
    input   logic               branch_we, //high if branch at execute

    // connections to decode
    output  bp_state_t          bp_curr_state
);
// for all branch instructions
// jal always taken
// jalr always not taken??

bp_state_t state, next_state;

always_ff @ (posedge clk) begin 
    if (rst) begin 
        state <= wt;
    end else begin 
        state <= next_state;
    end
end

always_comb begin 
    next_state = state;

    if (branch_we) begin 
        unique case (state)
            snt : next_state = branch_taken ? wnt : snt;
            wnt : next_state = branch_taken ? wt : snt;
            wt : next_state = branch_taken ? st : wnt;
            st : next_state = branch_taken ? st : wt;
            default : next_state = state;
        endcase
    end
end

assign bp_curr_state = state;


endmodule : branch_predictor
