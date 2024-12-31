module load_queue
import rv32i_types::*;
import params::*;
#(
    parameter   WIDTH   = 64,   // Width of each entry in bits
    parameter   DEPTH   = 4   // Depth of the FIFO (number of entries)
)(
    input   logic                       clk,
    input   logic                       rst,

    // connections to decode
    input   ls_queue_entry_t            wdata,
    input   logic                       load_enqueue,

    output  logic                       load_full,
    
    // connections to reg file
    output  logic   [5:0]               ps1_ls,
    output  logic   [5:0]               ps2_ls,

    input   logic   [31:0]              ps1_v_ls,
    // input   logic   [31:0]              ps2_v_ls,

    // connections to cdb
    input  CDB_t                       load_cdb,
    input   CDB_t                       alu_cdb,
    input   CDB_t                       mul_cdb,        
    input   CDB_t                       div_cdb,

    input    logic                          load_ack, 
    output     logic                        load_req,
    output  split_lsq_t                  load_queue_req, 

    input   logic       [31:0]          load_store_age, 
    input   logic       [31:0]          store_age_order[DEPTH], 
    input   logic                       store_valid   [DEPTH],

    input   logic                       store_valid_order   [DEPTH],
    input   logic           [2:0]       store_funct3 [DEPTH],
    input   logic       [31:0]          store_addr[DEPTH], 
    input   logic                       store_ps2_valid_order   [DEPTH],
    input   logic       [31:0]          store_val    [DEPTH],

    output logic   [5:0]    ps1_ld_addr1,
    output logic   [5:0]    ps1_ld_addr2,
    output logic   [5:0]    ps1_ld_addr3,
    output logic   [5:0]    ps1_ld_addr4,
    input  logic   [31:0]   ps1_v_ld_addr1,
    input  logic   [31:0]   ps1_v_ld_addr2,
    input  logic   [31:0]   ps1_v_ld_addr3,
    input  logic   [31:0]   ps1_v_ld_addr4,

    // connection to rob
    // output  rvfi_mem_signals_t          curr_mem_operation,
    input   logic                       flush

);


    ls_queue_entry_t           load_queue           [DEPTH];
    logic                      valid                [DEPTH];
    logic                      age_order_satisfied  [DEPTH];
    logic          [31:0]      load_age_order       [DEPTH];
    logic          [31:0]      load_forward_age     [DEPTH];
    logic          [31:0]      load_forward_data     [DEPTH];
    logic                      load_forward_valid     [DEPTH];


    logic   [$clog2(DEPTH)-1:0]  load_head;
    logic   [$clog2(DEPTH)-1:0]  load_tail;

    logic                        load_overflow;
    logic                        load_empty;
    
    ls_queue_entry_t             load_rdata;
    logic                        load_dequeue;

    logic   [31:0]  load_request_addr, load_request_addr2;
    logic   [3:0]   load_request_rmask;
    logic       [31:0]          load_addr    [DEPTH];

    logic ready; 
    
    logic forward_flag; 

    always_ff @(posedge clk) begin
        if(rst || flush) begin
            load_head <= '0;
            load_tail <= '0;
            load_overflow <= '0;
            for(int i = '0; i < DEPTH; ++i) begin
                load_queue[i] <= '0;
                valid[i] <= '0;
                load_age_order[i] <= '0;
            end
        end
        else begin
            // DEQUEUE LOGIC_________________________________________________ 
            if (load_dequeue && !load_empty) begin
                load_head <= load_head + 2'b1;
                valid[load_head] <= 1'b0;
            end
            // ENQUEUE LOGIC_________________________________________________
            if (load_enqueue && !load_full) begin
                load_queue[load_tail] <= wdata;
                valid[load_tail] <= 1'b1;         
                load_tail <= load_tail + 1'b1;
                load_overflow <= ((load_tail + 1'b1) == load_head);
                load_age_order[load_tail] <= load_store_age; 
            end

            if (load_overflow && load_dequeue) load_overflow <= '0;

            // VALUE FORWARD_________________________________________________ 
            if (alu_cdb.regf_we) begin 
                    for (int i = 0; i < DEPTH; i++) begin
                        if (valid[i]) begin
                            if (load_queue[i].ps1 == alu_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
                            if (load_queue[i].ps2 == alu_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
                        end
                    end 
                end

                if (div_cdb.regf_we) begin 
                    for (int i = 0; i < DEPTH; i++) begin
                        if (valid[i]) begin
                            if (load_queue[i].ps1 == div_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
                            if (load_queue[i].ps2 == div_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
                        end
                    end 
                end

                if (mul_cdb.regf_we) begin 
                    for (int i = 0; i < DEPTH; i++) begin
                        if (valid[i]) begin
                            if (load_queue[i].ps1 == mul_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
                            if (load_queue[i].ps2 == mul_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
                        end
                    end 
                end

                if (load_cdb.regf_we) begin 
                    for (int i = 0; i < DEPTH; i++) begin
                        if (valid[i]) begin
                            if (load_queue[i].ps1 == load_cdb.pd) load_queue[i].ps1_valid <= 1'b1;
                            if (load_queue[i].ps2 == load_cdb.pd) load_queue[i].ps2_valid <= 1'b1;
                        end
                    end 
                end
                // VALUE FORWARD_________________________________________________
        end

        for (int i = 0; i < DEPTH; i++) begin
            if (valid[i] && load_forward_valid[i]) begin
                load_queue[i].data_available <= 1'b1; 
                load_queue[i].load_data <= load_forward_data[i]; 
            end
        end
    end

    assign load_empty = (load_head == load_tail) && ~load_overflow;
    assign load_full = (load_head == load_tail) && load_overflow;
    assign ps1_ls = load_rdata.ps1;
    assign ps2_ls = load_rdata.ps2;

    always_comb begin
        load_request_addr2 = ps1_v_ls + load_rdata.imm; 
        load_request_addr = {load_request_addr2[31:2], 2'b00}; 
        load_request_rmask = '0;

        if (load_rdata.op_code == op_b_load) begin
            unique case (load_rdata.funct3) 
                load_f3_lb, load_f3_lbu: load_request_rmask = 4'b0001 << load_request_addr2[1:0]; //request_addr has addr
                load_f3_lh, load_f3_lhu: load_request_rmask = 4'b0011 << load_request_addr2[1:0];
                load_f3_lw             : load_request_rmask = 4'b1111;
                default                : load_request_rmask = '0;
            endcase
        end 
    end

   

    assign load_rdata = (!load_empty) ? load_queue[load_head] : '0;
    assign ready = (load_rdata.ps1_valid) && ~load_empty && valid[load_head];
    assign load_dequeue = load_ack & valid[load_head]; 
    assign load_req = ready && ~flush && age_order_satisfied[load_head];

     always_comb begin
        ps1_ld_addr1 = load_queue[0].ps1;  
        ps1_ld_addr2 = load_queue[1].ps1; 
        ps1_ld_addr3 = load_queue[2].ps1; 
        ps1_ld_addr4 = load_queue[3].ps1; 
        load_addr[0] = ps1_v_ld_addr1 + load_queue[0].imm; 
        load_addr[1] = ps1_v_ld_addr2 + load_queue[1].imm; 
        load_addr[2] = ps1_v_ld_addr3 + load_queue[2].imm; 
        load_addr[3] = ps1_v_ld_addr4 + load_queue[3].imm; 
    end

    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            age_order_satisfied[i] = '1; 
            if (valid[i]) begin
                for (int j = 0; j < DEPTH; j++) begin
                    if (store_valid[j] && (store_age_order[j] < load_age_order[i]) && (~store_valid_order[j])) begin
                        age_order_satisfied[i] = '0; 
                        break;
                    end
                    else if (store_valid[j] && (store_age_order[j] < load_age_order[i]) && load_queue[i].ps1_valid && (load_addr[i][31:2] == store_addr[j][31:2])) begin
                        age_order_satisfied[i] = '0; 
                        break;
                    end
                end
            end
        end
    end
 
    always_comb begin  
        for (int i = 0; i < DEPTH; i++) begin
            load_forward_age[i] = load_age_order[i]; 
            load_forward_data[i] = '0; 
            load_forward_valid[i] = 1'b0; 
            forward_flag = 1'b0;
            
            if (valid[i]) begin
                for (int j = 0; j < DEPTH; j++) begin
                    if (store_valid[j] && (store_age_order[j] < load_age_order[i]) && store_valid_order[j] && store_ps2_valid_order[j] && load_queue[i].ps1_valid && (load_addr[i] == store_addr[j]) && (load_queue[i].funct3 == store_funct3[j])) begin
                      if (!forward_flag) begin
                        load_forward_age[i] = store_age_order[j]; 
                        load_forward_data[i] = store_val[j]; 
                        load_forward_valid[i] = 1'b1; 
                        forward_flag = 1'b1; 

                      end else if (store_age_order[j] > load_forward_age[i]) begin
                        load_forward_age[i] = store_age_order[j]; 
                        load_forward_data[i] = store_val[j]; 
                        load_forward_valid[i] = 1'b1; 
                    end
                    end
                end
            end
        end
    end

    always_comb begin
        load_queue_req = '0; 
        load_queue_req.funct3 = load_rdata.funct3; 
        load_queue_req.addr2 = load_request_addr2; 
        load_queue_req.addr = load_request_addr; 
        load_queue_req.rmask = load_request_rmask; 
        load_queue_req.rd = load_rdata.rd; 
        load_queue_req.pd = load_rdata.pd; 
        load_queue_req.rob_entry = load_rdata.rob_entry;
        load_queue_req.pc = load_rdata.pc;
        load_queue_req.data_available = load_rdata.data_available; 
        load_queue_req.load_data = load_rdata.load_data; 
    end

endmodule 
