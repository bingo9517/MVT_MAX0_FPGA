
module fix_point_multiplier_wrapper (
	clock,
	//rst,
	dataa,
	datab,
	result);

	input	  clock;
	input	signed [31:0]  dataa;
	input	signed [31:0]  datab;
	output	signed [31:0]  result;
	
    wire    signed [63:0]  result_tmp;
	
	fix_point_multiplier fix_point_multiplier_inst(
	  .clock(clock),
	  .aclr(),
	  .dataa(dataa),
	  .datab(datab),
	  .result(result_tmp)
	);
    
	assign result = result_tmp[47:16] + result_tmp[15];


endmodule
