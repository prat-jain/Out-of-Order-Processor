module execute
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to reservation station
    input  res_station_entry_t     instr_execution_alu,
    input  res_station_entry_t     instr_execution_mul,
    input  res_station_entry_t     instr_execution_div,

    input   logic incoming_alu,
    input   logic incoming_mul,
    input   logic incoming_div,

    output  logic alu_ready,
    output  logic mul_ready,
    output  logic div_ready,

    
    // connections to phys reg file
    input  logic   [31:0]  ps1_v_alu, ps2_v_alu,
    input  logic   [31:0]  ps1_v_mul, ps2_v_mul,
    input  logic   [31:0]  ps1_v_div, ps2_v_div,

    //connections to writeback
    output  logic alu_wb_valid, 
    output  logic mul_wb_valid, 
    output  logic div_wb_valid, 
    output execution_out_t  alu_execution_val,
    output execution_out_t  mul_execution_val,
    output execution_out_t  div_execution_val,

    input   flush

    //connections to history table
    // output   logic   [$clog2(PHT_DEPTH)-1:0]  write_idx,
    // output   logic   [$clog2(LHT_DEPTH)-1:0]  gshare_write_idx,
    // output   logic                           branch_we,
    // output   logic                           branch_taken,
    // output   bp_state_t                      bp_prev_state,
    // output   logic  [$clog2(LHT_DEPTH)-1:0]  prev_pattern,

    // // input   logic   [$clog2(LHT_DEPTH)-1:0] ghr,

    // // connections to tournament
    // output  logic                   misprediction,
    // output  logic                   predictor_used

    //connections to btb
    // output  logic                   pc_next_misprediction,
    // output  logic   [31:0]          btb_write_pc,
    // output  logic   [$clog2(BTB_DEPTH)-1:0] btb_write_idx

    // input   logic   [$clog2(LHT_DEPTH)-1:0] curr_pattern

    
);

    //ALU LOGIC
    res_station_entry_t pp_instr_execution_alu; 
    logic           incoming_alu_latch;
    logic   [31:0]  ps1_v_alu_latch, ps2_v_alu_latch;
    logic   [31:0]  pcp_4, pcp_offset;

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            pp_instr_execution_alu <= '0; 
            incoming_alu_latch <= '0;
            ps1_v_alu_latch <= '0;
            ps2_v_alu_latch <= '0;
        end else begin
            pp_instr_execution_alu <= instr_execution_alu; 
            incoming_alu_latch <= incoming_alu;
            ps1_v_alu_latch <= ps1_v_alu;
            ps2_v_alu_latch <= ps2_v_alu;
        end
    end

    assign alu_ready = 1'b1; 

    logic   [31:0]  a;
    logic   [31:0]  b;
    logic   [2:0]   aluop;
    logic   [2:0]   cmpop;
    logic   [31:0]  aluout;
    logic           br_en;

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);


    always_comb begin
        unique case (aluop)
            alu_op_add: aluout = au +   bu;
            alu_op_sll: aluout = au <<  bu[4:0];
            alu_op_sra: aluout = unsigned'(as >>> bu[4:0]);
            alu_op_sub: aluout = au -   bu;
            alu_op_xor: aluout = au ^   bu;
            alu_op_srl: aluout = au >>  bu[4:0];
            alu_op_or : aluout = au |   bu;
            alu_op_and: aluout = au &   bu;
            default   : aluout = 'x;
        endcase
    end

    always_comb begin
        unique case (cmpop)
            branch_f3_beq : br_en = (au == bu);    
            branch_f3_bne : br_en = (au != bu);    
            branch_f3_blt : br_en = (as <  bs);
            branch_f3_bge : br_en = (as >=  bs);
            branch_f3_bltu: br_en = (au <  bu);
            branch_f3_bgeu: br_en = (au >=  bu);
            default       : br_en = 1'bx;
        endcase
    end

    always_comb begin 
        alu_execution_val.pv       = '0;
        alu_execution_val.pd       = pp_instr_execution_alu.pd; 
        alu_execution_val.rd       = pp_instr_execution_alu.rd;
        alu_execution_val.pc       = pp_instr_execution_alu.pc;
        alu_execution_val.regf_we  = 1'b0;
        alu_execution_val.rob_entry = pp_instr_execution_alu.rob_entry;
        alu_wb_valid = 1'b0; 
        alu_execution_val.pc_next = '0;
        alu_execution_val.update_pc_next = '0;
        alu_execution_val.branch_taken = 1'b0;

        // write_idx = '0;
        // btb_write_idx = pp_instr_execution_alu.pc[$clog2(BTB_DEPTH)-1:0];
        // gshare_write_idx = '0;
        // branch_we = '0;
        // branch_taken = '0;
        // bp_prev_state = wnt;
        // prev_pattern = '0;
        // misprediction = '0;
        // pc_next_misprediction = '0;
        // predictor_used = '0;
        // btb_write_pc = '0;

        pcp_4 = pp_instr_execution_alu.pc + 32'd4;
        pcp_offset = pp_instr_execution_alu.pc + pp_instr_execution_alu.imm;

        a          = 'x;
        b          = 'x;
        
        aluop      = 'x;
        cmpop      = 'x;

        if (incoming_alu_latch) begin   

            alu_wb_valid = 1'b1;
            alu_execution_val.regf_we = 1'b1;
            unique case (pp_instr_execution_alu.op_code)
                op_b_lui: begin
                    alu_execution_val.pv = pp_instr_execution_alu.imm;
                   
                end

                op_b_auipc: begin
                    alu_execution_val.pv = pp_instr_execution_alu.pc + pp_instr_execution_alu.imm;
                end

                op_b_imm: begin
                    a = ps1_v_alu_latch;
                    b = pp_instr_execution_alu.imm;
                    unique case (pp_instr_execution_alu.funct3)
                        arith_f3_slt: begin
                            cmpop = branch_f3_blt;
                            alu_execution_val.pv = {31'd0, br_en};
                        end
                        arith_f3_sltu: begin
                            cmpop = branch_f3_bltu;
                            alu_execution_val.pv = {31'd0, br_en};
                        end
                        arith_f3_sr: begin
                            if (pp_instr_execution_alu.funct7[5]) begin
                                aluop = alu_op_sra;
                            end else begin
                                aluop = alu_op_srl;
                            end
                            alu_execution_val.pv = aluout;
                        end
                        default: begin
                            aluop = pp_instr_execution_alu.funct3;
                            alu_execution_val.pv = aluout;
                        end
                    endcase
                end

                op_b_reg: begin
                    a = ps1_v_alu_latch;
                    b = ps2_v_alu_latch;
                    unique case (pp_instr_execution_alu.funct3)
                        arith_f3_slt: begin
                            cmpop = branch_f3_blt;
                            alu_execution_val.pv = {31'd0, br_en};
                        end
                        arith_f3_sltu: begin
                            cmpop = branch_f3_bltu;
                            alu_execution_val.pv = {31'd0, br_en};
                        end
                        arith_f3_sr: begin
                            if (pp_instr_execution_alu.funct7[5]) begin
                                aluop = alu_op_sra;
                            end else begin
                                aluop = alu_op_srl;
                            end
                            alu_execution_val.pv = aluout;
                        end
                        arith_f3_add: begin
                            if (pp_instr_execution_alu.funct7[5]) begin
                                aluop = alu_op_sub;
                            end else begin
                                aluop = alu_op_add;
                            end
                            alu_execution_val.pv = aluout;
                        end
                        default: begin
                            aluop = pp_instr_execution_alu.funct3;
                            alu_execution_val.pv = aluout;
                        end
                    endcase
                end

                op_b_jal: begin
                    a = pp_instr_execution_alu.pc;
                    b = pp_instr_execution_alu.imm;
                    aluop = alu_op_add;
                    alu_execution_val.pv = pp_instr_execution_alu.pc + 32'd4;
                    alu_execution_val.pc_next = aluout;
                    // alu_execution_val.update_pc_next = 1'b1;
                    alu_execution_val.update_pc_next = 1'b0;
                end

                op_b_jalr: begin
                    a = ps1_v_alu_latch;
                    b = pp_instr_execution_alu.imm;
                    aluop = alu_op_add;
                    alu_execution_val.pv = pp_instr_execution_alu.pc + 32'd4;
                    alu_execution_val.pc_next = {aluout[31:1], 1'b0};
                    alu_execution_val.update_pc_next = 1'b1;
                end

                op_b_br: begin 
                    a = ps1_v_alu_latch;
                    b = ps2_v_alu_latch;
                    cmpop = pp_instr_execution_alu.funct3;
                    alu_execution_val.pv = '0;
                    // alu_execution_val.update_pc_next = br_en;
                    // alu_execution_val.pc_next = pp_instr_execution_alu.pc + pp_instr_execution_alu.imm; //should we use same ALU adder??
                    alu_execution_val.update_pc_next = br_en ^ pp_instr_execution_alu.br_en;
                    // alu_execution_val.update_pc_next = misprediction;
                    alu_execution_val.branch_taken = br_en;
                    
                    if (br_en && ~pp_instr_execution_alu.br_en) begin
                        alu_execution_val.pc_next  = pcp_offset; //should we use same ALU adder??
                    end else if (~br_en && pp_instr_execution_alu.br_en) begin
                        alu_execution_val.pc_next = pcp_4; //should we use same ALU adder??
                    end else begin //branch prediction correct, need to check if pc prediction also correct
                        if (br_en && ( pp_instr_execution_alu.btb_pc_next != pcp_offset)) begin 
                            alu_execution_val.update_pc_next = 1'b1;
                            alu_execution_val.pc_next = pcp_offset;
                            // btb_write_pc = pcp_offset;
                            // pc_next_misprediction = 1'b1;
                        end else if (~br_en && (pp_instr_execution_alu.btb_pc_next != pcp_4)) begin 
                            alu_execution_val.update_pc_next = 1'b1;
                            alu_execution_val.pc_next = pcp_4;
                            // btb_write_pc = pcp_4;
                            // pc_next_misprediction = 1'b1;
                        end else 
                            alu_execution_val.pc_next = '0;
                    end

                    // branch_we = 1'b1;
                    // branch_we = 1'b0;
                    // branch_taken = br_en;
                    // write_idx = pp_instr_execution_alu.pc[$clog2(PHT_DEPTH)-1:0];
                    // gshare_write_idx = pp_instr_execution_alu.pc[$clog2(LHT_DEPTH)-1:0] ^ pp_instr_execution_alu.ghr_val;
                    // gshare_write_idx = pp_instr_execution_alu.pc[$clog2(LHT_DEPTH)-1:0];
                    // bp_prev_state = pp_instr_execution_alu.bp_curr_state;
                    // prev_pattern = pp_instr_execution_alu.br_pattern;
                    // predictor_used = pp_instr_execution_alu.predictor_used;
                    // prev_pattern = curr_pattern;

                end

                default: begin
                end
            endcase
        end
    end

    // MUL LOGIC
    res_station_entry_t pp_instr_execution_mul; 
    logic mul_ready_latch; 

    logic incoming_mul_latch;
    
    logic [32 : 0] mul_a;
    logic [32 : 0] mul_a_latch;
    logic [32 : 0] mul_b; 
    logic [32 : 0] mul_b_latch; 
    logic mul_output_ready;
    logic  mul_complete;
    logic   flush_mul_latch;

    always_ff @(posedge clk) begin 
        if (rst) begin
            mul_ready_latch <= 1'b0;
            incoming_mul_latch <= 1'b0;
            flush_mul_latch <= 1'b0;
        end else if (flush && ~mul_complete) begin 
            flush_mul_latch <= 1'b1;
        end else begin 

            if (flush_mul_latch && mul_output_ready) flush_mul_latch <= 1'b0;

            if (~mul_ready_latch && (incoming_mul || incoming_mul_latch)) mul_ready_latch <= 1'b1;
            if (mul_ready_latch && mul_complete) mul_ready_latch <= '0;

            incoming_mul_latch <= incoming_mul;
            mul_a_latch <= mul_a;
            mul_b_latch <= mul_b;
            // mul_output_ready <= '0;
            if (incoming_mul) begin
                pp_instr_execution_mul <= instr_execution_mul; 
            end
            // if (mul_complete && mul_ready_latch) mul_output_ready <= 1'b1;
            // if (mul_output_ready) mul_output_ready <= 1'b0;
        end

    end
    

    logic [65 : 0] mul_out;


    assign mul_output_ready = mul_ready_latch ? mul_complete : 1'b0;
    assign mul_ready = mul_complete;

    DW_mult_seq_inst    multiplier( .inst_clk(clk), 
                                    .inst_rst_n(~rst), 
                                    .inst_hold(1'b0), 
                                    .inst_start(incoming_mul_latch), 
                                    .inst_a(mul_a_latch),
                                    .inst_b(mul_b_latch), 
                                    .complete_inst(mul_complete), 
                                    .product_inst(mul_out) 
                                    );

    always_comb begin
        mul_execution_val.branch_taken = 1'b0;
        mul_execution_val.pv       = '0;
        mul_execution_val.pd       = pp_instr_execution_mul.pd; 
        mul_execution_val.rd       = pp_instr_execution_mul.rd;
        mul_execution_val.pc       = pp_instr_execution_mul.pc;
        mul_execution_val.regf_we  = 1'b0;
        mul_execution_val.rob_entry = pp_instr_execution_mul.rob_entry;
        mul_wb_valid = 1'b0; 
        mul_execution_val.pc_next = '0;
        mul_execution_val.update_pc_next = '0;

        mul_a = '0;
        mul_b = '0;

        if (incoming_mul) begin  //drive multiplier input signals 
            unique case (instr_execution_mul.funct3)  
                3'b000: begin
                    mul_a = {ps1_v_mul[31], ps1_v_mul}; 
                    mul_b = {ps2_v_mul[31], ps2_v_mul}; 
                end
                3'b001: begin
                    mul_a = {ps1_v_mul[31], ps1_v_mul}; 
                    mul_b = {ps2_v_mul[31], ps2_v_mul}; 
                end
                3'b010: begin
                    mul_a = {ps1_v_mul[31], ps1_v_mul}; 
                    mul_b = {1'b0, ps2_v_mul}; 
                end
                3'b011: begin
                    mul_a = {1'b0, ps1_v_mul}; 
                    mul_b = {1'b0, ps2_v_mul}; 
                end
                default: begin end
            endcase
        end

        if (mul_output_ready && ~flush_mul_latch) begin
            mul_wb_valid = 1'b1; 
            mul_execution_val.regf_we  = 1'b1;

            unique case (pp_instr_execution_mul.funct3)  
                3'b000: begin
                    mul_execution_val.pv = mul_out[31:0]; 
                end
                3'b001: begin
                    mul_execution_val.pv = mul_out[63:32]; 
                end
                3'b010: begin
                    mul_execution_val.pv = mul_out[63:32]; 
                end
                3'b011: begin
                    mul_execution_val.pv = mul_out[63:32]; 
                end
                default: begin end
            endcase
        end

    end



    // DIV LOGIC
    res_station_entry_t pp_instr_execution_div; 
    logic div_ready_latch; 

    
    logic [32 : 0] div_a;
    logic [32 : 0] div_b; 
    logic div_output_ready;
    logic  div_complete;
    logic   [31:0]  div_ps1_v_latch;
    logic   flush_div_latch;


    always_ff @(posedge clk) begin 
        if (rst) begin
            div_ready_latch <= 1'b0;
            div_ps1_v_latch <= '0;
            flush_div_latch <= 1'b0;
        end else if (flush && ~div_complete) begin 
            flush_div_latch <= 1'b1;
        end else begin 

            if(flush_div_latch && div_output_ready) flush_div_latch <= 1'b0;

            if (~div_ready_latch && incoming_div) div_ready_latch <= 1'b1;
            if (div_ready_latch && div_complete) div_ready_latch <= incoming_div;

            if (incoming_div) begin
                pp_instr_execution_div <= instr_execution_div; 
                div_ps1_v_latch <= ps1_v_div;
            end
     
        end

    end
    

    logic [32 : 0] div_q_out, div_r_out;


    assign div_output_ready = div_ready_latch ? div_complete : 1'b0;
    assign div_ready = div_complete;

    logic divide_by_0;

    DW_div_seq_inst    divider( .inst_clk(clk), 
                                    .inst_rst_n(~rst), 
                                    .inst_hold(1'b0), 
                                    .inst_start(incoming_div), 
                                    .inst_a(div_a),
                                    .inst_b(div_b), 
                                    .complete_inst(div_complete), 
                                    .quotient_inst(div_q_out),
                                    .remainder_inst(div_r_out),
                                    .divide_by_0_inst(divide_by_0)
                                    );

    always_comb begin
        div_execution_val.branch_taken = 1'b0;
        div_execution_val.pv       = '0;
        div_execution_val.pd       = pp_instr_execution_div.pd; 
        div_execution_val.rd       = pp_instr_execution_div.rd;
        div_execution_val.pc       = pp_instr_execution_div.pc;
        div_execution_val.regf_we  = 1'b0;
        div_execution_val.rob_entry = pp_instr_execution_div.rob_entry;
        div_wb_valid = 1'b0; 
        div_execution_val.pc_next = '0;
        div_execution_val.update_pc_next = '0;

        div_a = '0;
        div_b = '0;

        if (incoming_div) begin  //drive multiplier input signals 
            unique case (instr_execution_div.funct3)  
                3'b100, 3'b110: begin
                    div_a = {ps1_v_div[31], ps1_v_div}; 
                    div_b = {ps2_v_div[31], ps2_v_div}; 
                end
                3'b101, 3'b111: begin
                    div_a = {1'b0, ps1_v_div}; 
                    div_b = {1'b0, ps2_v_div}; 
                end
                default: begin end
            endcase
        end

        if (div_output_ready && ~flush_div_latch) begin
            div_wb_valid = 1'b1; 
            div_execution_val.regf_we  = 1'b1;

            unique case (pp_instr_execution_div.funct3)  
                3'b100, 3'b101: begin // div
                    if (divide_by_0) div_execution_val.pv = '1;
                    else div_execution_val.pv = div_q_out[31:0]; 
                end
                3'b110, 3'b111: begin
                    if (divide_by_0) div_execution_val.pv = div_ps1_v_latch;
                    else div_execution_val.pv = div_r_out[31:0]; 
                end
                default: begin end
            endcase
        end

    end

endmodule : execute

//need to write execute - add multiplier divider - add additional mul_execution_val structs (one for each functional unit)