// module top_tb;

// timeunit 1000ps;
// timeprecision 1000ps;


// bit clk, rst;

// int clock_half_period = 5;

// initial begin
//     clk = '0;
//     forever #(clock_half_period) clk = ~clk;
// end

// logic   [31:0]      adapter_addr;
// logic               adapter_read;
// logic               adapter_write;
// logic   [255:0]     adapter_rdata;
// logic   [255:0]     adapter_wdata;
// logic               adapter_resp;
// logic   [31:0]      icache_dfp_addr;
// logic               icache_dfp_read; 
// logic               icache_dfp_write; 
// logic               icache_dfp_resp;
// logic   [255:0]     icache_dfp_rdata; 
// logic   [255:0]     icache_dfp_wdata;
// logic   [31:0]      dcache_dfp_addr;
// logic               dcache_dfp_read; 
// logic               dcache_dfp_write; 
// logic               dcache_dfp_resp;
// logic   [255:0]     dcache_dfp_rdata; 
// logic   [255:0]     dcache_dfp_wdata;
// logic               arbiter;

// cacheline_arbiter dut(.*);

// assign adapter_rdata = '1;
// assign icache_dfp_addr = 32'd1;
// assign dcache_dfp_addr = 32'd2;

// property both_caches_req_arbiter;
//     @(posedge clk) disable iff (rst)
//     icache_dfp_read && dcache_dfp_read && arbiter && adapter_resp |=> (adapter_addr == 32'd1);
// endproperty

// property both_caches_req_not_arbiter;
//     @(posedge clk) disable iff (rst)
//     icache_dfp_read && dcache_dfp_read && !arbiter && adapter_resp |=> (adapter_addr == 32'd2);
// endproperty

// property i_cache_req;
//     @(posedge clk) disable iff (rst)
//     (icache_dfp_read && !dcache_dfp_read) |-> (adapter_addr == 32'd1);
// endproperty

// property d_cache_req;
//     @(posedge clk) disable iff (rst)
//     (dcache_dfp_read && !icache_dfp_read) |-> (adapter_addr == 32'd2);
// endproperty

// property adapter_resp_come;
//     @(posedge clk) disable iff (rst)
//     $rose(adapter_read) |-> ##[3:5](adapter_resp); 
// endproperty

// property_a: assert property (both_caches_req_arbiter)     else $fatal("not working1");
// property_b: assert property (both_caches_req_not_arbiter) else $fatal("not working2");
// property_c: assert property (i_cache_req)                 else $fatal("not working3");
// property_d: assert property (d_cache_req)                 else $fatal("not working4");
// property_e: assert property (adapter_resp_come)           else $fatal("not working5");

// task produce_requests;
//     for(int i = 0; i < 1000; ++i) begin
//         icache_dfp_read <= 1'b1;
//         dcache_dfp_read <= 1'b1;

//         repeat (4) @(posedge clk);

//         adapter_resp <= 1'b1; 
//         #1;
//         assert (icache_dfp_resp == !arbiter);
//         assert (dcache_dfp_resp == arbiter);
//         @(posedge clk); 
//         adapter_resp <= 1'b0; 

//     end
// endtask;

// initial begin
//     icache_dfp_read <= 1'b0;
//     dcache_dfp_read <= 1'b0;

//     icache_dfp_write <= 1'b0;
//     dcache_dfp_write <= 1'b0;

//     adapter_resp <= 1'b0;

//     $fsdbDumpfile("dump.fsdb");
//     $fsdbDumpvars(0, "+all");

//     rst = 1'b1;
//     repeat(2) @(posedge clk);
//     rst <= '0;
//     @(posedge clk);
    
//     // icache_dfp_read <= 1'b1;
//     // dcache_dfp_read <= 1'b1;

//     // repeat (4) @(posedge clk);

//     // adapter_resp <= 1'b1; 

//     // #1;
//     // assert (icache_dfp_resp == 1'b1);
//     // assert (dcache_dfp_resp == 1'b0);

//     // @ (posedge clk) 
//     // adapter_resp <= 1'b0;

//     // repeat (4) @ (posedge clk);

//     // adapter_resp <= 1'b1;

//     // #1
//     // assert (icache_dfp_resp == 1'b0);
//     // assert (dcache_dfp_resp == 1'b1);

//     // @ (posedge clk);
//     // adapter_resp <= 1'b0;

//     produce_requests();    

//     $finish;

// end

// endmodule 