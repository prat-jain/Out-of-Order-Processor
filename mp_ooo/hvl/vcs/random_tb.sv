//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types::*;
(
    mem_itf_banked.mem itf
);

    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();

    logic reading;
    task run_random_instrs();
        
        repeat (10000) begin
            @(posedge itf.clk iff (|itf.read || |itf.write));
            reading <= 1'b0;
            // Always read out a valid instruction.
            for(int i = 0; i < 4; i++) begin 
                if ((itf.read != '0) && (i == '0)) begin
                    reading <= 1'b1;
                    gen.randomize();
                    itf.rdata[31:0] <= gen.instr.word;
                    itf.rvalid <= 1'b1;
                    gen.randomize();
                    itf.rdata[63:32] <= gen.instr.word;
                    @(posedge itf.clk);
                end else if (reading) begin
                    gen.randomize();
                    itf.rdata[31:0] <= gen.instr.word;
                    itf.rvalid <= 1'b1;
                    gen.randomize();
                    itf.rdata[63:32] <= gen.instr.word;
                    @(posedge itf.clk);                
                end
            end
            @(posedge itf.clk) itf.rvalid <= 1'b0;
        end
    endtask : run_random_instrs


    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read) || $isunknown(itf.write)) begin
            $error("Memory Error: mask containes 1'bx");
            itf.error <= 1'b1;
        end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr[0])) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            if (itf.addr[0] != 1'b0) begin
                $error("Memory Error: Address is not 16-bit aligned");
                itf.error <= 1'b1;
            end
        end
    end

    // A single initial block ensures random stability.
    initial begin

        // Wait for reset.
        @(posedge itf.clk iff itf.rst == 1'b0);

        // Run!
        itf.ready <= 1'b1;
        run_random_instrs();

        // Finish up
        $display("Random testbench finished!");
        $finish;
    end

endmodule : random_tb