module btb
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // connections to fetch
    input   logic   [$clog2(BTB_DEPTH)-1:0]     btb_read_idx,
    output  logic   [31:0]                      btb_pc_next,
    output  logic                               btb_valid_read,

    // connections to execute
    input   logic                               pc_next_misprediction,
    input   logic   [$clog2(BTB_DEPTH)-1:0]     btb_write_idx,
    input   logic   [31:0]                      btb_write_pc



);
// add connections to load store queue and handle forwarding 

logic valid [BTB_DEPTH];
logic   web1_reg;
logic   [$clog2(BTB_DEPTH)-1:0] addr0_reg, addr1_reg;
logic   [31:0]  din1_reg, btb_write_next, btb_pc_next_val;


always_ff @ (posedge clk) begin 
     if (rst) begin 
        for (int i = 0; i < BTB_DEPTH; i++) begin 
            valid[i] <= 1'b0;
        end
        web1_reg <= '0;
        addr0_reg <= '0;
        addr1_reg <= '0;
        din1_reg <= '0;
    end else begin 
        if (pc_next_misprediction) valid[btb_write_idx] <= 1'b1;

        web1_reg <= pc_next_misprediction;
        addr0_reg <= btb_read_idx;
        addr1_reg <= btb_write_idx;
        din1_reg <= btb_write_pc; 

    end

end

assign btb_valid_read = valid[addr0_reg]; 

always_comb begin

    if (valid[addr0_reg]) begin 
        if (web1_reg && (addr0_reg == addr1_reg)) 
            btb_pc_next = din1_reg;
        else if (pc_next_misprediction && (addr0_reg == btb_write_idx))
            btb_pc_next = btb_write_pc;
        else 
            btb_pc_next = btb_pc_next_val;
    end else 
        // bp_curr_state = wnt;
        btb_pc_next = '0;
end

btb_sram         btb_sram(.clk0      (clk),
                    .csb0       (1'b0),
                    .web0       (1'b1),
                    .addr0      (btb_read_idx),
                    .din0       ('0),
                    .dout0      (btb_pc_next_val),
                    .clk1       (clk),
                    .csb1       (1'b0),
                    .web1       (~pc_next_misprediction), //active low
                    .addr1      (btb_write_idx),
                    .din1       (btb_write_pc),
                    .dout1      ());

endmodule : btb