module stage1
import rv32i_types::*;
(
     
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,  
    input   logic   [31:0]  ufp_wdata,

    input   logic   [31:0]  old_ufp_addr,

    output  logic   [3:0]   plru_addr, 

    input   logic    [1:0]  way_evict,

    input   logic   [255:0] dfp_rdata,
    input   logic           dfp_resp,

    input   logic   [255:0] write_data,
    input   logic   [1:0]   write_way,
    input   logic   [31:0]  write_mask,

    input   logic           write_stall_sig,
    input   logic           stall_sig,

    input   logic           write_stall_sig_next, 
    output  s1_s2_stage_reg_t s1_s2_reg_next,
    output   logic   [31:0]  sram_addr[4],
    output   logic   [255:0] sram_din0[4],
    output   logic           sram_web[4],
    output   logic   [31:0]  sram_wmask[4],
    output   logic           valid_in[4],
    output   logic           dirty_bit[4],

    input  logic             dirty_flag 
);

logic flag;
assign flag = (write_stall_sig && |s1_s2_reg_next.wmask); 

always_comb begin 
    for (int i = 0; i < 4; i++) begin
        sram_addr[i] = (stall_sig || dfp_resp || flag || write_stall_sig_next) ? old_ufp_addr : ufp_addr; 
        sram_web[i] = 1'b1;
        sram_wmask[i] = 'x; 
        sram_din0[i] = 'x; 
        valid_in[i]  = 1'b0; 
        dirty_bit[i] = 1'b0; 
    end

    plru_addr = old_ufp_addr[8:5];

    s1_s2_reg_next.addr  = ufp_addr; 
    s1_s2_reg_next.rmask = ufp_rmask; 
    s1_s2_reg_next.wmask = ufp_wmask; 
    s1_s2_reg_next.wdata = ufp_wdata; 

    if (dfp_resp && !dirty_flag) begin
        valid_in[way_evict]  = 1'b1; 
        sram_web[way_evict]  = 1'b0;
        sram_wmask[way_evict] =  '1; 
        sram_din0[way_evict] = dfp_rdata;
        // dirty_bit[write_way] = 1'b0; 
    end

    if (dfp_resp) dirty_bit[way_evict] = 1'b0; 

    // if (dfp_resp && dirty_flag) valid_in[way_evict] = 1'b0; 

    if (write_stall_sig_next) begin
        dirty_bit[write_way] = 1'b1; 
        valid_in[write_way]  = 1'b1; 
        sram_web[write_way]  = 1'b0;
        sram_wmask[write_way] = write_mask; 
        sram_din0[write_way] = write_data;
    end

end 

endmodule