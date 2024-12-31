module DW_mult_seq_inst
import rv32i_types::*;
import params::*;
#(
    parameter inst_a_width = 33,
    parameter inst_b_width = 33,
    parameter inst_tc_mode = 1,
    parameter inst_num_cyc = 3,
    parameter inst_rst_mode = 1,
    parameter inst_input_mode = 1,
    parameter inst_output_mode = 1,
    parameter inst_early_start = 0
)
(   
    input logic inst_clk, 
    input logic inst_rst_n, 
    input logic inst_hold, 
    input logic inst_start, 
    input logic [inst_a_width-1 : 0] inst_a,
    input logic [inst_b_width-1 : 0] inst_b, 
    output logic complete_inst, 
    output logic [inst_a_width+inst_b_width-1 : 0] product_inst 
);


// Instance of DW_mult_seq
DW_mult_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
              inst_rst_mode, inst_input_mode, inst_output_mode, inst_early_start)
            U1 (.clk(inst_clk), .rst_n(inst_rst_n), .hold(inst_hold),
                .start(inst_start), .a(inst_a), .b(inst_b),
                .complete(complete_inst), .product(product_inst));

endmodule : DW_mult_seq_inst