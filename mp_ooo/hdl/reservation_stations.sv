module reservation_stations
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,


    // connections to decode
    input   res_station_struct_t    decode_to_rs,
    input   logic                   incoming_from_decode, 
    output      logic               alu_station_full,
    output      logic               mul_station_full,
    output      logic               div_station_full,
    input       logic         [2:0] case_type,  

    // connections to regfile
    output  logic     [5:0]          ps1_alu, 
    output  logic     [5:0]          ps2_alu,
    output  logic     [5:0]          ps1_mul, 
    output  logic     [5:0]          ps2_mul,
    output  logic     [5:0]          ps1_div, 
    output  logic     [5:0]          ps2_div, 

    // connections to functional units
    output  res_station_entry_t     instr_execution_alu,
    output  res_station_entry_t     instr_execution_mul,
    output  res_station_entry_t     instr_execution_div,

    output  logic                   incoming_alu,
    output  logic                   incoming_mul,
    output  logic                   incoming_div,

    input   logic                   alu_ready,
    input   logic                   mul_ready,
    input   logic                   div_ready,

    //connections to common data bus
    input   logic   [PR_WIDTH-1:0]  alu_cdb_pd,
    input   logic                   alu_cdb_we,      

    input   logic   [PR_WIDTH-1:0]  mul_cdb_pd,
    input   logic                   mul_cdb_we,

    input   logic   [PR_WIDTH-1:0]  div_cdb_pd,
    input   logic                   div_cdb_we,

    input   logic   [PR_WIDTH-1:0]  load_cdb_pd,
    input   logic                   load_cdb_we,

    input  logic    [31:0]         res_station_age,

    //flush
    input   logic                   flush

);

    res_station_entry_t alu_station [ALU_RS_COUNT];
    res_station_entry_t mul_station [MUL_RS_COUNT];
    res_station_entry_t div_station [DIV_RS_COUNT];

    logic [$clog2(ALU_RS_COUNT) - 1 : 0] alu_index; 
    logic [$clog2(MUL_RS_COUNT) - 1 : 0] mul_index; 
    logic [$clog2(DIV_RS_COUNT) - 1 : 0] div_index; 

    logic [$clog2(ALU_RS_COUNT) - 1 : 0] alu_ready_index; 
    logic [$clog2(MUL_RS_COUNT) - 1 : 0] mul_ready_index; 
    logic [$clog2(DIV_RS_COUNT) - 1 : 0] div_ready_index; 

    logic alu_flag; 
    logic mul_flag; 
    logic div_flag; 

    logic   [31:0]     min_age_alu; 
    logic   [$clog2(ALU_RS_COUNT) - 1 : 0] alu_age_index; 

    // logic temp; 

    // always_comb begin
    //     temp = 1'b0; 
    //     if (alu_station[0].ps1_valid & alu_station[0].ps2_valid & alu_station[0].busy &&
    //         alu_station[1].ps1_valid & alu_station[1].ps2_valid & alu_station[1].busy &&
    //         alu_station[2].ps1_valid & alu_station[2].ps2_valid & alu_station[2].busy &&
    //         alu_station[3].ps1_valid & alu_station[3].ps2_valid & alu_station[3].busy) 
    //         temp = 1'b1;
    // end

    always_comb begin 

        alu_ready_index = alu_index;
        mul_ready_index = mul_index;
        div_ready_index = div_index;
        incoming_alu = 1'b0;
        incoming_mul = 1'b0;
        incoming_div = 1'b0;

        
        if (alu_ready && ~flush) begin 
            min_age_alu = 32'b01111111111111111111111111111111;
            alu_age_index = 2'b0;
            for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                if (alu_station[i].ps1_valid & alu_station[i].ps2_valid & alu_station[i].busy & alu_station[i].age < min_age_alu) begin 
                    min_age_alu = alu_station[i].age; 
                    alu_age_index = unsigned'(2'(i)); 
                end
            end

            for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                if (alu_station[i].ps1_valid & alu_station[i].ps2_valid & alu_station[i].busy & (alu_age_index == unsigned'(2'(i)))) begin
                    alu_ready_index = unsigned'(2'(i)); //alu_rs_count
                    incoming_alu = 1'b1;
                    break;
                end
            end
        end

        // if (alu_ready && ~flush) begin 
        //     for (int i = 0; i < ALU_RS_COUNT; i++) begin 
        //         if (alu_station[i].ps1_valid & alu_station[i].ps2_valid & alu_station[i].busy) begin 
        //             alu_ready_index = unsigned'(2'(i)); //alu_rs_count
        //             incoming_alu = 1'b1;
        //             break;
        //         end
        //     end
        // end

        if (mul_ready && ~flush) begin 
            for (int i = 0; i < MUL_RS_COUNT; i++) begin 
                if (mul_station[i].ps1_valid & mul_station[i].ps2_valid & mul_station[i].busy) begin 
                    mul_ready_index = unsigned'(1'(i)); //mul_rs_count
                    incoming_mul = 1'b1;
                    break;
                end
            end
        end

        if (div_ready && ~flush) begin 
            for (int i = 0; i < DIV_RS_COUNT; i++) begin 
                if (div_station[i].ps1_valid & div_station[i].ps2_valid & div_station[i].busy) begin 
                    div_ready_index = unsigned'(1'(i)); //div_rs_count
                    incoming_div = 1'b1;
                    break;
                end
            end
        end

        ps1_alu = alu_station[alu_ready_index].ps1; 
        ps2_alu = alu_station[alu_ready_index].ps2;
        ps1_mul = mul_station[mul_ready_index].ps1; 
        ps2_mul = mul_station[mul_ready_index].ps2;
        ps1_div = div_station[div_ready_index].ps1; 
        ps2_div = div_station[div_ready_index].ps2; 

        instr_execution_alu = alu_station[alu_ready_index];
        instr_execution_mul = mul_station[mul_ready_index];
        instr_execution_div = div_station[div_ready_index];
    end

    always_comb begin //res station full signals
        alu_station_full = 1'b1;
        mul_station_full = 1'b1;
        div_station_full = 1'b1;

        for (int i = 0; i < ALU_RS_COUNT; i++) begin 
            if (~alu_station[i].busy) begin 
                alu_station_full = 1'b0;
                break;
            end
        end
        for (int i = 0; i < MUL_RS_COUNT; i++) begin 
            if (~mul_station[i].busy) begin 
                mul_station_full = 1'b0;
                break;
            end
        end
        for (int i = 0; i < DIV_RS_COUNT; i++) begin 
            if (~div_station[i].busy) begin 
                div_station_full = 1'b0;
                break;
            end
        end
    end

    always_ff @(posedge clk) begin //assign to res station based on operation and res_station_next
        if (rst || flush) begin
            for (int i = 0; i < ALU_RS_COUNT; i++) begin
                alu_station[i] <= '0;
            end
            for (int i = 0; i < MUL_RS_COUNT; i++) begin
                mul_station[i] <= '0;
            end
            for (int i = 0; i < DIV_RS_COUNT; i++) begin
                div_station[i] <= '0;
            end

            alu_index <= 2'b0; 
            mul_index <= 1'b0; 
            div_index <= 1'b0; 

        end else begin
        
            if (incoming_from_decode) begin 
                case(case_type)
                    0: begin
                        alu_station[alu_index].busy <= 1'b1; 

                        alu_station[alu_index].ps1 <= decode_to_rs.ps1; 
                        alu_station[alu_index].ps1_valid <= decode_to_rs.ps1_valid;
                        alu_station[alu_index].ps2 <= decode_to_rs.ps2; 
                        alu_station[alu_index].ps2_valid <= decode_to_rs.ps2_valid;
                        alu_station[alu_index].rob_entry <= decode_to_rs.rob_entry; 
                        alu_station[alu_index].rd <= decode_to_rs.rd; 
                        alu_station[alu_index].pd <= decode_to_rs.pd;

                        // alu_station[alu_index].rs1 <= decode_to_rs.rs1; 
                        // alu_station[alu_index].rs2 <= decode_to_rs.rs2; 

                        alu_station[alu_index].pc  <= decode_to_rs.pc;
                        alu_station[alu_index].br_en  <= decode_to_rs.br_en;
                        
                        alu_station[alu_index].rob_entry <= decode_to_rs.rob_entry;  

                        alu_station[alu_index].op_code <= decode_to_rs.op_code; 
                        alu_station[alu_index].funct3 <= decode_to_rs.funct3; 
                        alu_station[alu_index].funct7 <= decode_to_rs.funct7; 
                        alu_station[alu_index].imm <= decode_to_rs.imm;
                        alu_station[alu_index].bp_curr_state <= decode_to_rs.bp_curr_state;
                        alu_station[alu_index].br_pattern <= decode_to_rs.br_pattern;
                        alu_station[alu_index].predictor_used <= decode_to_rs.predictor_used;
                        alu_station[alu_index].ghr_val <= decode_to_rs.ghr_val;
                        alu_station[alu_index].btb_pc_next <= decode_to_rs.btb_pc_next;


                        alu_station[alu_index].age <= res_station_age; 

                        
                        for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                            if (alu_station[i].busy == 1'b0 && alu_index != unsigned'(2'(i))) begin
                                alu_index <= unsigned'(2'(i));
                                alu_flag <= 1'b0; 
                                break; 
                            end else 
                                alu_flag <= 1'b1; 
                        end
                    end

                    1: begin
                        mul_station[mul_index].busy <= 1'b1; 

                        mul_station[mul_index].ps1 <= decode_to_rs.ps1; 
                        mul_station[mul_index].ps1_valid <= decode_to_rs.ps1_valid;
                        mul_station[mul_index].ps2 <= decode_to_rs.ps2; 
                        mul_station[mul_index].ps2_valid <= decode_to_rs.ps2_valid;
                        mul_station[mul_index].rob_entry <= decode_to_rs.rob_entry; 
                        mul_station[mul_index].rd <= decode_to_rs.rd; 
                        mul_station[mul_index].pd <= decode_to_rs.pd; 

                        // mul_station[mul_index].rs1 <= decode_to_rs.rs1; 
                        // mul_station[mul_index].rs2 <= decode_to_rs.rs2; 

                        mul_station[mul_index].pc <= decode_to_rs.pc; 
                        mul_station[mul_index].br_en <= decode_to_rs.br_en; 

                        mul_station[mul_index].rob_entry <= decode_to_rs.rob_entry; 

                        mul_station[mul_index].op_code <= decode_to_rs.op_code; 
                        mul_station[mul_index].funct3 <= decode_to_rs.funct3; 
                        mul_station[mul_index].funct7 <= decode_to_rs.funct7; 
                        mul_station[mul_index].imm <= decode_to_rs.imm;
                        mul_station[mul_index].bp_curr_state <= decode_to_rs.bp_curr_state;
                        mul_station[mul_index].br_pattern <= decode_to_rs.br_pattern;
                        mul_station[mul_index].predictor_used <= decode_to_rs.predictor_used;
                        mul_station[mul_index].ghr_val <= decode_to_rs.ghr_val;





                        for (int unsigned i = 0; i < MUL_RS_COUNT; i++) begin
                            if (mul_station[i].busy == 1'b0 && mul_index != 1'(i)) begin
                                mul_index <= unsigned'(1'(i));
                                mul_flag <= 1'b0; 
                                break; 
                            end else 
                                mul_flag <= 1'b1; 
                        end

                    end

                    2: begin
                        div_station[div_index].busy <= 1'b1; 

                        div_station[div_index].ps1 <= decode_to_rs.ps1; 
                        div_station[div_index].ps1_valid <= decode_to_rs.ps1_valid;
                        div_station[div_index].ps2 <= decode_to_rs.ps2; 
                        div_station[div_index].ps2_valid <= decode_to_rs.ps2_valid;
                        div_station[div_index].rob_entry <= decode_to_rs.rob_entry; 
                        div_station[div_index].rd <= decode_to_rs.rd; 
                        div_station[div_index].pd <= decode_to_rs.pd; 

                        // div_station[div_index].rs1 <= decode_to_rs.rs1; 
                        // div_station[div_index].rs2 <= decode_to_rs.rs2;  

                        div_station[div_index].pc <= decode_to_rs.pc; 
                        div_station[div_index].br_en <= decode_to_rs.br_en; 

                        div_station[div_index].rob_entry <= decode_to_rs.rob_entry; 

                        div_station[div_index].op_code <= decode_to_rs.op_code; 
                        div_station[div_index].funct3 <= decode_to_rs.funct3; 
                        div_station[div_index].funct7 <= decode_to_rs.funct7; 
                        div_station[div_index].imm <= decode_to_rs.imm;
                        div_station[div_index].bp_curr_state <= decode_to_rs.bp_curr_state;
                        div_station[div_index].br_pattern <= decode_to_rs.br_pattern;
                        div_station[div_index].predictor_used <= decode_to_rs.predictor_used;
                        div_station[div_index].ghr_val <= decode_to_rs.ghr_val;





                        for (int i = 0; i < DIV_RS_COUNT; i++) begin
                            if (div_station[i].busy == 1'b0 && div_index != unsigned'(1'(i))) begin
                                div_index <= unsigned'(1'(i));
                                div_flag <= 1'b0; 
                                break; 
                            end else 
                                div_flag <= 1'b1; 
                        end
                    end

                    default: begin end
                endcase
            end

            if (incoming_alu) begin 
                alu_station[alu_ready_index].busy <= 1'b0;
                alu_index <= alu_ready_index;
            end

            if (incoming_mul) begin 
                mul_station[mul_ready_index].busy <= 1'b0;
                mul_index <= mul_ready_index;
            end

            if (incoming_div) begin 
                div_station[div_ready_index].busy <= 1'b0;
                div_index <= div_ready_index;
            end
            
            if (alu_cdb_we) begin //check stations with ALU CDB
                for (int i = 0; i < ALU_RS_COUNT; i++) begin
                    if (alu_station[i].busy != '0) begin 
                        if (alu_station[i].ps1 == alu_cdb_pd) alu_station[i].ps1_valid <= 1'b1;
                        if (alu_station[i].ps2 == alu_cdb_pd) alu_station[i].ps2_valid <= 1'b1;
                    end 
                end

                for (int i = 0; i < MUL_RS_COUNT; i++) begin 
                    if (mul_station[i].busy != '0) begin 
                        if (mul_station[i].ps1 == alu_cdb_pd) mul_station[i].ps1_valid <= 1'b1;
                        if (mul_station[i].ps2 == alu_cdb_pd) mul_station[i].ps2_valid <= 1'b1;
                    end

                end

                for (int i = 0; i < DIV_RS_COUNT; i++) begin 
                    if (div_station[i].busy != '0) begin 
                         if (div_station[i].ps1 == alu_cdb_pd) div_station[i].ps1_valid <= 1'b1;
                        if (div_station[i].ps2 == alu_cdb_pd) div_station[i].ps2_valid <= 1'b1;
                    end
                end
            end

            if (mul_cdb_we) begin //check stations with MUL CDB 
                for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                    if (alu_station[i].busy != '0) begin 
                        if (alu_station[i].ps1 == mul_cdb_pd) alu_station[i].ps1_valid <= 1'b1;
                        if (alu_station[i].ps2 == mul_cdb_pd) alu_station[i].ps2_valid <= 1'b1;
                    end
                end

                for (int i = 0; i < MUL_RS_COUNT; i++) begin 
                    if (mul_station[i].busy != '0) begin
                        if (mul_station[i].ps1 == mul_cdb_pd) mul_station[i].ps1_valid <= 1'b1;
                        if (mul_station[i].ps2 == mul_cdb_pd) mul_station[i].ps2_valid <= 1'b1;
                    end
                end

                for (int i = 0; i < DIV_RS_COUNT; i++) begin
                    if (div_station[i].busy != '0) begin  
                        if (div_station[i].ps1 == mul_cdb_pd) div_station[i].ps1_valid <= 1'b1;
                        if (div_station[i].ps2 == mul_cdb_pd) div_station[i].ps2_valid <= 1'b1;
                    end
                end
            end

            if (div_cdb_we) begin 
                for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                    if (alu_station[i].busy != '0) begin 
                        if (alu_station[i].ps1 == div_cdb_pd) alu_station[i].ps1_valid <= 1'b1;
                        if (alu_station[i].ps2 == div_cdb_pd) alu_station[i].ps2_valid <= 1'b1;
                    end
                end

                for (int i = 0; i < MUL_RS_COUNT; i++) begin 
                    if (mul_station[i].busy != '0) begin
                        if (mul_station[i].ps1 == div_cdb_pd) mul_station[i].ps1_valid <= 1'b1;
                        if (mul_station[i].ps2 == div_cdb_pd) mul_station[i].ps2_valid <= 1'b1;
                    end 
                end

                for (int i = 0; i < DIV_RS_COUNT; i++) begin 
                    if (div_station[i].busy != '0) begin 
                        if (div_station[i].ps1 == div_cdb_pd) div_station[i].ps1_valid <= 1'b1;
                        if (div_station[i].ps2 == div_cdb_pd) div_station[i].ps2_valid <= 1'b1;
                    end
                end
            end

             if (load_cdb_we) begin 
                for (int i = 0; i < ALU_RS_COUNT; i++) begin 
                    if (alu_station[i].busy != '0) begin 
                        if (alu_station[i].ps1 == load_cdb_pd) alu_station[i].ps1_valid <= 1'b1;
                        if (alu_station[i].ps2 == load_cdb_pd) alu_station[i].ps2_valid <= 1'b1;
                    end
                end

                for (int i = 0; i < MUL_RS_COUNT; i++) begin 
                    if (mul_station[i].busy != '0) begin
                        if (mul_station[i].ps1 == load_cdb_pd) mul_station[i].ps1_valid <= 1'b1;
                        if (mul_station[i].ps2 == load_cdb_pd) mul_station[i].ps2_valid <= 1'b1;
                    end 
                end

                for (int i = 0; i < DIV_RS_COUNT; i++) begin 
                    if (div_station[i].busy != '0) begin 
                        if (div_station[i].ps1 == load_cdb_pd) div_station[i].ps1_valid <= 1'b1;
                        if (div_station[i].ps2 == load_cdb_pd) div_station[i].ps2_valid <= 1'b1;
                    end
                end
            end
        end
    end


endmodule : reservation_stations
