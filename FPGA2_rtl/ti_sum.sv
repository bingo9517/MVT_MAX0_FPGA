`include "./param.v"
module ti_sum(
	input clk_200m,
	input reset_200m,
	input ti_valid,
	input  [2*(`MVT_CHANNEL)-1:0] [17:0] t,//Q10.8
	output valid_out,
	output [18+$clog2(2*(`MVT_CHANNEL))-1:0] t_sum
);
   	sum_generic #(
        .DATA_WIDTH(18),
        .NUM_INPUTS(2*(`MVT_CHANNEL))
	) sum_generic_inst (
    .clk(clk_200m),
	.rst_n(reset_200m),
	.data_in(t),
	.valid_in(ti_valid),
	.sum_out(t_sum),
	.valid_out(valid_out)
    );


endmodule
