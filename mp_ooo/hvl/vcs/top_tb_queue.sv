// module top_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     int clock_half_period_ps = getenv("ECE411_CLOCK_PERIOD_PS").atoi() / 2;

//     bit clk;
//     always #(clock_half_period_ps) clk = ~clk;

//     bit rst;

//     int timeout = 10000000; // in cycles, change according to your needs

    

//     // bit               rst;

//     logic   [63:0]  wdata;
//     logic           enqueue;

//     logic   [63:0]      rdata;
//     logic               dequeue;

//     logic               full;
//     logic               empty;

//     queue dut(.*);
    
//     task initial_test;
//         assert (full == '0);
//         assert (empty == 1'b1);
//     endtask

//     task enqueue_single;
//         enqueue <= 1'b1;
//         dequeue <= 1'b0;
//         wdata <= 64'd69;
//         @ (posedge clk);
//         enqueue <= 1'b0;
//         wdata <= 'x;
//         #1;
//         assert (full == '0);
//         assert (empty == 1'b0);
//         @ (posedge clk);
//         dequeue <= 1'b1;
//         #1;
//         assert (rdata == 64'd69);
//         @ (posedge clk);
//         dequeue <= 1'b0;
//         #1;
//         assert (full == 1'b0);
//         assert (empty == 1'b1);
//     endtask

//     task queue_full_test;
//         for (int i = 0; i < 5; i++) begin
//             enqueue <= 1'b1;
//             wdata <= i;
//             @ (posedge clk);
//         end

//         enqueue <= 1'b0;
//         wdata <= 'x;
//         #1;
//         assert (full == '1);
//         assert (empty == 1'b0);
//         @ (posedge clk);
       
//     endtask

//     task dequeue_full_test;
//         for (int i = 0; i < 5; i++) begin
//             dequeue <= 1'b1;
//             #1;
//              if (i < 4) assert (rdata == i);
//             @ (posedge clk);
//         end

//         dequeue <= 1'b0;
//         #1;
//         assert (full == '0);
//         assert (empty == 1'b1);
//         @ (posedge clk);
       
//     endtask

//     task circular_test;
//         enqueue <= 1'b0;
//         dequeue <= 1'b0;
//         @ (posedge clk);

//         for (int i = 0; i < 10; i++) begin
//             enqueue <= 1'b1;
//             dequeue <= 1'b0;
//             wdata <= i;

//             @ (posedge clk);
//             wdata <= i;

//             @ (posedge clk);
//             enqueue <= 1'b0;
//             dequeue <= 1'b1;

//             #1;
//             // assert (rdata == i);

//             @ (posedge clk);
//         end

//         dequeue <= 1'b0;
//         enqueue <= 1'b0;

//         // #1;
//         // assert (full == '0);
//         // assert (empty == 1'b1);
//         @ (posedge clk);
       
//     endtask

//     initial begin
//         $fsdbDumpfile("dump.fsdb");
//         $fsdbDumpvars(0, "+all");
//         rst = 1'b1;
//         enqueue = 1'b0;
//         dequeue = 1'b0;
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;

//         initial_test();
//         enqueue_single();
//         queue_full_test();
//         dequeue_full_test();
//         circular_test();

//         $finish;
//     end

// endmodule