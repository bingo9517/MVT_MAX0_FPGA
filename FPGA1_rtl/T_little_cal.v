module T_little_cal(
	input clk_200m,
	input reset_200m,
	input [23:0] T_in,
	input [15:0] T_common,
	input [17:0] T_multi,
	output wire [25:0] T_o
	);
	wire [23:0]T_TEMP;
	//wire [31:0]T_TEMP_1;
	assign T_TEMP = T_in - T_common;
	//assign T_TEMP_1 = (T_TEMP << 8);
	
	wire [41:0] result_sig;
	//1 latency
	multi_24x18bit	multi_24x18bit_inst (
	.clock ( clk_200m ),
	.aclr ( ~reset_200m ),
	.dataa ( T_TEMP ),
	.datab ( T_multi ),
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
*/	
	assign T_o = result_sig >>> 16;//x*171799/2^32*2^16,Qx.16
endmodule
