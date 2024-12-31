module cache 
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    logic   [255:0] data_out[4];
    logic   [23:0]  tag_out[4];
    logic           valid_out[4];
    logic           valid_in[4];
    logic           dirty_bit[4]; 
    logic   [31:0]  sram_addr[4];
    logic   [255:0] sram_din0[4]; 
    logic           sram_web[4]; 
    logic   [31:0]  sram_wmask[4]; 

    logic    [2:0]  curr_lru;
    logic    [2:0]  new_lru;
    logic    [1:0]  way_evict; 

    logic    [2:0]  unused_lru_out_w; 

    logic           stall_sig;
    logic           write_stall_sig; 
    logic           write_stall_sig_next;
    logic   [31:0]  old_ufp_addr;

    logic   [255:0] write_data;
    logic   [1:0]   write_way;
    logic   [31:0]  write_mask;

    logic           plru_we; 
    logic   [3:0]   plru_addr; 
    logic   [2:0]   write_in_plru; 

    logic           dirty_flag; 

    // always_comb begin
    //     for (int i = 0; i < 4; i++) begin
    //         dirty_bit[i] = 'x; 
    //     end
    //     dfp_wdata = '0; 
    // end

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (sram_web[i]),
            .wmask0     (sram_wmask[i]),
            .addr0      (sram_addr[i][8:5]),
            .din0       (sram_din0[i]),
            .dout0      (data_out[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (sram_web[i]),
            .addr0      (sram_addr[i][8:5]),
            .din0       ({dirty_bit[i], sram_addr[i][31:9]}),
            .dout0      (tag_out[i])
        );
        valid_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (sram_web[i]),
            .addr0      (sram_addr[i][8:5]),
            .din0       (valid_in[i]),
            .dout0      (valid_out[i])
        );
    end endgenerate

    lru_array lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (1'b1),
        .addr0      (sram_addr[0][8:5]),
        .din0       ('0),
        .dout0      (curr_lru),
        .csb1       (1'b0),
        .web1       (plru_we),
        .addr1      (plru_addr),
        .din1       (write_in_plru),
        .dout1      (unused_lru_out_w)
    );

    s1_s2_stage_reg_t s1_s2_reg, s1_s2_reg_next;

    stage1 stage1 (.*); 
    stage2 stage2 (.*); 

    always_ff @(posedge clk) begin
        if (rst) begin
            s1_s2_reg  <= '0;
        end else if (!(stall_sig || dfp_resp || (write_stall_sig && |s1_s2_reg_next.wmask))) begin
            s1_s2_reg  <= s1_s2_reg_next;
        end
    end

endmodule
