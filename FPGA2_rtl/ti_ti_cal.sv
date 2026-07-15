`include "./param.v"
module ti_ti_cal(
	input [2*(`MVT_CHANNEL)-1:0] [17:0] ti,
	input  clk_200m,
	input  reset_200m,
	input  valid_in,
	output valid_out,
	output [44+$clog2(2*(`MVT_CHANNEL))-1:0] sum
);

	wire [2*(`MVT_CHANNEL)-1:0] [35:0] result_sig;
	genvar i;
	generate
	for(i = 0; i < 2*(`MVT_CHANNEL); i = i + 1)
	begin : ti_ti_cal_gen
		multi_18x18bit	multi_18x18bit_inst (
			.clock ( clk_200m ),
			.aclr ( ~reset_200m ),
			.dataa ( ti[i][17:0] ),
			.datab ( ti[i][17:0] ),
			.result ( result_sig[i][35:0] )
		);
	end
	endgenerate

	wire valid_in_d;

	pipe_stage #(
	  .DATA_WIDTH(1),
	  .STAGES (1),
	  .RESET_VALUE (0)
	) pipe_stage_inst (
	  .i_clk        (clk_200m),
	  .i_rst_n      (reset_200m),
	  .i_data       (valid_in),
	  .o_data       (valid_in_d)
	);
	
	wire [2*(`MVT_CHANNEL)-1:0] [43:0] data_in_packed;
	genvar gi;
	generate
  		for (gi = 0; gi < 2*(`MVT_CHANNEL); gi = gi + 1) begin: data_in_pack_gen
   		assign data_in_packed[gi][43:0] = {result_sig[gi][35:0], 8'b0};//Qx.24
  	end
	endgenerate

   	sum_generic #(
        .DATA_WIDTH(44),
        .NUM_INPUTS(2*(`MVT_CHANNEL))
	) sum_generic_inst (
    .clk(clk_200m),
	.rst_n(reset_200m),
	.data_in(data_in_packed),
	.valid_in(valid_in_d),
	.sum_out(sum),
	.valid_out(valid_out)
    );
	

endmodule
