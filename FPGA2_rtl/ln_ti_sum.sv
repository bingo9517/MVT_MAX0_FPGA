`include "./param.v"
module ln_ti_sum(
	input  clk_200m,
	input  reset_200m,
	input  wire signed [2*(`MVT_CHANNEL)-1:0] [27:0] ln_ti,
	input  valid_in,
	output valid_out,
	output signed [28+$clog2(2*(`MVT_CHANNEL))-1 : 0] ln_ti_sum
);

	
    sum_generic_signed #(
        .DATA_WIDTH(28), // Q4.24
        .NUM_INPUTS(2*(`MVT_CHANNEL))
	) sum_generic_signed_inst (
    .clk(clk_200m),
	.rst_n(reset_200m),
	.data_in(ln_ti),
	.valid_in(valid_in),
	.sum_out(ln_ti_sum),
	.valid_out(valid_out)
    );

endmodule
