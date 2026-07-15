`include "./param.v"
module ti_ln_ti_sum(
	input [2*(`MVT_CHANNEL)-1:0] [17:0] ti,//Q10.8
	input wire signed [2*(`MVT_CHANNEL)-1:0] [27:0] ln_ti,//Q4.24
	input  clk_200m,
	input  reset_200m,
	input  valid_in,
	output valid_out,
	output [38+$clog2(2*(`MVT_CHANNEL))-1 : 0] sum//Qx.24
);

	wire signed [2*(`MVT_CHANNEL)-1:0] [45:0] result_sig;
	
	genvar i;
	generate
	for(i = 0; i < 2*(`MVT_CHANNEL); i = i + 1)
	begin : ti_ln_ti_cal_gen
		multi_18x28bit_sign	multi_18x28bit_sign_inst (
			.clock ( clk_200m ),
			.aclr ( ~reset_200m ),
			.dataa ( ti[i][17:0] ),
			.datab ( ln_ti[i][27:0] ),
			.result ( result_sig[i][45:0] )
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


	wire [2*(`MVT_CHANNEL)-1:0] [37:0] data_in_packed;
	genvar gi;
	generate
  		for (gi = 0; gi < 2*(`MVT_CHANNEL); gi = gi + 1) begin: data_in_pack_gen
   		assign data_in_packed[gi][37:0] = result_sig[gi][45:8];
  	end
	endgenerate

   	sum_generic_signed #(
        .DATA_WIDTH(38),
        .NUM_INPUTS(2*(`MVT_CHANNEL))
	) sum_generic_signed_inst (
 	    .clk(clk_200m),
		.rst_n(reset_200m),
		.data_in(data_in_packed),
		.valid_in(valid_in_d),
		.sum_out(sum),
		.valid_out(valid_out)
	);


endmodule
