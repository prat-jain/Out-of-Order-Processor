module icache_prefetch
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    output  logic   [31:0]  ufp_rdata,
    output  logic           ufp_resp,

    // icache side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    input   logic   [31:0]  dfp_rdata,
    input   logic   [255:0] dfp_rdata_line,
    input   logic           dfp_resp
);

    enum logic [2:0] {
        IDLE, HIT, MISS, PREFETCH, PREFETCH_HIT, PREFETCH_RESP
    } state, state_next;

    logic   [255:0] data_line;
    logic   [255:0] data_line_reg;
    logic           data_line_we;

    logic   [31:0]  ufp_addr_reg;
    logic           ufp_addr_we;
    logic   [26:0]  tag;
    logic   [26:0]  tag_reg;
    logic           tag_we;

    logic           hit;

    logic   [31:0]  req_while_prefetch_reg;
    logic           req_while_prefetch_flag;
    logic           req_while_prefetch_we;
    logic           start_prefetch;
    logic           start_prefetch_reg;
    logic           end_prefetch;

    always_ff @(posedge clk) begin
        if (rst) begin
            data_line_reg <= '0;
            tag_reg <= '0;
            req_while_prefetch_reg <= '0;
            req_while_prefetch_flag <= '0;
            state <= IDLE;
            start_prefetch_reg <= '0;
        end else begin
            if (data_line_we) data_line_reg <= data_line;
            if (tag_we) tag_reg <= tag;
            if (ufp_addr_we) ufp_addr_reg <= ufp_addr;
            if (req_while_prefetch_we) begin
                req_while_prefetch_reg <= ufp_addr;
                req_while_prefetch_flag <= 1'b1;
            end
            if (end_prefetch) begin
                req_while_prefetch_flag <= 1'b0;
            end
            start_prefetch_reg <= start_prefetch;
            state <= state_next;
        end
    end

    always_comb begin
        dfp_addr = ufp_addr;
        dfp_read = ufp_rmask[0];
        ufp_rdata = dfp_rdata;
        ufp_resp = dfp_resp;
        data_line_we = '0;
        tag_we = '0;
        tag = '0;
        data_line = '0;
        ufp_addr_we = 1'b0;
        req_while_prefetch_we = 1'b0;
        end_prefetch = 1'b0;
        start_prefetch = 1'b0;

        state_next = state;

        unique case (state)
            IDLE: begin
                if (ufp_rmask[0]) begin
                    ufp_addr_we = 1'b1;
                    if (tag_reg == ufp_addr[31:5]) begin
                        state_next = HIT;
                    end else begin
                        state_next = MISS;
                    end
                end
            end
            HIT: begin
                // dfp_addr = '0;
                // dfp_read = '0;
                ufp_rdata = data_line_reg[ufp_addr_reg[4:2]*32+:32];
                ufp_resp = 1'b1;

                if (ufp_rmask[0]) begin
                    ufp_addr_we = 1'b1;
                    if (tag_reg == ufp_addr[31:5]) begin
                        state_next = HIT;
                    end else begin
                        state_next = MISS;
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            MISS: begin
                if (!dfp_resp) begin
                    state_next = MISS;
                end else begin 
                    tag = ufp_addr_reg[31:5];
                    data_line = dfp_rdata_line;
                    if (tag_reg != ufp_addr_reg[31:5]) begin
                        tag_we = 1'b1;
                        data_line_we = 1'b1;
                    end

                    if (ufp_rmask[0]) begin
                        ufp_addr_we = 1'b1;
                        if (ufp_addr_reg[31:5] == ufp_addr[31:5]) begin
                            state_next = PREFETCH_HIT;
                            start_prefetch = 1'b1;
                        end else begin
                            state_next = MISS;
                        end
                    end else begin
                        state_next = PREFETCH;
                        start_prefetch = 1'b1;
                    end
                end
            end
            PREFETCH: begin
                start_prefetch = 1'b0;
                dfp_addr = {tag_reg+1'b1, 5'b0}; // plus 4
                dfp_read = 1'b1;
                ufp_rdata = '0;
                ufp_resp = '0;

                if (ufp_rmask[0]) begin // new ufp req while prefetching
                   req_while_prefetch_we = 1'b1; // save ufp_addr
                   ufp_addr_we = 1'b1;
                end
                if (dfp_resp) begin
                    dfp_read = 1'b0;
                    state_next = PREFETCH_RESP;
                end
            end
            PREFETCH_HIT: begin
                start_prefetch = 1'b0;
                dfp_addr = {tag_reg+1'b1, 5'b0}; // plus 4
                dfp_read = 1'b1;
                ufp_rdata = data_line_reg[ufp_addr_reg[4:2]*32+:32];
                ufp_resp = 1'b1;
                
                if (!dfp_resp || start_prefetch_reg) begin
                    if (ufp_rmask[0] && !req_while_prefetch_flag) begin
                        ufp_addr_we = 1'b1;
                        if (tag_reg == ufp_addr[31:5]) begin
                            state_next = PREFETCH_HIT;
                        end else begin
                            state_next = PREFETCH;
                            req_while_prefetch_we = 1'b1; // save ufp_addr
                        end
                    end else begin
                        state_next = PREFETCH;
                    end
                end else begin
                    if (ufp_rmask[0] && !req_while_prefetch_flag) begin
                        ufp_addr_we = 1'b1;
                        if (tag_reg == ufp_addr[31:5]) begin
                            state_next = HIT;
                            end_prefetch = 1'b1;
                        end else begin
                            state_next = PREFETCH_RESP;
                            req_while_prefetch_we = 1'b1;
                        end
                    end else begin
                        state_next = PREFETCH_RESP;
                    end
                end
            end
            PREFETCH_RESP: begin
                end_prefetch = 1'b1;
                ufp_rdata = data_line_reg[ufp_addr_reg[4:2]*32+:32];
                ufp_resp = 1'b1;
                
                if (req_while_prefetch_flag) begin
                    dfp_addr = req_while_prefetch_reg;
                    dfp_read = 1'b1;
                    ufp_rdata = '0;
                    ufp_resp = '0;

                    if (tag_reg == req_while_prefetch_reg[31:5]) begin
                        state_next = HIT;
                    end else begin
                        state_next = MISS;
                    end

                end else begin
                    if (ufp_rmask[0]) begin
                        ufp_addr_we = 1'b1;
                        if (tag_reg == ufp_addr[31:5]) begin
                            state_next = HIT;
                        end else begin
                            state_next = MISS;
                        end
                    end else begin
                        state_next = IDLE;
                    end
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase

    end



endmodule
