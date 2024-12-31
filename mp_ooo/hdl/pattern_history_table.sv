module pattern_history_table
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to fetch
    input   logic   [$clog2(PHT_DEPTH)-1:0]  read_idx,
    // input   logic   [$clog2(IQUEUE_DEPTH)-1:0]  inst_q_tail,

    // connections to instruction queue
    output  bp_state_t                          bp_curr_state,  
    // output  logic   [$clog2(IQUEUE_DEPTH)-1:0]  iqueue_write_idx,


    // connections to exe
    input   logic   [$clog2(PHT_DEPTH)-1:0] write_idx,
    input   logic                           branch_we,
    input   logic                           branch_taken,
    input   bp_state_t                      bp_prev_state,
    output  logic   [$clog2(LHT_DEPTH)-1:0] curr_pattern,
    input   logic   [$clog2(LHT_DEPTH)-1:0] prev_pattern          

);

logic   [$clog2(LHT_DEPTH)-1:0] pattern_dout0, pattern_dout1;
logic valid  [PHT_DEPTH];
logic [$clog2(LHT_DEPTH)-1:0] br_next_pattern, din1_reg, curr_pattern0;
logic [$clog2(PHT_DEPTH)-1:0]  read_idx_latch, addr0_reg, addr1_reg;
logic [1:0]       bp_curr_state_val;
logic web1_reg;
// bp_state_t                          bp_curr_state;
// logic   [$clog2(LHT_DEPTH)-1:0] curr_pattern;




always_ff @(posedge clk) begin 
    if (rst) begin 
        // iqueue_write_idx <= '0;
        for (int i = 0; i < PHT_DEPTH; i++) valid[i] <= '0;
    end else begin 
        // iqueue_write_idx <= inst_q_tail; //add boundary conditions
        if (branch_we) valid[write_idx] <= 1'b1;
        web1_reg <= branch_we;
        addr0_reg <= read_idx;
        addr1_reg <= write_idx;
        din1_reg <= br_next_pattern; 
    end
end

always_comb begin 
    br_next_pattern = {prev_pattern[$clog2(LHT_DEPTH)-2:0], branch_taken};

    if (valid[addr0_reg]) begin 
        if (web1_reg && (addr0_reg == addr1_reg))
          curr_pattern = din1_reg;
        else if (branch_we && (addr0_reg == write_idx))
          curr_pattern = br_next_pattern;
        else 
            curr_pattern = pattern_dout0;
    end else 
        curr_pattern = '0;

//     if (valid[addr1_reg]) begin 
//         if (web1_reg)
//           curr_pattern = din1_reg;
//         else if (branch_we && (addr1_reg == write_idx))
//           curr_pattern = br_next_pattern;
//         else 
//             curr_pattern = pattern_dout1;
//     end else 
//         curr_pattern = '0;
end

pht_sram            pht(.clk0       (clk),
                        .csb0       (1'b0),
                        .web0       (1'b1),
                        .addr0      (read_idx),
                        .din0       ('0),
                        .dout0      (pattern_dout0),
                        .clk1       (clk),
                        .csb1       (1'b0),
                        .web1       (~branch_we), //active low
                        .addr1      (write_idx),
                        .din1       (br_next_pattern),
                        .dout1      (pattern_dout1));

local_history_table lht(.*, .read_idx(curr_pattern),
                        .bp_curr_state(bp_curr_state), 
                        .write_idx(prev_pattern),
                        .branch_we(branch_we),
                        .branch_taken(branch_taken),
                        .bp_prev_state(bp_prev_state));
// end endgenerate




endmodule : pattern_history_table