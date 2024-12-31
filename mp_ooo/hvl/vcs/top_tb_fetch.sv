// module top_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

//     bit clk;
//     always #(clock_half_period_ps) clk = ~clk;

//     bit rst;

//     int timeout = 10000000; // in cycles, change according to your needs

    

//     // bit               rst;

//     logic   [31:0]      bmem_addr;
//     logic               bmem_read;
//     logic               bmem_write;
//     logic   [63:0]      bmem_wdata;
//     logic               bmem_ready;

//     logic   [31:0]      bmem_raddr;
//     logic   [63:0]      bmem_rdata;
//     logic               bmem_rvalid;

//     logic   [31:0]      adapter_addr;
//     logic               adapter_read;
//     logic               adapter_write;
//     logic   [255:0]     adapter_rdata;
//     logic   [255:0]     adapter_wdata;
//     logic               adapter_resp;

//     adapter dut(.*);
    
//     task initial_test;
//         assert (adapter_resp == '0);
//         assert (bmem_read == '0);
//         assert (bmem_write == '0);
//     endtask

//     task read_single;
//         adapter_read <= 1'b1;
//         adapter_write <= 1'b0;
//         adapter_addr <= 32'heceb;
//         bmem_rvalid <= '0;
//         bmem_raddr <= '0;

//         #1;
//         assert (bmem_read == 1'b1);
//         assert (bmem_addr == 32'heceb);

//         @ (posedge clk);

//         adapter_read <= '0;
//         adapter_addr <= 'x;

//         #1;
//         assert (bmem_addr == '0);
//         assert (bmem_read == '0);

//         repeat (4) @ (posedge clk);

//         bmem_rvalid <= 1'b1;
//         bmem_rdata <= 64'ha;

//         @ (posedge clk);
//         bmem_rdata <= 64'hb;

//         @ (posedge clk);
//         bmem_rdata <= 64'hc;

//         @ (posedge clk);
//         bmem_rdata <= 64'hd;

//         @ (posedge clk);
//         bmem_rvalid <= 1'b0;
//         bmem_rdata <= 'x;
//         adapter_read <= 1'b0;
//         adapter_write <= 1'b0;

//         #1;
//         assert (adapter_resp == 1'b1);
//         assert (adapter_rdata == 256'h000000000000000d000000000000000c000000000000000b000000000000000a);
    
//         @ (posedge clk);

//     endtask

//     task write_single;
//         adapter_read <= 1'b0;
//         adapter_write <= 1'b1;
//         adapter_addr <= 32'heceb;
//         adapter_wdata <= {64'hecebecebecebeceb, 64'h0, 64'hecebecebecebeceb, 64'h1};
//         bmem_rvalid <= '0;
//         bmem_raddr <= '0;

//         #1;
//         assert (bmem_write == 1'b1);
//         assert (bmem_addr == 32'heceb);
//         assert (bmem_wdata == 64'h1);

//         @ (posedge clk);

//         adapter_write <= '0;
//         adapter_addr <= 'x;
//         adapter_wdata <= 'x;

//         #1;
//         assert (bmem_write == 1'b1);
//         assert (bmem_addr == 32'heceb);
//         assert (bmem_wdata == 64'hecebecebecebeceb);

//         @ (posedge clk);

//         #1;
//         assert (bmem_write == 1'b1);
//         assert (bmem_addr == 32'heceb);
//         assert (bmem_wdata == 64'h0);

//         @ (posedge clk);
        
//         #1;
//         assert (bmem_write == 1'b1);
//         assert (bmem_addr == 32'heceb);
//         assert (bmem_wdata == 64'hecebecebecebeceb);
//         @ (posedge clk);
        
//         #1
//         assert (bmem_write == 1'b0);
//         assert (adapter_resp == 1'b1);

//         @ (posedge clk);

//         #1;
//         assert (adapter_resp == 1'b0);
    
//         repeat (4) @ (posedge clk);

//     endtask

    
//     initial begin
//         $fsdbDumpfile("dump.fsdb");
//         $fsdbDumpvars(0, "+all");
//         rst = 1'b1;
//         adapter_read = '0;
//         adapter_write = '0;
//         bmem_rvalid = '0;
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;

//         initial_test();
//         read_single();
//         write_single();

//         $finish;
//     end

// endmodule