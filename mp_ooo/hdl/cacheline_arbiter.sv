module cacheline_arbiter
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to cacheline adapter
    output   logic   [31:0]      adapter_addr,
    output   logic               adapter_read,
    output   logic               adapter_write,
    input    logic   [255:0]     adapter_rdata,
    output   logic   [255:0]     adapter_wdata,
    input    logic               adapter_resp,

    // connections to icache
    input   logic   [31:0]      icache_dfp_addr,
    input   logic               icache_dfp_read, 
    input   logic               icache_dfp_write, 
    output  logic               icache_dfp_resp,
    output  logic   [255:0]     icache_dfp_rdata, 
    input   logic   [255:0]     icache_dfp_wdata,

    // connections to dcache
    input   logic   [31:0]      dcache_dfp_addr,
    input   logic               dcache_dfp_read, 
    input   logic               dcache_dfp_write, 
    output  logic               dcache_dfp_resp,
    output  logic   [255:0]     dcache_dfp_rdata, 
    input   logic   [255:0]     dcache_dfp_wdata

    // input   logic               flush

);


    logic   arbiter; //0 for icache and 1 for dcache 
    logic   icache_req, dcache_req, waiting;

    assign icache_req = icache_dfp_read || icache_dfp_write; 
    assign dcache_req = dcache_dfp_read || dcache_dfp_write;

    always_ff @(posedge clk) begin 
        if (rst) begin 
            arbiter <= 1'b0;
            waiting <= 1'b0;
        end  else begin 
            if (~waiting && icache_req && dcache_req) begin 
                arbiter <= ~arbiter;
                waiting <= 1'b1; 
                end
            else if (~waiting && icache_req) begin 
                arbiter <= 1'b0;
                waiting <= 1'b1;  
                end
            else if (~waiting && dcache_req) begin 
                arbiter <= 1'b1;
                waiting <= 1'b1;  
            end

            if (adapter_resp) waiting <= 1'b0;
        end 
    end

    always_comb begin 
        if (waiting && ~arbiter) begin 
            adapter_addr = icache_dfp_addr;
            adapter_read = icache_dfp_read;
            adapter_write = icache_dfp_write;
            adapter_wdata = icache_dfp_wdata;
        end else if (waiting && arbiter) begin 
            adapter_addr = dcache_dfp_addr;
            adapter_read = dcache_dfp_read;
            adapter_write = dcache_dfp_write;
            adapter_wdata = dcache_dfp_wdata;
        end else if (icache_req && dcache_req) begin // both req incoming, choose opp of what arbiter says
            adapter_addr = ~arbiter ? dcache_dfp_addr : icache_dfp_addr;
            adapter_read = ~arbiter ? dcache_dfp_read : icache_dfp_read;
            adapter_write = ~arbiter ? dcache_dfp_write : icache_dfp_write;
            adapter_wdata = ~arbiter ? dcache_dfp_wdata : icache_dfp_wdata;
        end else if (icache_req) begin //pass through
            adapter_addr = icache_dfp_addr;
            adapter_read = icache_dfp_read;
            adapter_write = icache_dfp_write;
            adapter_wdata = icache_dfp_wdata;
        end else if (dcache_req) begin //pass through
            adapter_addr = dcache_dfp_addr;
            adapter_read = dcache_dfp_read;
            adapter_write = dcache_dfp_write;
            adapter_wdata = dcache_dfp_wdata;
        end else begin 
            adapter_addr = '0;
            adapter_read = '0;
            adapter_write = '0;
            adapter_wdata = '0;
        end
    end

    always_comb begin 
        icache_dfp_resp = arbiter ? '0 : adapter_resp;
        icache_dfp_rdata = arbiter ? '0 : adapter_rdata;
        dcache_dfp_resp = arbiter ? adapter_resp: '0;
        dcache_dfp_rdata = arbiter ? adapter_rdata : '0;
    end

endmodule : cacheline_arbiter
