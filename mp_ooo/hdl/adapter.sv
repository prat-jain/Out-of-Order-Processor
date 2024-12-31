module adapter
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid,

    input   logic   [31:0]      adapter_addr,
    input   logic               adapter_read,
    input   logic               adapter_write,
    output  logic   [255:0]     adapter_rdata,
    input   logic   [255:0]     adapter_wdata,
    output  logic               adapter_resp
);

    logic       request_from_cache, rw;
    logic   [31:0]  request_addr;
    logic   [191:0] request_wdata;
    logic   [63:0] rdata_buffer [4];
    logic init;

    assign init = (bmem_raddr == '0) ? 1'b1 : 1'b0;

    adapter_state state, next_state;

    always_ff @(posedge clk) begin
        if (rst) begin 
            rw <= 1'b0; 
            request_addr <= '0;
            request_wdata <= '0;
            rdata_buffer[0] <= '0;
            rdata_buffer[1] <= '0;
            rdata_buffer[2] <= '0;
            rdata_buffer[3] <= '0;
            state <= idle;
        end
        else begin
            state <= next_state;

            case (state) 
                idle : begin 
                    request_addr <= adapter_addr;

                    if (adapter_read) 
                        rw <= 1'b0;
                    
                    if (adapter_write) begin 
                        rw <= 1'b1; 
                        request_wdata <= adapter_wdata[255:64];
                    end
                end

                burst_one :  
                    rdata_buffer[0] <= bmem_rdata;

                burst_two :  
                    rdata_buffer[1] <= bmem_rdata;
                
                burst_three :  
                    rdata_buffer[2] <= bmem_rdata;

                burst_four :  
                    rdata_buffer[3] <= bmem_rdata;
            endcase
        end
        
    end 


    always_comb begin : next_state_logic 
        next_state = state;

        //bmem signals
        bmem_read = 1'b0;
        bmem_write = 1'b0;
        bmem_addr = '0;
        bmem_wdata = '0;

        //output/cache signals
        adapter_rdata = '0;
        adapter_resp = '0;

        unique case(state)  
            idle : begin
                if (bmem_ready && (adapter_read || adapter_write)) next_state = burst_one;
                 

                if (adapter_read && bmem_ready) begin 
                    bmem_addr = adapter_addr;
                    bmem_read = 1'b1;
                end 

                if (adapter_write && bmem_ready) begin 
                    bmem_addr = adapter_addr;
                    bmem_write = 1'b1;
                    bmem_wdata = adapter_wdata[63:0];
                end
            end

            burst_one: begin
                if (rw)  begin//write 
                    next_state = burst_two;
                    bmem_wdata = request_wdata[63:0];
                    bmem_addr = request_addr;
                    bmem_write = 1'b1;
                end else begin //read
                    if (bmem_rvalid)  
                        next_state = burst_two;
                end
            end

            burst_two: begin
                next_state = burst_three;

                if (rw) begin//write 
                    bmem_wdata = request_wdata[127:64];
                    bmem_addr = request_addr;
                    bmem_write = 1'b1;
                end 
            end

            burst_three: begin
                next_state = burst_four;

                if (rw)  begin//write 
                    bmem_wdata = request_wdata[191:128];
                    bmem_addr = request_addr;
                    bmem_write = 1'b1;
                end 
            end

            burst_four: begin
                next_state = respond;
                
                if (rw) begin 
                    adapter_resp = 1'b1; // write
                    next_state = idle;
                end
            end

            respond : begin 
                next_state = idle;

                if (~rw) begin
                    adapter_resp = 1'b1;
                    adapter_rdata = {rdata_buffer[3], rdata_buffer[2], rdata_buffer[1], rdata_buffer[0]};
                end
            end

            default : begin 
                bmem_read = 1'b0;
                bmem_write = 1'b0;
                bmem_addr = '0;
                bmem_wdata = '0;

                //output/cache signals
                adapter_rdata = '0;
                adapter_resp = '0;
            end
        endcase
    end

endmodule : adapter
