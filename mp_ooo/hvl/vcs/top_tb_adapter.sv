// import "DPI-C" function string getenv(input string env_name);


// module top_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

//     bit clk;
//     always #(clock_half_period_ps) clk = ~clk;

//     bit rst;

//     int timeout = 10000000; // in cycles, change according to your needs

//     mem_itf_banked bmem_itf(.*);
//     banked_memory banked_memory(.itf(bmem_itf));

//     mon_itf #(.CHANNELS(8)) mon_itf(.*);
//     monitor #(.CHANNELS(8)) monitor(.itf(mon_itf));

//     logic   [31:0]      adapter_addr;
//     logic               adapter_read;
//     logic               adapter_write;
//     logic   [255:0]     adapter_rdata;
//     logic   [255:0]     adapter_wdata;
//     logic               adapter_resp;

//     adapter dut(.*, .bmem_addr(bmem_itf.addr), .bmem_read(bmem_itf.read), .bmem_write(bmem_itf.write),
//                 .bmem_wdata(bmem_itf.wdata), .bmem_ready(bmem_itf.ready), .bmem_raddr(bmem_itf.raddr),
//                 .bmem_rdata(bmem_itf.rdata), .bmem_rvalid(bmem_itf.rvalid));
    
//     task initial_test;
//         assert (adapter_resp == '0);
//         assert (bmem_itf.read == '0);
//         assert (bmem_itf.write == '0);
//     endtask

//     task read_single;
//         adapter_read <= 1'b1;
//         adapter_write <= 1'b0;
//         adapter_addr <= 32'h1eceb000;

//         #1;
//         assert (bmem_itf.read == 1'b1);
//         assert (bmem_itf.addr == 32'h1eceb000);

//         @ (posedge clk);

//         adapter_read <= '0;
//         adapter_addr <= 'x;

//         #1;
//         assert (bmem_itf.addr == '0);
//         assert (bmem_itf.read == '0);

//         @ (posedge clk);
//         adapter_read <= 1'b0;
//         adapter_write <= 1'b0;

//         #1;
//         // assert (adapter_resp == 1'b1);
//         // assert (adapter_rdata == 256'h000000000000000d000000000000000c000000000000000b000000000000000a);
    
//         repeat(10) @ (posedge clk);

//     endtask

//     task write_single;
//         adapter_read <= 1'b0;
//         adapter_write <= 1'b1;
//         adapter_addr <= 32'h1eceb000;
//         adapter_wdata <= {64'hecebecebecebeceb, 64'h0, 64'hecebecebecebeceb, 64'h1};

//         #1;
//         assert (bmem_itf.write == 1'b1);
//         assert (bmem_itf.addr == 32'h1eceb000);
//         assert (bmem_itf.wdata == 64'h1);

//         @ (posedge clk);

//         adapter_write <= '0;
//         adapter_addr <= 'x;
//         adapter_wdata <= 'x;

//         #1;
//         assert (bmem_itf.write == 1'b1);
//         assert (bmem_itf.addr == 32'h1eceb000);
//         assert (bmem_itf.wdata == 64'hecebecebecebeceb);

//         @ (posedge clk);

//         #1;
//         assert (bmem_itf.write == 1'b1);
//         assert (bmem_itf.addr == 32'h1eceb000);
//         assert (bmem_itf.wdata == 64'h0);

//         @ (posedge clk);
        
//         #1;
//         assert (bmem_itf.write == 1'b1);
//         assert (bmem_itf.addr == 32'h1eceb000);
//         assert (bmem_itf.wdata == 64'hecebecebecebeceb);
//         @ (posedge clk);
        
//         #1
//         assert (bmem_itf.write == 1'b0);
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
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;

//         initial_test();
//         read_single();
//         write_single();
//         read_single();

//         $finish;
//     end

// endmodule