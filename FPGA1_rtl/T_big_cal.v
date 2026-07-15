module T_big_cal(
	input clk_200m,
	input reset_200m,
	input [15:0] T_in,
	input [15:0] T_common,
	input [15:0] T_multi,
	output wire [27:0] T_o
	);
	wire [15:0]T_TEMP;
	// wire [15:0]T_TEMP_1;
	assign T_TEMP = T_in - T_common;
	// assign T_TEMP_1 = (T_TEMP << 8);
	
	wire [31:0] result_sig;
	//1 latency
	multi_16x16bit	multi_16x16bit_inst (
	.clock ( clk_200m ),
	.aclr ( ~reset_200m ),
	.dataa ( T_multi ),
	.datab ( T_TEMP ),
	.result ( result_sig )
	);
/*	
	wire	[25:0] quotient;
	wire	[9:0]  remain;
	divide_1000 divide_1000_inst(
			.denom		(10'd1000),
			.numer		(result_sig),
			.quotient	(quotient),
			.remain		(remain)
	);
	
	assign T_o = (remain > 0) ? (quotient + 1) : quotient;
	*/
	
	assign T_o = {result_sig[27:0]};
endmodule