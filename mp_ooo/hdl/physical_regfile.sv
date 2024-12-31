module regfile
(
    input   logic           clk,
    input   logic           rst,


    // connections to common data bus
    input   logic           alu_regf_we,
    input   logic   [31:0]  alu_pv,
    input   logic   [5:0]   alu_pd,

    input   logic           mul_regf_we,
    input   logic   [31:0]  mul_pv,
    input   logic   [5:0]   mul_pd,

    input   logic           div_regf_we,
    input   logic   [31:0]  div_pv,
    input   logic   [5:0]   div_pd,

    input   logic           ls_regf_we,
    input   logic   [31:0]  ls_pv,
    input   logic   [5:0]   ls_pd,

    // connections to reservation station
    input   logic   [5:0]   ps1_alu, ps2_alu, 
    input   logic   [5:0]   ps1_mul, ps2_mul, 
    input   logic   [5:0]   ps1_div, ps2_div, 

    // connections to load queue
    input  logic   [5:0]    ps1_ls,
    input  logic   [5:0]    ps2_ls,

    output   logic   [31:0] ps1_v_ls,
    output   logic   [31:0] ps2_v_ls,

    // connections to store queue
    input  logic   [5:0]    ps1_st,
    input  logic   [5:0]    ps2_st,

    output   logic   [31:0] ps1_v_st,
    output   logic   [31:0] ps2_v_st,

    // for store address calculation
    input    logic   [5:0]    ps1_st_addr1,
    input    logic   [5:0]    ps1_st_addr2,
    input    logic   [5:0]    ps1_st_addr3,
    input    logic   [5:0]    ps1_st_addr4,
    output   logic   [31:0] ps1_v_st_addr1,
    output   logic   [31:0] ps1_v_st_addr2,
    output   logic   [31:0] ps1_v_st_addr3,
    output   logic   [31:0] ps1_v_st_addr4,

    input    logic   [5:0]    ps2_st_addr1,
    input    logic   [5:0]    ps2_st_addr2,
    input    logic   [5:0]    ps2_st_addr3,
    input    logic   [5:0]    ps2_st_addr4,
    output   logic   [31:0] ps2_v_st_addr1,
    output   logic   [31:0] ps2_v_st_addr2,
    output   logic   [31:0] ps2_v_st_addr3,
    output   logic   [31:0] ps2_v_st_addr4,

    input logic   [5:0]    ps1_ld_addr1,
    input logic   [5:0]    ps1_ld_addr2,
    input logic   [5:0]    ps1_ld_addr3,
    input logic   [5:0]    ps1_ld_addr4,
    output  logic   [31:0] ps1_v_ld_addr1,
    output  logic   [31:0] ps1_v_ld_addr2,
    output  logic   [31:0] ps1_v_ld_addr3,
    output  logic   [31:0] ps1_v_ld_addr4,

    // connections to functional units
    output  logic   [31:0]  ps1_v_alu, ps2_v_alu,
    output  logic   [31:0]  ps1_v_mul, ps2_v_mul,
    output  logic   [31:0]  ps1_v_div, ps2_v_div,

    //connections to rrf (for rvfi)
    input   logic   [5:0]   commit_ps1, commit_ps2, commit_pd,
    output  logic   [31:0]  commit_ps1_v, commit_ps2_v, commit_pd_v,

    input   logic               valid_front

);
// add connections to load store queue and handle forwarding 

    logic  [31:0]  data [64];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 64; i++) begin
                data[i] <= '0;
            end
        end else begin 
            if (alu_regf_we && (alu_pd != 6'd0)) begin
                data[alu_pd] <= alu_pv;
            end

            if (mul_regf_we && (mul_pd != 6'd0)) begin
                data[mul_pd] <= mul_pv;
            end

            if (div_regf_we && (div_pd != 6'd0)) begin
                data[div_pd] <= div_pv;
            end

              if (ls_regf_we && (ls_pd != 6'd0)) begin
                data[ls_pd] <= ls_pv;
            end
        end
    end

    always_comb begin
        if (rst) begin
            ps1_v_alu = 'x;
            ps2_v_alu = 'x;
            ps1_v_mul = 'x;
            ps2_v_mul = 'x;
            ps1_v_div = 'x;
            ps2_v_div = 'x;
            ps1_v_ls = 'x;
            ps2_v_ls = 'x;
            ps1_v_st = 'x;
            ps2_v_st = 'x;

            ps1_v_st_addr1 = 'x; 
            ps1_v_st_addr2 = 'x; 
            ps1_v_st_addr3 = 'x; 
            ps1_v_st_addr4 = 'x; 

            ps2_v_st_addr1 = 'x; 
            ps2_v_st_addr2 = 'x; 
            ps2_v_st_addr3 = 'x; 
            ps2_v_st_addr4 = 'x; 

            ps1_v_ld_addr1 = 'x; 
            ps1_v_ld_addr2 = 'x; 
            ps1_v_ld_addr3 = 'x; 
            ps1_v_ld_addr4 = 'x; 

            commit_ps1_v = '0;
            commit_ps2_v = '0;
            commit_pd_v = '0;

        end else begin
            ps1_v_alu = (ps1_alu != 6'd0) ? data[ps1_alu] : '0;
            ps2_v_alu = (ps2_alu != 6'd0) ? data[ps2_alu] : '0;

            ps1_v_mul = (ps1_mul != 6'd0) ? data[ps1_mul] : '0;
            ps2_v_mul = (ps2_mul != 6'd0) ? data[ps2_mul] : '0;

            ps1_v_div = (ps1_div != 6'd0) ? data[ps1_div] : '0;
            ps2_v_div = (ps2_div != 6'd0) ? data[ps2_div] : '0;

            ps1_v_alu = (ps1_alu != 6'd0) ? data[ps1_alu] : '0;
            ps2_v_alu = (ps2_alu != 6'd0) ? data[ps2_alu] : '0;

            ps1_v_ls = (ps1_ls != 6'd0) ? data[ps1_ls] : '0;
            ps2_v_ls = (ps2_ls != 6'd0) ? data[ps2_ls] : '0;

            ps1_v_st = (ps1_st != 6'd0) ? data[ps1_st] : '0;
            ps2_v_st = (ps2_st != 6'd0) ? data[ps2_st] : '0;

            ps1_v_st_addr1 = (ps1_st_addr1 != 6'd0) ? data[ps1_st_addr1] : '0; 
            ps1_v_st_addr2 = (ps1_st_addr2 != 6'd0) ? data[ps1_st_addr2] : '0; 
            ps1_v_st_addr3 = (ps1_st_addr3 != 6'd0) ? data[ps1_st_addr3] : '0; 
            ps1_v_st_addr4 = (ps1_st_addr4 != 6'd0) ? data[ps1_st_addr4] : '0; 

            ps2_v_st_addr1 = (ps2_st_addr1 != 6'd0) ? data[ps2_st_addr1] : '0; 
            ps2_v_st_addr2 = (ps2_st_addr2 != 6'd0) ? data[ps2_st_addr2] : '0; 
            ps2_v_st_addr3 = (ps2_st_addr3 != 6'd0) ? data[ps2_st_addr3] : '0; 
            ps2_v_st_addr4 = (ps2_st_addr4 != 6'd0) ? data[ps2_st_addr4] : '0; 

            ps1_v_ld_addr1 = (ps1_ld_addr1 != 6'd0) ? data[ps1_ld_addr1] : '0; 
            ps1_v_ld_addr2 = (ps1_ld_addr2 != 6'd0) ? data[ps1_ld_addr2] : '0; 
            ps1_v_ld_addr3 = (ps1_ld_addr3 != 6'd0) ? data[ps1_ld_addr3] : '0; 
            ps1_v_ld_addr4 = (ps1_ld_addr4 != 6'd0) ? data[ps1_ld_addr4] : '0; 

            commit_ps1_v = (valid_front) ? data[commit_ps1] : '0;
            commit_ps2_v = (valid_front) ? data[commit_ps2] : '0;
            commit_pd_v = (valid_front) ? data[commit_pd] : '0;

            //forwarding to alu reads
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_alu)  ps1_v_alu = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_alu)  ps2_v_alu = alu_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_alu)  ps1_v_alu = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_alu)  ps2_v_alu = mul_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_alu)  ps1_v_alu = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_alu)  ps2_v_alu = div_pv;

            //forwarding to mul reads
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_mul)  ps1_v_mul = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_mul)  ps2_v_mul = alu_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_mul)  ps1_v_mul = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_mul)  ps2_v_mul = mul_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_mul)  ps1_v_mul = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_mul)  ps2_v_mul = div_pv;

            //forwarding to div reads
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_div)  ps1_v_div = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_div)  ps2_v_div = alu_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_div)  ps1_v_div = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_div)  ps2_v_div = mul_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_div)  ps1_v_div = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_div)  ps2_v_div = div_pv;
            
            //forwarding to load reads
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_ls)  ps1_v_ls = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_ls)  ps2_v_ls = alu_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_ls)  ps1_v_ls = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_ls)  ps2_v_ls = mul_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_ls)  ps1_v_ls = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_ls)  ps2_v_ls = div_pv;

            //forwarding to store reads
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_st)  ps1_v_st = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_st)  ps2_v_st = alu_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_st)  ps1_v_st = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_st)  ps2_v_st = mul_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_st)  ps1_v_st = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_st)  ps2_v_st = div_pv;

            //forwarding for store address calculations
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_st_addr1)  ps1_v_st_addr1 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_st_addr2)  ps1_v_st_addr2 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_st_addr3)  ps1_v_st_addr3 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_st_addr4)  ps1_v_st_addr4 = alu_pv;

            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_st_addr1)  ps1_v_st_addr1 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_st_addr2)  ps1_v_st_addr2 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_st_addr3)  ps1_v_st_addr3 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_st_addr4)  ps1_v_st_addr4 = mul_pv;

            if(div_regf_we && div_pd != '0 && div_pd == ps1_st_addr1)  ps1_v_st_addr1 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_st_addr2)  ps1_v_st_addr2 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_st_addr3)  ps1_v_st_addr3 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_st_addr4)  ps1_v_st_addr4 = div_pv;

            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_st_addr1)  ps2_v_st_addr1 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_st_addr2)  ps2_v_st_addr2 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_st_addr3)  ps2_v_st_addr3 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps2_st_addr4)  ps2_v_st_addr4 = alu_pv;

            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_st_addr1)  ps2_v_st_addr1 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_st_addr2)  ps2_v_st_addr2 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_st_addr3)  ps2_v_st_addr3 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps2_st_addr4)  ps2_v_st_addr4 = mul_pv;

            if(div_regf_we && div_pd != '0 && div_pd == ps2_st_addr1)  ps2_v_st_addr1 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_st_addr2)  ps2_v_st_addr2 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_st_addr3)  ps2_v_st_addr3 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps2_st_addr4)  ps2_v_st_addr4 = div_pv;

            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_ld_addr1)  ps1_v_ld_addr1 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_ld_addr2)  ps1_v_ld_addr2 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_ld_addr3)  ps1_v_ld_addr3 = alu_pv;
            if(alu_regf_we && alu_pd != '0 && alu_pd == ps1_ld_addr4)  ps1_v_ld_addr4 = alu_pv;
            
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_ld_addr1)  ps1_v_ld_addr1 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_ld_addr2)  ps1_v_ld_addr2 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_ld_addr3)  ps1_v_ld_addr3 = mul_pv;
            if(mul_regf_we && mul_pd != '0 && mul_pd == ps1_ld_addr4)  ps1_v_ld_addr4 = mul_pv;

            if(div_regf_we && div_pd != '0 && div_pd == ps1_ld_addr1)  ps1_v_ld_addr1 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_ld_addr2)  ps1_v_ld_addr2 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_ld_addr3)  ps1_v_ld_addr3 = div_pv;
            if(div_regf_we && div_pd != '0 && div_pd == ps1_ld_addr4)  ps1_v_ld_addr4 = div_pv;

        end
    end

endmodule : regfile