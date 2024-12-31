module local_history_table
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to decode
    input   logic   [$clog2(LHT_DEPTH)-1:0]  read_idx,
    output  bp_state_t                      bp_curr_state,  

    // connections to exe
    input   logic   [$clog2(LHT_DEPTH)-1:0]  write_idx,
    input   logic                           branch_we,
    input   logic                           branch_taken,
    input   bp_state_t                      bp_prev_state

);

bp_state_t       branch_next_state, din1_reg;
logic   [$clog2(LHT_DEPTH)-1:0]  read_idx_latch, addr0_reg, addr1_reg;
logic            valid   [LHT_DEPTH];
logic [1:0]       bp_curr_state_val;
logic web1_reg;

//branch history table
// logic  branch_we_arr [HT_DEPTH];
// logic  branch_taken_arr [HT_DEPTH];
// bp_state_t  bp_curr_state_arr [HT_DEPTH];

// generate for (genvar i = 0; i < HT_DEPTH; i++) begin

//     branch_predictor bp (.*,.branch_we(branch_we_arr[i]),
//                             .branch_taken(branch_taken_arr[i]),
//                             .bp_curr_state(bp_curr_state_arr[i]));

// end endgenerate

always_ff @(posedge clk) begin 
    if (rst) begin 
        for (int i = 0; i < LHT_DEPTH; i++) begin 
            valid[i] <= 1'b0;
        end
        web1_reg <= '0;
        addr0_reg <= '0;
        addr1_reg <= '0;
        din1_reg <= wnt;
    end else begin 
        if (branch_we) valid[write_idx] <= 1'b1;
        web1_reg <= branch_we;
        addr0_reg <= read_idx;
        addr1_reg <= write_idx;
        din1_reg <= branch_next_state; 

    end
end

lht_sram    bht(.clk0       (clk),
                .csb0       (1'b0),
                .web0       (1'b1),
                .addr0      (read_idx),
                .din0       ('0),
                .dout0      (bp_curr_state_val),
                .clk1       (clk),
                .csb1       (1'b0),
                .web1       (~branch_we), //active low
                .addr1      (write_idx),
                .din1       (branch_next_state),
                .dout1      ());


// assign bp_curr_state = bp_curr_state_arr[read_idx];

always_comb begin 
    
    case (bp_prev_state) 
        snt : branch_next_state = branch_taken ? wnt : snt;
        wnt : branch_next_state = branch_taken ? wt : snt;
        wt : branch_next_state = branch_taken ? st : wnt;
        st : branch_next_state = branch_taken ? st : wt;
        // default : branch_next_state = wnt;
        default : branch_next_state = wnt;

    endcase

    if (valid[addr0_reg]) begin 
        if (web1_reg && (addr0_reg == addr1_reg)) 
            bp_curr_state = din1_reg;
        else if (branch_we && (addr0_reg == write_idx))
            bp_curr_state = branch_next_state;
        else 
            bp_curr_state = bp_state_t'(bp_curr_state_val);
    end else 
        // bp_curr_state = wnt;
        bp_curr_state = wnt;
    
end



endmodule : local_history_table