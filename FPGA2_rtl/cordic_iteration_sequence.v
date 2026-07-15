// ================================================================
// Author: lib
// Date: 2025-06-16
// Description: CORDIC Iteration Sequence Generator
// ================================================================
module cordic_iteration_sequence(
    input  [5:0] iteration_count,    
    output reg [5:0] actual_i        
);


always @(*) begin
    case(iteration_count)
        6'd0:  actual_i = 6'd1;
        6'd1:  actual_i = 6'd2;
        6'd2:  actual_i = 6'd3;
        6'd3:  actual_i = 6'd4;
        6'd4:  actual_i = 6'd4;
        6'd5:  actual_i = 6'd5;
        6'd6:  actual_i = 6'd6;
        6'd7:  actual_i = 6'd7;
        6'd8:  actual_i = 6'd8;
        6'd9:  actual_i = 6'd9;
        6'd10: actual_i = 6'd10;
        6'd11: actual_i = 6'd11;
        6'd12: actual_i = 6'd12;
        6'd13: actual_i = 6'd13;
        6'd14: actual_i = 6'd13;
        6'd15: actual_i = 6'd14;
	6'd16: actual_i = 6'd15;
	6'd17: actual_i = 6'd16;
        default: actual_i = 6'd0;
    endcase
end

endmodule
