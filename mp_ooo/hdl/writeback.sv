module writeback
import rv32i_types::*;
(
    // input   logic               clk,
    // input   logic               rst,

    // connections to functional units
    input execution_out_t  alu_execution_val,
    input execution_out_t  mul_execution_val,   
    input execution_out_t  div_execution_val,   
    input logic             alu_wb_valid,                
    input logic             mul_wb_valid,   
    input logic             div_wb_valid, 

    // connections to common data bus
    output  CDB_t           alu_cdb,
    output  CDB_t           mul_cdb,
    output  CDB_t           div_cdb

);

    always_comb begin 
        alu_cdb = alu_wb_valid ? alu_execution_val : '0;
        mul_cdb = mul_wb_valid ? mul_execution_val : '0;
        div_cdb = div_wb_valid ? div_execution_val : '0;
    end

endmodule : writeback