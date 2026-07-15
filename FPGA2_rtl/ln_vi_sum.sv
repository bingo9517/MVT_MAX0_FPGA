`include "./param.v"
module ln_vi_sum(
	input  clk_200m,
	input  reset_200m,
	input  [2*(`MVT_CHANNEL)-1:0] [27:0] ln_vi,
	input  valid_in,
	output valid_out,
	output [28 + $clog2(2*(`MVT_CHANNEL))-1:0] sum
);

	sum_generic #(
        .DATA_WIDTH(28),
        .NUM_INPUTS(2*(`MVT_CHANNEL))
	) sum_generic_inst (
    .clk(clk_200m),
	.rst_n(reset_200m),
	.data_in(ln_vi),
	.valid_in(valid_in),
	.sum_out(sum),
	.valid_out(valid_out)
    );
	
endmodule
