module tournament
import rv32i_types::*;
import params::*;
(
    input   logic               clk,
    input   logic               rst,

    input   logic               branch_we,
    input   logic               misprediction,
    input   logic               predictor_used, // 0 -> 2 level and 1 -> gshare

    output  logic               tournament_output
    
);

logic   [1:0]       tournament_state, tournament_state_next;
// 00, 01 -> 2 level
//10, 11 -> gshare

assign tournament_output = (tournament_state < 2'd2) ? 1'b0 : 1'b1;
// assign tournament_output = 1'b1;

always_ff @(posedge clk) begin 
    if (rst) begin 
        tournament_state <= 2'b10;
    end else begin 
        tournament_state <= tournament_state_next;
    end
end

always_comb begin 
    tournament_state_next = tournament_state;

    if (branch_we) begin 
        case (tournament_state) 
            2'b00: begin 
                if (predictor_used)  
                    tournament_state_next = misprediction ? 2'b00 : 2'b01;
                else
                    tournament_state_next = misprediction ? 2'b01 : 2'b00;
            end

            2'b01: begin 
                if (predictor_used)  
                    tournament_state_next = misprediction ? 2'b00 : 2'b10;
                else
                    tournament_state_next = misprediction ? 2'b10 : 2'b00;
            end

            2'b10: begin 
                if (predictor_used)  
                    tournament_state_next = misprediction ? 2'b01 : 2'b11;
                else
                    tournament_state_next = misprediction ? 2'b11 : 2'b01;
            end

            2'b11: begin 
                if (predictor_used)  
                    tournament_state_next = misprediction ? 2'b10 : 2'b11;
                else
                    tournament_state_next = misprediction ? 2'b11 : 2'b10;
            end
            
            default: tournament_state_next = tournament_state;
        endcase
    end
end


   

endmodule : tournament
