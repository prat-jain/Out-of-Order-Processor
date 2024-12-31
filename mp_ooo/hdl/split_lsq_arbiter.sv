module split_lsq_arbiter
import rv32i_types::*;
import params::*;
(
    input   logic                       clk,
    input   logic                       rst,

    // connections to dcache
    input   logic                       dcache_ufp_resp,
    output  logic   [31:0]              dcache_ufp_addr,
    output  logic   [3:0]               dcache_ufp_rmask,
    output  logic   [3:0]               dcache_ufp_wmask,
    output  logic   [31:0]              dcache_ufp_wdata,
    input  logic   [31:0]               dcache_ufp_rdata,

    // connections to cdb
    input  split_lsq_t                  load_queue_req, 
    input  split_lsq_t                  store_queue_req, 

    input  logic                        load_req, 
    input  logic                        store_req, 

    output logic                        load_ack, 
    output logic                        store_ack, 

    output  CDB_t                       store_cdb,
    output  CDB_t                       load_cdb,

    output  rvfi_mem_signals_t          curr_mem_operation,
    output  rvfi_mem_signals_t          curr_mem_operation_store,

    input   logic                       flush
);

   logic in_progress;
   logic valid_in_progress;
   logic ld_st_sent;
   logic flag; 

   always_comb begin
    dcache_ufp_addr  = '0; 
    dcache_ufp_rmask = '0; 
    dcache_ufp_wmask = '0; 
    dcache_ufp_wdata = '0; 
    flag = 1'b0; 
    if (store_req & ~in_progress) begin
        dcache_ufp_addr = store_queue_req.addr; 
        dcache_ufp_wmask = store_queue_req.wmask; 
        dcache_ufp_wdata = store_queue_req.wdata; 
    end else if (load_req & ~in_progress) begin
        if (load_queue_req.data_available) begin
            flag = 1'b1;
        end else begin
            dcache_ufp_addr =  load_queue_req.addr; 
            dcache_ufp_rmask = load_queue_req.rmask; 
        end
    end
   end

   always_ff @(posedge clk) begin
    if (rst) begin
        in_progress <= 1'b0;
        ld_st_sent  <= 1'b0;
    end else begin 
        if (store_req & ~in_progress) begin
            valid_in_progress <= 1'b1;
            in_progress <= 1'b1;
            ld_st_sent  <= 1'b0;  
        end else if (load_req & ~in_progress & ~flag & |load_queue_req.rmask) begin
            valid_in_progress <= 1'b1;
            in_progress <= 1'b1;
            ld_st_sent  <= 1'b1;  
        end
        if (dcache_ufp_resp & in_progress) begin
            valid_in_progress <= 1'b0;
            in_progress <= 1'b0; 
        end 
        if(flush) valid_in_progress <= '0;
    end
   end

   always_comb begin
    load_ack = '0; 
    store_ack = '0;  
    load_cdb = '0; 
    store_cdb = '0; 
    curr_mem_operation = '0; 
    curr_mem_operation_store = '0; 
    if ((dcache_ufp_resp & valid_in_progress) | flag) begin
        if (flag) begin
            load_ack = '1; 
            load_cdb.rd = load_queue_req.rd;
            load_cdb.pd = load_queue_req.pd;
            load_cdb.pv = '0;
            // load_cdb.regf_we = '0;
            load_cdb.rob_entry = load_queue_req.rob_entry;
            load_cdb.pc = load_queue_req.pc;
            load_cdb.regf_we = 1'b1;

            curr_mem_operation.addr  = load_queue_req.addr2;
            curr_mem_operation.rdata = load_queue_req.load_data;
            curr_mem_operation.rmask = load_queue_req.rmask;

            unique case(load_queue_req.funct3) 
                load_f3_lb : load_cdb.pv = {{24{load_queue_req.load_data[7 +8 *load_queue_req.addr2[1:0]]}}, load_queue_req.load_data[8 *load_queue_req.addr2[1:0] +: 8 ]};
                load_f3_lbu: load_cdb.pv = {{24{1'b0}}                          , load_queue_req.load_data[8 *load_queue_req.addr2[1:0] +: 8 ]};
                load_f3_lh : load_cdb.pv = {{16{load_queue_req.load_data[15+16*load_queue_req.addr2[1]  ]}}, load_queue_req.load_data[16*load_queue_req.addr2[1]   +: 16]};
                load_f3_lhu: load_cdb.pv = {{16{1'b0}}                          , load_queue_req.load_data[16*load_queue_req.addr2[1]   +: 16]};
                load_f3_lw : load_cdb.pv = load_queue_req.load_data;
                default    : load_cdb.pv = '0;
            endcase

        end else if (ld_st_sent) begin
            load_ack = '1; 
            load_cdb.rd = load_queue_req.rd;
            load_cdb.pd = load_queue_req.pd;
            load_cdb.pv = '0;
            // load_cdb.regf_we = '0;
            load_cdb.rob_entry = load_queue_req.rob_entry;
            load_cdb.pc = load_queue_req.pc;
            load_cdb.regf_we = 1'b1;

            curr_mem_operation.addr  = load_queue_req.addr2;
            curr_mem_operation.rdata = dcache_ufp_rdata;
            curr_mem_operation.rmask = load_queue_req.rmask;

            unique case(load_queue_req.funct3) 
                load_f3_lb : load_cdb.pv = {{24{dcache_ufp_rdata[7 +8 *load_queue_req.addr2[1:0]]}}, dcache_ufp_rdata[8 *load_queue_req.addr2[1:0] +: 8 ]};
                load_f3_lbu: load_cdb.pv = {{24{1'b0}}                          , dcache_ufp_rdata[8 *load_queue_req.addr2[1:0] +: 8 ]};
                load_f3_lh : load_cdb.pv = {{16{dcache_ufp_rdata[15+16*load_queue_req.addr2[1]  ]}}, dcache_ufp_rdata[16*load_queue_req.addr2[1]   +: 16]};
                load_f3_lhu: load_cdb.pv = {{16{1'b0}}                          , dcache_ufp_rdata[16*load_queue_req.addr2[1]   +: 16]};
                load_f3_lw : load_cdb.pv = dcache_ufp_rdata;
                default    : load_cdb.pv = '0;
            endcase

        end else begin
            store_ack = '1; 
            store_cdb.rd = store_queue_req.rd;
            store_cdb.pd = store_queue_req.pd;
            store_cdb.pv = '0;
            // store_cdb.regf_we = '0;
            store_cdb.rob_entry = store_queue_req.rob_entry;
            store_cdb.pc = store_queue_req.pc;
            store_cdb.regf_we = 1'b1;

            curr_mem_operation_store.addr  = store_queue_req.addr;
            curr_mem_operation_store.wmask = store_queue_req.wmask;
            curr_mem_operation_store.wdata = store_queue_req.wdata;
        end
    end
   end
   

endmodule