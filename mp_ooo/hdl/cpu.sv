module cpu
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

    logic           inst_q_dequeue, inst_q_enqueue, inst_q_full, inst_q_empty;
    iq_struct_t     inst_q_wdata, inst_q_rdata;  

    logic           icache_ufp_read, icache_ufp_resp;
    logic   [31:0]  icache_ufp_addr, icache_ufp_rdata;

    logic   [3:0]   dcache_ufp_rmask, dcache_ufp_wmask;
    logic           dcache_ufp_resp;
    logic   [31:0]  dcache_ufp_addr, dcache_ufp_wdata, dcache_ufp_rdata;


    logic   [31:0]      adapter_addr;
    logic               adapter_read, adapter_write, adapter_resp;
    logic   [255:0]     adapter_rdata, adapter_wdata;

    logic   [31:0]      icache_dfp_addr;
    logic               icache_dfp_read, icache_dfp_write, icache_dfp_resp;
    logic   [255:0]     icache_dfp_rdata, icache_dfp_wdata;

    logic   [31:0]      dcache_dfp_addr;
    logic               dcache_dfp_read, dcache_dfp_write, dcache_dfp_resp;
    logic   [255:0]     dcache_dfp_rdata, dcache_dfp_wdata;

    CDB_t       alu_cdb, mul_cdb, div_cdb, load_cdb, store_cdb; 

    logic               alu_station_full;
    logic               mul_station_full;
    logic               div_station_full;
    logic         [2:0] case_type;


    logic           flush;
    logic   [31:0]  updated_pc;
    logic   [63:0]  updated_order;

    bp_state_t  curr_bp_state; 
    logic   predictor_used, tournament_output, misprediction;

    logic    [31:0]     predicted_pc_next;
    logic               decode_pc_we;

    logic   [$clog2(PHT_DEPTH)-1:0]  read_idx, read_idx_2;
    bp_state_t                      bp_curr_state, bp_prev_state, gshare_bp_curr_state;
    logic   [$clog2(LHT_DEPTH)-1:0] curr_pattern, prev_pattern, gshare_read_idx, gshare_write_idx;  

    logic   [$clog2(LHT_DEPTH)-1:0] ghr;
    // connections to exe
    logic   [$clog2(PHT_DEPTH)-1:0]  write_idx;
    logic                           branch_we;
    logic                           branch_taken;

    logic    [31:0]         res_station_age;

    logic   [31:0]                  load_store_age; 
    logic       [31:0]              store_age_order[4]; 
    logic                           store_valid_order   [4];
    logic                           store_ps2_valid_order   [4];
    logic                           store_valid         [4];
    logic       [31:0]              store_addr    [4];
    logic       [31:0]              store_val    [4];
    logic       [2:0]               store_funct3 [4];

    logic   [5:0]    ps1_st_addr1;
    logic   [5:0]    ps1_st_addr2;
    logic   [5:0]    ps1_st_addr3;
    logic   [5:0]    ps1_st_addr4;
    logic   [31:0] ps1_v_st_addr1;
    logic   [31:0] ps1_v_st_addr2;
    logic   [31:0] ps1_v_st_addr3;
    logic   [31:0] ps1_v_st_addr4;

    logic   [5:0]    ps2_st_addr1;
    logic   [5:0]    ps2_st_addr2;
    logic   [5:0]    ps2_st_addr3;
    logic   [5:0]    ps2_st_addr4;
    logic   [31:0] ps2_v_st_addr1;
    logic   [31:0] ps2_v_st_addr2;
    logic   [31:0] ps2_v_st_addr3;
    logic   [31:0] ps2_v_st_addr4;

    logic   [5:0]    ps1_ld_addr1;
    logic   [5:0]    ps1_ld_addr2;
    logic   [5:0]    ps1_ld_addr3;
    logic   [5:0]    ps1_ld_addr4;
    logic   [31:0]   ps1_v_ld_addr1;
    logic   [31:0]   ps1_v_ld_addr2;
    logic   [31:0]   ps1_v_ld_addr3;
    logic   [31:0]   ps1_v_ld_addr4;


    // logic   [$clog2(BTB_DEPTH)-1:0]     btb_read_idx;
    // logic   [31:0]                      btb_pc_next;

    // logic                               pc_next_misprediction;
    // logic   [$clog2(BTB_DEPTH)-1:0]     btb_write_idx;
    // logic   [31:0]                      btb_write_pc;
    // logic                               btb_valid_read;


    instruction_queue   #(.WIDTH(IQUEUE_WIDTH), .DEPTH(IQUEUE_DEPTH)) instuction_queue(
                                                                            .*, 
                                                                            .enqueue(inst_q_enqueue), 
                                                                            .dequeue(inst_q_dequeue), 
                                                                            .rdata(inst_q_rdata),
                                                                            .wdata(inst_q_wdata), 
                                                                            .empty(inst_q_empty), 
                                                                            .full(inst_q_full)
                                                                            // .head(inst_q_head)
                                                                            );

    

    adapter                             adapter(.*);

    cacheline_arbiter   cacheline_arbiter(.*);

    cache   dcache(.*, .ufp_addr(dcache_ufp_addr), .ufp_rmask(dcache_ufp_rmask),.ufp_wmask(dcache_ufp_wmask), .ufp_rdata(dcache_ufp_rdata), .ufp_wdata(dcache_ufp_wdata), .ufp_resp(dcache_ufp_resp),
                                        .dfp_addr(dcache_dfp_addr), .dfp_read(dcache_dfp_read), .dfp_write(dcache_dfp_write), .dfp_rdata(dcache_dfp_rdata), .dfp_wdata(dcache_dfp_wdata), .dfp_resp(dcache_dfp_resp));
    
    logic   [31:0]  icache_prefetch_addr;
    logic           icache_prefetch_rmask;
    logic   [31:0]  icache_prefetch_rdata;
    logic           icache_prefetch_resp;
    logic   [255:0] icache_rdata_line;

    icache   icache(.*, .ufp_addr(icache_prefetch_addr), .ufp_rmask({icache_prefetch_rmask, icache_prefetch_rmask, icache_prefetch_rmask, icache_prefetch_rmask}), .ufp_wmask('0), .ufp_rdata(icache_prefetch_rdata), .ufp_rdata_line(icache_rdata_line), .ufp_wdata('0), .ufp_resp(icache_prefetch_resp),
                                        .dfp_addr(icache_dfp_addr), .dfp_read(icache_dfp_read), .dfp_write(icache_dfp_write), .dfp_rdata(icache_dfp_rdata), .dfp_wdata(icache_dfp_wdata), .dfp_resp(icache_dfp_resp));

    // cache   icache(.*, .ufp_addr(icache_ufp_addr), .ufp_rmask({icache_ufp_read, icache_ufp_read, icache_ufp_read, icache_ufp_read}),.ufp_wmask('0), .ufp_rdata(icache_ufp_rdata), .ufp_wdata('0), .ufp_resp(icache_ufp_resp),
    //                                     .dfp_addr(icache_dfp_addr), .dfp_read(icache_dfp_read), .dfp_write(icache_dfp_write), .dfp_rdata(icache_dfp_rdata), .dfp_wdata(icache_dfp_wdata), .dfp_resp(icache_dfp_resp));


    icache_prefetch     icache_prefetch(.*,.ufp_addr(icache_ufp_addr), .ufp_rmask({icache_ufp_read, icache_ufp_read, icache_ufp_read, icache_ufp_read}), .ufp_rdata(icache_ufp_rdata), .ufp_resp(icache_ufp_resp), 
                                            .dfp_addr(icache_prefetch_addr), .dfp_read(icache_prefetch_rmask), .dfp_rdata(icache_prefetch_rdata), .dfp_rdata_line(icache_rdata_line), .dfp_resp(icache_prefetch_resp));

    logic                           free_list_dequeue, free_list_enqueue, free_list_full, free_list_empty;
    logic   [FREE_LIST_WIDTH-1:0]  free_list_wdata, free_list_rdata;  
    

    free_list   #(.WIDTH(FREE_LIST_WIDTH), .DEPTH(FREE_LIST_DEPTH)) free_list(
                                                                            .*, 
                                                                            .enqueue(free_list_enqueue), 
                                                                            .dequeue(free_list_dequeue), 
                                                                            .rdata(free_list_rdata), 
                                                                            .wdata(free_list_wdata), 
                                                                            .empty(free_list_empty), 
                                                                            .full(free_list_full)
                                                                            );

    logic                           rob_dequeue, rob_enqueue, rob_full, rob_empty, valid_front, alu_commit_we, mul_commit_we, div_commit_we;
    rob_entry_t  rob_wdata, rob_rdata;
    logic   [$clog2(ROB_QUEUE_DEPTH)-1:0] alu_commit_entry, mul_commit_entry, div_commit_entry, rob_tail, rob_head;  
    rvfi_mem_signals_t          curr_mem_operation, mem_rvfi_output, curr_mem_operation_store;     
    
    rob_queue   #(.WIDTH(ROB_QUEUE_WIDTH), .DEPTH(ROB_QUEUE_DEPTH)) rob(
                                                                            .*, 
                                                                            .enqueue(rob_enqueue), 
                                                                            .dequeue(rob_dequeue), 
                                                                            .rdata(rob_rdata), 
                                                                            .wdata(rob_wdata), 
                                                                            .empty(rob_empty), 
                                                                            .full(rob_full),
                                                                            .alu_commit_we(alu_cdb.regf_we),
                                                                            .alu_commit_entry(alu_cdb.rob_entry),
                                                                            .alu_branch_taken(alu_cdb.branch_taken),
                                                                            .update_pc_next(alu_cdb.update_pc_next),
                                                                            .pc_next_val(alu_cdb.pc_next),
                                                                            .mul_commit_we(mul_cdb.regf_we),
                                                                            .mul_commit_entry(mul_cdb.rob_entry),
                                                                            .div_commit_we(div_cdb.regf_we),
                                                                            .div_commit_entry(div_cdb.rob_entry),
                                                                            .ls_commit_we(load_cdb.regf_we),
                                                                            .ls_commit_entry(load_cdb.rob_entry),
                                                                            .st_commit_we(store_cdb.regf_we),
                                                                            .st_commit_entry(store_cdb.rob_entry),
                                                                            .valid_front(valid_front),
                                                                            .tail(rob_tail),
                                                                            .head(rob_head)
                                                                            );


    fetch   fetch(.*);

    pattern_history_table   pattern_history_table(.*);

    local_history_table     gshare(.*, .read_idx(gshare_read_idx), .write_idx(gshare_write_idx), .bp_curr_state(gshare_bp_curr_state));

    tournament  tournament(.*);

    // btb btb(.*);
    
    logic   [AR_WIDTH-1:0]  rs1, rs2, rd;
    logic   [PR_WIDTH-1:0]  ps1, ps2, pd;
    logic                   ps1_valid, ps2_valid, rat_we;
    logic   [PR_WIDTH-1:0]  discarded_pd;
    res_station_struct_t    decode_to_rs;
    logic                   incoming_from_decode;

    ls_queue_entry_t        decode_to_load_queue;
    logic                   load_enqueue;
    logic                   load_queue_full;

    ls_queue_entry_t        decode_to_store_queue;
    logic                   store_enqueue;
    logic                   store_queue_full;

    logic                   res_station_full;
    logic     [5:0]         ps1_alu, ps2_alu, ps1_mul, ps2_mul, ps1_div,  ps2_div, ps1_ls, ps2_ls; 
    logic     [5:0]         ps1_st, ps2_st; 

    // connections to functional units
    res_station_entry_t     instr_execution_alu, instr_execution_mul, instr_execution_div;

    logic                   incoming_alu, incoming_mul, incoming_div, alu_ready, mul_ready, div_ready;      

    logic   [31:0]  ps1_v_alu, ps2_v_alu;
    logic   [31:0]  ps1_v_mul, ps2_v_mul;
    logic   [31:0]  ps1_v_div, ps2_v_div;
    logic   [31:0]  ps1_v_ls, ps2_v_ls;
    logic   [31:0]  ps1_v_st, ps2_v_st;

    split_lsq_t                  load_queue_req;
    split_lsq_t                  store_queue_req;
    logic                        load_req;
    logic                        store_req;
    logic                        load_ack;
    logic                        store_ack;

    logic alu_wb_valid, mul_wb_valid, div_wb_valid; 
    execution_out_t alu_execution_val, mul_execution_val, div_execution_val;
    logic   [5:0]   commit_ps1, commit_ps2, commit_pd;
    logic   [31:0]  commit_ps1_v, commit_ps2_v, commit_pd_v;

    decode  decode(.*);

    reservation_stations res_station(.*, .alu_cdb_pd(alu_cdb.pd), .alu_cdb_we(alu_cdb.regf_we),
                                        .mul_cdb_pd(mul_cdb.pd), .mul_cdb_we(mul_cdb.regf_we),
                                        .div_cdb_pd(div_cdb.pd), .div_cdb_we(div_cdb.regf_we),
                                        .load_cdb_pd(load_cdb.pd), .load_cdb_we(load_cdb.regf_we));

    // logic   [PR_WIDTH-1:0]  cdb_pd;
    // logic   [AR_WIDTH-1:0]  cdb_rd;
    // logic                   cdb_regf_we;

    // assign cdb_regf_we = 1'b0;

    rat     rat(.*, .alu_cdb_pd(alu_cdb.pd), .alu_cdb_rd(alu_cdb.rd), .alu_cdb_regf_we(alu_cdb.regf_we),
                    .mul_cdb_pd(mul_cdb.pd), .mul_cdb_rd(mul_cdb.rd), .mul_cdb_regf_we(mul_cdb.regf_we),
                    .div_cdb_pd(div_cdb.pd), .div_cdb_rd(div_cdb.rd), .div_cdb_regf_we(div_cdb.regf_we),
                    .load_cdb_pd(load_cdb.pd), .load_cdb_rd(load_cdb.rd), .load_cdb_regf_we(load_cdb.regf_we));

    regfile regfile(.*, .alu_regf_we(alu_cdb.regf_we), .alu_pv(alu_cdb.pv), .alu_pd(alu_cdb.pd),
                    .mul_regf_we(mul_cdb.regf_we), .mul_pv(mul_cdb.pv), .mul_pd(mul_cdb.pd),
                    .div_regf_we(div_cdb.regf_we), .div_pv(div_cdb.pv), .div_pd(div_cdb.pd),
                    .ls_regf_we(load_cdb.regf_we), .ls_pv(load_cdb.pv), .ls_pd(load_cdb.pd));

    execute execute (.*); 

    writeback writeback (.*); 

    logic        rvfi_valid;
    logic [63:0] rvfi_order;
    logic [31:0] rvfi_inst;
    logic [4:0]  rvfi_rs1_addr;
    logic [4:0]  rvfi_rs2_addr;
    logic [31:0] rvfi_rs1_rdata;
    logic [31:0] rvfi_rs2_rdata;
    logic [4:0]  rvfi_rd_addr;
    logic [31:0] rvfi_rd_wdata;
    logic [31:0] rvfi_pc_rdata;
    logic [31:0] rvfi_pc_wdata;
    logic [31:0] rvfi_mem_addr;
    logic [31:0] rvfi_mem_rdata;
    logic [31:0] rvfi_mem_wdata;
    logic [3:0]  rvfi_mem_rmask;
    logic [3:0]  rvfi_mem_wmask;

    logic [PR_WIDTH-1:0]  rrf_rdata[32];

    rrf       rrf(.*);

    load_queue    load_queue(.*, .load_enqueue(load_enqueue), .wdata(decode_to_load_queue), .load_full(load_queue_full));
    store_queue   store_queue(.*, .store_enqueue(store_enqueue), .wdata(decode_to_store_queue), .store_full(store_queue_full), .ps1_ls(ps1_st), .ps2_ls(ps2_st), .ps1_v_ls(ps1_v_st), .ps2_v_ls(ps2_v_st));
    split_lsq_arbiter split_lsq_arbiter(.*); 

    
endmodule : cpu


//rob - goes to reset state during flush
//rat <- rrf - restore rat from RRAT 
//res station - goes to reset state, does not send anything to functional units
//ls_queue - need to mask first dcache resp and clear queue 
//instruction queue - goes to reset state during flush
//free_list (becomes full) - goes to reset state
//fetch (gets new pc) - mask icache resp and take updated PC val
//functional units - invalidate all calculated outputs