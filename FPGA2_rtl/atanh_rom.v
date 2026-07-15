// ================================================================
// CORDIC Hyperbolic Mode e^x Calculator
// Author: lib
// Date: 2025-06-16
// Description: 16-iteration CORDIC hyperbolic mode algorithm 
// ================================================================

module atanh_rom (
    input  [5:0] iter_idx,           
    output reg signed [31:0] data_out 
);

always @(*) begin
    case(iter_idx)
        6'd1:  data_out = 32'h00008C9F;  // atanh(2^-1) = atanh(0.5) = 0.549306144... * 2^16
        6'd2:  data_out = 32'h00004163;  // atanh(2^-2) = atanh(0.25) = 0.255412812... * 2^16
        6'd3:  data_out = 32'h0000202B;  // atanh(2^-3) = atanh(0.125) = 0.125657214... * 2^16
        6'd4:  data_out = 32'h00001005;  // atanh(2^-4) = atanh(0.0625) = 0.062581571... * 2^16
        6'd5:  data_out = 32'h00000801;  // atanh(2^-5) = atanh(0.03125) = 0.031260134... * 2^16
        6'd6:  data_out = 32'h00000400;  // atanh(2^-6) = atanh(0.015625) = 0.015628263... * 2^16
        6'd7:  data_out = 32'h00000200;  // atanh(2^-7) = atanh(0.0078125) = 0.007813654... * 2^16
        6'd8:  data_out = 32'h00000100;  // atanh(2^-8) = atanh(0.00390625) = 0.003906574... * 2^16
        6'd9:  data_out = 32'h00000080;  // atanh(2^-9) = atanh(0.001953125) = 0.001953230... * 2^16
        6'd10:  data_out = 32'h00000040;  // atanh(2^-10) = atanh(0.0009765625) = 0.000976597... * 2^16
        6'd11: data_out = 32'h00000020;  // atanh(2^-11) = atanh(0.00048828125) = 0.000488298... * 2^16
        6'd12: data_out = 32'h00000010;  // atanh(2^-12) = atanh(0.000244140625) = 0.000244149... * 2^16
        6'd13: data_out = 32'h00000008;  // atanh(2^-13) = atanh(0.0001220703125) = 0.000122074... * 2^16
        6'd14: data_out = 32'h00000004;  // atanh(2^-14) = atanh(0.00006103515625) = 0.000061037... * 2^16
        6'd15: data_out = 32'h00000002;  // atanh(2^-15) = atanh(0.000030517578125) = 0.000030518... * 2^16
        6'd16: data_out = 32'h00000001;  // atanh(2^-16) = atanh(0.0000152587890625) = 0.000015259... * 2^16
        default: data_out = 32'h00000000;
    endcase
end

endmodule
