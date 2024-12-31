module decode
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    // connections to instruction
    output  logic               inst_q_dequeue,
    input   logic               inst_q_empty,
    input   iq_struct_t         inst_q_rdata,

    // connections to rat
    output  logic   [AR_WIDTH-1:0]  rs1,
    input   logic   [PR_WIDTH-1:0]  ps1,
    input   logic                   ps1_valid,
    output  logic   [AR_WIDTH-1:0]  rs2,
    input   logic   [PR_WIDTH-1:0]  ps2,
    input   logic                   ps2_valid,
    output  logic   [AR_WIDTH-1:0]  rd,
    output  logic   [PR_WIDTH-1:0]  pd,
    output  logic                   rat_we,
    // input   logic   [PR_WIDTH-1:0]  discarded_pd,
    output  logic    [31:0]         load_store_age, 
    output  logic    [31:0]         res_station_age, 

    // connections to free_list
    input   logic   [FREE_LIST_WIDTH-1:0]   free_list_rdata,
    output  logic                           free_list_dequeue,
    // output   logic [FREE_LIST_WIDTH-1:0]  free_list_wdata,
    // output   logic                       free_list_enqueue,

    // connections to reservation station
    output  res_station_struct_t    decode_to_rs,
    output  logic                   incoming_from_decode,
    // input   logic                   res_station_full, // reservation station stall
    
    // connections to load store queue
    output  ls_queue_entry_t        decode_to_load_queue,
    output  logic                   load_enqueue,
    input   logic                   load_queue_full,

    output  ls_queue_entry_t        decode_to_store_queue,
    output  logic                   store_enqueue,
    input   logic                   store_queue_full,

    // connections to rob queue
    input   logic           rob_full, // rob stall
    output  logic           rob_enqueue,
    output  rob_entry_t     rob_wdata,
    input   logic   [$clog2(ROB_QUEUE_DEPTH)-1:0]   rob_tail,

    input   logic   flush,
    input   logic   [63:0] updated_order,

    // connections to history table
    // output   logic   [$clog2(HT_DEPTH)-1:0]  read_idx,
    // input  bp_state_t                      bp_curr_state,

    // connections to fetch and IQ
    output  logic    [31:0]     predicted_pc_next,
    output  logic               decode_pc_we,

    input      logic               alu_station_full,
    input      logic               mul_station_full,
    input      logic               div_station_full,
    output       logic         [2:0] case_type

    // input      logic            tournament_output



);

    logic   [63:0]  order, order_next;
    logic   [31:0]          inst, pc, pc_next;
    logic res_station_full;
    bp_state_t      bp_curr_state;
    logic   [$clog2(LHT_DEPTH)-1:0] br_pattern;


    assign inst = inst_q_rdata.inst;
    assign pc = inst_q_rdata.pc;
    // assign bp_curr_state = inst_q_rdata.bp_curr_state;
    assign bp_curr_state = inst_q_rdata.tournament_output ? inst_q_rdata.gshare_bp_curr_state : inst_q_rdata.bp_curr_state;
    // assign bp_curr_state = inst_q_rdata.gshare_bp_curr_state;

    assign br_pattern = inst_q_rdata.br_pattern;

    // assign read_idx = pc[$clog2(HT_DEPTH)-1 : 0];

    always_ff @(posedge clk) begin 
        if (rst) begin
            order <= '0;
            load_store_age <= '0; 
            res_station_age <= '0; 
        end else if (flush) begin 
            order <= updated_order + 'd1;
            load_store_age <= '0; 
            res_station_age <= '0; 
        end else begin 
            order <= order_next;
            if (decode_to_rs.op_code == op_b_load || decode_to_rs.op_code == op_b_store)
                load_store_age <= load_store_age + 1'b1; 
            else 
                res_station_age <= res_station_age + 1'b1;
        end
    end

    logic           ras_push_en, ras_pop_en, ras_full, ras_empty;
    logic   [31:0]  ras_push_data, ras_pop_data;
    stack   return_address_stack(.*, 
                                .push(ras_push_en),
                                .pop(ras_pop_en),
                                .push_data(ras_push_data),
                                .pop_data(ras_pop_data),
                                .full(ras_full),
                                .empty(ras_empty));

    logic       ras_link_rd, ras_link_rs1;
    assign ras_link_rd = incoming_from_decode ? (inst[11:7] == 5'd1 || inst[11:7] == 5'd5) : 1'b0;
    assign ras_link_rs1 = incoming_from_decode ? (inst[19:15] == 5'd1 || inst[19:15] == 5'd5) : 1'b0;
    logic       jalr_jmp_rn;

    always_comb begin 
        decode_to_rs = '0;
        res_station_full = '0;
        case_type = '0;
        incoming_from_decode = 1'b0;
        load_enqueue = 1'b0;
        store_enqueue = 1'b0;

        ras_push_en = '0;
        ras_pop_en = '0;
        ras_push_data = pc + 32'd4;
        jalr_jmp_rn = 1'b0;

        rs1 = inst[19:15];
        rs2 = inst[24:20];
        rd = inst[11:7];
        pd = (rd == '0 || (inst[6:0] == op_b_store)) ? '0 : free_list_rdata;

        pc_next = pc + 32'd4;
        predicted_pc_next = '0;

        decode_to_rs.op_code = inst[6:0];
        decode_to_rs.funct3 = inst[14:12];
        decode_to_rs.funct7 = inst[31:25];
        decode_to_rs.pc = pc;
        decode_to_rs.rob_entry = rob_tail;
        decode_to_rs.ps1 = ps1;
        decode_to_rs.ps2 = ps2;
        decode_to_rs.pd  = pd;
        decode_to_rs.rd  = rd;
        decode_to_rs.br_en = '0;

        decode_to_rs.bp_curr_state = bp_curr_state;
        decode_to_rs.br_pattern = br_pattern;
        decode_to_rs.predictor_used = inst_q_rdata.tournament_output;
        decode_to_rs.ghr_val = inst_q_rdata.ghr_val;
        decode_to_rs.btb_pc_next = pc_next;

      

        unique case (decode_to_rs.op_code)
            op_b_lui, op_b_auipc:  begin         // u type
                decode_to_rs.imm  = {inst[31:12], 12'h000};
                decode_to_rs.ps1_valid = 1'b1;
                decode_to_rs.ps2_valid = 1'b1;
            end

            op_b_imm: begin                     //imm reg operations
                decode_to_rs.imm  = {{21{inst[31]}}, inst[30:20]};
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2 = '0;
                decode_to_rs.ps2_valid = 1'b1;
                rs2 = '0;
            end

            op_b_load: begin 
                decode_to_rs.imm  = {{21{inst[31]}}, inst[30:20]};
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2 = '0;
                decode_to_rs.ps2_valid = 1'b1;
                rs2 = '0;
            end

            op_b_store: begin 
                decode_to_rs.imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2_valid = ps2_valid;
                rd = '0;
                pd = '0;
                decode_to_rs.pd  = '0;
                decode_to_rs.rd  = '0;
            end

            op_b_jal: begin                      // j type
                decode_to_rs.imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
                decode_to_rs.ps1 = '0;
                decode_to_rs.ps1_valid = 1'b1;
                rs1 = '0;
                decode_to_rs.ps2 = '0;
                decode_to_rs.ps2_valid = 1'b1;
                rs2 = '0;
                predicted_pc_next = pc + decode_to_rs.imm;
                // predicted_pc_next = inst_q_rdata.btb_pc_next;
                pc_next = predicted_pc_next;
                if (ras_link_rd) ras_push_en = 1'b1;
            end 
            
            op_b_jalr: begin // i type 
                decode_to_rs.imm  = {{21{inst[31]}}, inst[30:20]};
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2 = '0;
                decode_to_rs.ps2_valid = 1'b1;
                rs2 = '0;
                if (ras_link_rs1 && !ras_link_rd) begin // pop
                    if (!ras_empty) begin
                        predicted_pc_next = ras_pop_data;
                        pc_next = predicted_pc_next;
                        ras_pop_en = 1'b1;
                        decode_to_rs.br_en = 1'b1;
                    end
                end else if (!ras_link_rs1 && ras_link_rd) begin // push (no jmp rn)
                    if (!ras_full) begin
                        ras_push_en = 1'b1;
                        decode_to_rs.br_en = 1'b0;
                    end
                end else if (ras_link_rs1 && ras_link_rd && inst[11:7] != inst[19:15]) begin // pop, then push
                    if (!ras_full && !ras_empty) begin
                        predicted_pc_next = ras_pop_data;
                        pc_next = predicted_pc_next;
                        ras_pop_en = 1'b1;
                        decode_to_rs.br_en = 1'b0;
                        ras_push_en = 1'b1;
                        jalr_jmp_rn = 1'b1;
                    end
                end else if (ras_link_rs1 && ras_link_rd && inst[11:7] == inst[19:15]) begin
                    if (!ras_full) begin
                        ras_push_en = 1'b1;
                        decode_to_rs.br_en = 1'b0;
                    end
                end
            end

            op_b_br: begin                       // b type
                decode_to_rs.imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2_valid = ps2_valid;
                rd = '0;
                pd = '0;
                decode_to_rs.pd  = '0;
                decode_to_rs.rd  = '0;


                if (bp_curr_state == st || bp_curr_state == wt) decode_to_rs.br_en = 1'b1;
                else decode_to_rs.br_en = 1'b0;

                if (decode_to_rs.br_en) begin 
                    // pc_next = inst_q_rdata.btb_pc_next;
                    pc_next = pc + decode_to_rs.imm;
                    decode_to_rs.btb_pc_next = pc_next;
                    predicted_pc_next = pc_next;
                end
            end

            default: begin
                decode_to_rs.imm = '0;
                decode_to_rs.ps1_valid = ps1_valid;
                decode_to_rs.ps2_valid = ps2_valid;
            end
        endcase

        if (~inst_q_empty && ~rob_full && inst != '0) begin
            if ((inst[6:0] == op_b_load)) begin
                load_enqueue = !load_queue_full;
                incoming_from_decode = 1'b0;
                decode_pc_we = '0;
            end else if ((inst[6:0] == op_b_store)) begin
                store_enqueue = !store_queue_full;
                incoming_from_decode = 1'b0;
                decode_pc_we = '0;
            end else begin 
                if (decode_to_rs.op_code == 7'b0110011 && decode_to_rs.funct7 == 7'b0000001 && decode_to_rs.funct3 < 3'b100) begin    // mul
                    case_type = 3'd1;
                    res_station_full = mul_station_full;
                end else if (decode_to_rs.op_code == 7'b0110011 && decode_to_rs.funct7 == 7'b0000001 && decode_to_rs.funct3 >= 3'b100) begin  // div
                    case_type = 3'd2;
                    res_station_full = div_station_full;
                end else begin                                                    //alu 
                    case_type = 3'd0; 
                    res_station_full = alu_station_full;
                end
                incoming_from_decode = !res_station_full;
                decode_pc_we = (incoming_from_decode && (inst[6:0] == op_b_jal || jalr_jmp_rn || decode_to_rs.br_en));
            end
        end else begin
            incoming_from_decode = 1'b0;
            decode_pc_we = 1'b0;
        end

         if (~incoming_from_decode & ~load_enqueue & ~store_enqueue) begin //stall
            inst_q_dequeue = '0;
            free_list_dequeue = 1'b0;
            rat_we = 1'b0;
            rob_enqueue = 1'b0;
            order_next = order;
        end else begin 
            inst_q_dequeue = 1'b1;
            free_list_dequeue = (rd == '0) ? 1'b0 : 1'b1;
            rat_we = (rd == '0) ? '0 : 1'b1;
            rob_enqueue = 1'b1;
            order_next = order + 64'b1;
        end

          //rob_entry
        rob_wdata = {1'b0, rd, pd, rs1, rs2, ps1, ps2, inst, pc, pc_next, order, 1'b0, decode_to_rs.bp_curr_state, decode_to_rs.br_pattern, decode_to_rs.predictor_used, 1'b0, decode_to_rs.ghr_val};

        decode_to_load_queue = decode_to_rs;
        decode_to_store_queue = decode_to_rs;
        if (!inst_q_dequeue) decode_to_rs = '0; 
    end
    
endmodule : decode

//need to figure out why free list not outputing anything
//connects to ROB