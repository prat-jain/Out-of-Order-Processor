module stage2
import rv32i_types::*;
(
    input   logic           clk,
    // input   logic           rst,

    input   logic           valid_out[4], 
    input   logic   [255:0] data_out[4],
    input   logic   [23:0]  tag_out[4],
    // input   logic           dirty_bit[4], 
    input   logic    [2:0]  curr_lru,

    input    s1_s2_stage_reg_t   s1_s2_reg, 
    output   logic   [31:0]    old_ufp_addr,        
    output   logic             stall_sig, 
    output   logic    [2:0]    new_lru,
    output   logic    [1:0]    way_evict,

    input   logic   [31:0]  sram_addr[4],
    // input   logic           sram_web[4],

    output   logic             write_stall_sig,

    output  logic   [31:0]  ufp_rdata,
    output  logic           ufp_resp,

    output  logic           plru_we, 

    output   logic   [255:0] write_data,
    output   logic   [1:0]   write_way,
    output   logic   [31:0]  write_mask,
    output   logic           write_stall_sig_next, 

    input   logic           dfp_resp,
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    output  logic   [255:0] dfp_wdata,
    output  logic    [2:0]  write_in_plru,

    output  logic           dirty_flag 
);

lru_encode lru_encode(.*); 

logic prev_dfp_resp_read; 
logic prev_dfp_resp_write;

logic flag; 
logic flopped_flag; 

logic   [31:0]  flopped_sram_addr[4];
logic flopped_resp;
 
always_ff @(posedge clk) begin
    if (dfp_resp && dfp_read)
        prev_dfp_resp_read <= 1'b1; 
    else if (!stall_sig)
        prev_dfp_resp_read <= 1'b0; 
    
    if (dfp_resp && dfp_write)
        prev_dfp_resp_write <= 1'b1; 
    else if (!stall_sig)
        prev_dfp_resp_write <= 1'b0; 
    
    write_stall_sig <= write_stall_sig_next; 
    flopped_flag <= flag;
    flopped_resp <= dfp_resp;
    for (int i = 0; i < 4; i++) begin
        flopped_sram_addr[i] <= sram_addr[i]; 
    end
end

always_comb begin
    write_in_plru = '0;
    dfp_addr = '0; 
    dfp_read = 1'b0; 
    dfp_write = 1'b0; 
    old_ufp_addr = s1_s2_reg.addr; 
    dfp_wdata = '0; 
    flag = 1'b1;

    ufp_resp = 1'b0; 
    ufp_rdata = '0; 
    if (s1_s2_reg.rmask != '0) begin
        if ((tag_out[0][22:0] == s1_s2_reg.addr[31:9]) && valid_out[0]) begin
            ufp_rdata = data_out[0][s1_s2_reg.addr[4:0] * 8 +: 32]; 
            ufp_resp = 1'b1;
            write_in_plru = {1'b0, 1'b0, curr_lru[0]};
        end
        else if ((tag_out[1][22:0] == s1_s2_reg.addr[31:9]) && valid_out[1]) begin
            ufp_rdata = data_out[1][s1_s2_reg.addr[4:0] * 8 +: 32]; 
            ufp_resp = 1'b1;
            write_in_plru = {1'b0, 1'b1, curr_lru[0]};
        end
        else if ((tag_out[2][22:0] == s1_s2_reg.addr[31:9]) && valid_out[2]) begin
            ufp_rdata = data_out[2][s1_s2_reg.addr[4:0] * 8 +: 32];
            ufp_resp = 1'b1; 
            write_in_plru = {1'b1, curr_lru[1], 1'b0};
        end
        else if ((tag_out[3][22:0] == s1_s2_reg.addr[31:9]) && valid_out[3]) begin
            ufp_rdata = data_out[3][s1_s2_reg.addr[4:0] * 8 +: 32]; 
            ufp_resp = 1'b1; 
            write_in_plru = {1'b1, curr_lru[1], 1'b1};
        end
    end

    write_way = 'x; 
    write_data = 'x;
    write_mask = '0; 
    dirty_flag = 1'b0; 

    if (s1_s2_reg.wmask != '0 && !write_stall_sig) begin
        if ((tag_out[0][22:0] == s1_s2_reg.addr[31:9]) && valid_out[0]) begin
            write_way = 2'b00; 
            ufp_resp = 1'b1;
            write_in_plru = {1'b0, 1'b0, curr_lru[0]};
        end
        else if ((tag_out[1][22:0] == s1_s2_reg.addr[31:9]) && valid_out[1]) begin
            write_way = 2'b01; 
            ufp_resp = 1'b1;
            write_in_plru = {1'b0, 1'b1, curr_lru[0]};
        end
        else if ((tag_out[2][22:0] == s1_s2_reg.addr[31:9]) && valid_out[2]) begin
            write_way = 2'b10; 
            ufp_resp = 1'b1; 
            write_in_plru = {1'b1, curr_lru[1], 1'b0};
        end
        else if ((tag_out[3][22:0] == s1_s2_reg.addr[31:9]) && valid_out[3]) begin
            write_way = 2'b11; 
            ufp_resp = 1'b1; 
            write_in_plru = {1'b1, curr_lru[1], 1'b1};
        end

        if (ufp_resp) begin
            if (s1_s2_reg.wmask[0]) begin
                write_data[8 * s1_s2_reg.addr[4:0] +: 8] = s1_s2_reg.wdata[7:0];  
                write_mask[s1_s2_reg.addr[4:0]] = 1'b1; 
            end if (s1_s2_reg.wmask[1]) begin
                write_data[8 * (s1_s2_reg.addr[4:0] + 1) +: 8] = s1_s2_reg.wdata[15:8];  
                write_mask[s1_s2_reg.addr[4:0] + 1] = 1'b1; 
            end if (s1_s2_reg.wmask[2]) begin
                write_data[8 * (s1_s2_reg.addr[4:0] + 2) +: 8] = s1_s2_reg.wdata[23:16]; 
                write_mask[s1_s2_reg.addr[4:0] + 2] = 1'b1;  
            end if (s1_s2_reg.wmask[3]) begin
                write_data[8 * (s1_s2_reg.addr[4:0] + 3) +: 8] = s1_s2_reg.wdata[31:24];  
                write_mask[s1_s2_reg.addr[4:0] + 3] = 1'b1; 
            end
        end
    end

    plru_we = (ufp_resp) ? 1'b0 : 1'b1;
    write_stall_sig_next = (s1_s2_reg.wmask != '0) & ufp_resp; 
    stall_sig = 1'b0; 

    if (!ufp_resp && (s1_s2_reg.rmask != '0)) begin
        stall_sig = 1'b1; 
        if (valid_out[way_evict]) begin 
            if (tag_out[way_evict][23] && !prev_dfp_resp_write) begin
                dirty_flag = 1'b1; 
                dfp_write  = 1'b1; 
                dfp_addr = {tag_out[way_evict][22:0], s1_s2_reg.addr[8:5], 5'b0}; 
                dfp_wdata = data_out[way_evict]; 
            end
        end 
        if (!prev_dfp_resp_read && !dfp_write) begin
            dfp_addr = {s1_s2_reg.addr[31:5], 5'b0}; 
            dfp_read = 1'b1;  
            for (int i = 0; i < 4; i++) begin
                if (dfp_resp || flopped_resp) begin
                    if ((sram_addr[i] & 32'hffffffe0) == dfp_addr || (flopped_sram_addr[i] & 32'hffffffe0) == dfp_addr)  begin
                        flag = 1'b0; 
                    end
                end 
            end
            dfp_read = flag & flopped_flag;
        end
    end

    if (!ufp_resp && (s1_s2_reg.wmask != '0) && !write_stall_sig) begin
        stall_sig = 1'b1; 
        if (valid_out[way_evict]) begin 
            if (tag_out[way_evict][23] && !prev_dfp_resp_write) begin
                dirty_flag = 1'b1; 
                dfp_write  = 1'b1; 
                dfp_addr = {tag_out[way_evict][22:0], s1_s2_reg.addr[8:5], 5'b0}; 
                dfp_wdata = data_out[way_evict]; 
            end
        end 
        if (!prev_dfp_resp_read && !dfp_write) begin
            dfp_addr = {s1_s2_reg.addr[31:5], 5'b0}; 
            dfp_read = 1'b1; 
        end
    end

end

endmodule