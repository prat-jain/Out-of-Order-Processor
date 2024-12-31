module lru_encode
import rv32i_types::*;
(
    input   logic    [2:0]  curr_lru,
    output   logic    [2:0]  new_lru,
    output   logic    [1:0]  way_evict
);

// L2L1L0
// L2: ROOT, L1: LEFT TREE, L0: RIGHT TREE

always_comb begin
    new_lru[2] = ~curr_lru[2]; 
    new_lru[1] = curr_lru[1]; 
    new_lru[0] = curr_lru[0];
    if (curr_lru[2] == 1'b1) begin
        new_lru[1] = ~curr_lru[1]; 
        way_evict = {new_lru[2], new_lru[1]};  
    end else begin
        new_lru[0] = ~curr_lru[0]; 
        way_evict = {new_lru[2], new_lru[0]};  
    end

end

endmodule