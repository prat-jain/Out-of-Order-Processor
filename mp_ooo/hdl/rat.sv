module rat
import rv32i_types::*;
import params::*;
(
    input   logic           clk,
    input   logic           rst,

    // connections to decode
    input   logic                   rat_we,
    input   logic   [PR_WIDTH-1:0]  pd,
    input   logic   [AR_WIDTH-1:0]  rs1, rs2, rd,
    output  logic   [PR_WIDTH-1:0]  ps1, ps2,
    output  logic                   ps1_valid, ps2_valid,
    // output  logic   [PR_WIDTH-1:0]  discarded_pd,

    // connections to common data bus
    input   logic   [PR_WIDTH-1:0]  alu_cdb_pd,
    input   logic   [AR_WIDTH-1:0]  alu_cdb_rd,
    input   logic                   alu_cdb_regf_we,

    input   logic   [PR_WIDTH-1:0]  mul_cdb_pd,
    input   logic   [AR_WIDTH-1:0]  mul_cdb_rd,
    input   logic                   mul_cdb_regf_we,

    input   logic   [PR_WIDTH-1:0]  div_cdb_pd,
    input   logic   [AR_WIDTH-1:0]  div_cdb_rd,
    input   logic                   div_cdb_regf_we,

    input   logic   [PR_WIDTH-1:0]  load_cdb_pd,
    input   logic   [AR_WIDTH-1:0]  load_cdb_rd,
    input   logic                   load_cdb_regf_we,

    input   logic                   flush,

    input   logic   [PR_WIDTH-1:0]  rrf_rdata[32]
);

    logic   [PR_WIDTH-1:0]  phys_reg_map [32];
    logic                   phys_reg_valid [32];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                phys_reg_map[i] <= unsigned'(6'(i));
                phys_reg_valid[i] <= 1'b1;
            end 
        end else if (flush) begin 
            for (int i = 0; i < 32; i++) begin
                phys_reg_map[i] <= rrf_rdata[i];
                phys_reg_valid[i] <= 1'b1;
            end
        end else begin
           
            if (alu_cdb_regf_we) 
                if (phys_reg_map[alu_cdb_rd] == alu_cdb_pd) phys_reg_valid[alu_cdb_rd] <= 1'b1;
            

            if (mul_cdb_regf_we) 
                if (phys_reg_map[mul_cdb_rd] == mul_cdb_pd) phys_reg_valid[mul_cdb_rd] <= 1'b1;
            

            if (div_cdb_regf_we) 
                if (phys_reg_map[div_cdb_rd] == div_cdb_pd) phys_reg_valid[div_cdb_rd] <= 1'b1;

            if (load_cdb_regf_we) 
                if (phys_reg_map[load_cdb_rd] == load_cdb_pd) phys_reg_valid[load_cdb_rd] <= 1'b1;
                
       
            if (rat_we && rd != '0) begin
                phys_reg_map[rd] <= pd;
                phys_reg_valid[rd] <= 1'b0;
            end  
                
            
        end
    end

    // assign discarded_pd = (rd != '0) ? phys_reg_map[rd] : '0;

    always_comb begin
        if (rst) begin
            ps1 = 'x;
            ps2 = 'x;
            ps1_valid = 'x;
            ps2_valid = 'x;
        end else begin
            ps1 = phys_reg_map[rs1];
            ps2 = phys_reg_map[rs2];

            if ((alu_cdb_regf_we && (alu_cdb_rd == rs1) && (alu_cdb_pd == ps1)) || (mul_cdb_regf_we && (mul_cdb_rd == rs1) && (mul_cdb_pd == ps1)) || (div_cdb_regf_we && (div_cdb_rd == rs1) && (div_cdb_pd == ps1)) || (load_cdb_regf_we && (load_cdb_rd == rs1) && (load_cdb_pd == ps1))) 
                ps1_valid = 1'b1;
            else ps1_valid = (rs1 == '0)  ? 1'b1 : phys_reg_valid[rs1];

            if ((alu_cdb_regf_we && (alu_cdb_rd == rs2) && (alu_cdb_pd == ps2)) || (mul_cdb_regf_we && (mul_cdb_rd == rs2) && (mul_cdb_pd == ps2)) || (div_cdb_regf_we && (div_cdb_rd == rs2) && (div_cdb_pd == ps2)) || (load_cdb_regf_we && (load_cdb_rd == rs2) && (load_cdb_pd == ps2))) 
                ps2_valid = 1'b1;
            else ps2_valid = (rs2 == '0)  ? 1'b1 : phys_reg_valid[rs2];
          
        end
    end

endmodule : rat
