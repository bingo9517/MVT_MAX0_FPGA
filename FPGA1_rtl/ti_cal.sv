`include "./param.v"
module ti_cal(
	input clk_200m,
	input reset_200m,
	input 	[2*(`MVT_THRESHOLDS_1)-1:0] [15:0] T_big,
	input 	[2*(`MVT_THRESHOLDS_1)-1:0] [23:0]  T_little,
	output reg [2*(`MVT_THRESHOLDS)-1:0] [17:0] t
);
  wire [2*(`MVT_THRESHOLDS_1)-1:0] [27:0] T_1;
  //wire [27:0] delta_t;
  //wire [2*(`MVT_THRESHOLDS_1)-1:0] [15:0] T_2;
  genvar i;
  generate
	for(i = 0; i < 2*(`MVT_THRESHOLDS_1); i = i + 1)
	begin : T_big_cal_gen
		T_big_cal T_bit_cal_inst(
			.clk_200m ( clk_200m ),
			.reset_200m ( reset_200m ),
			.T_in		(T_big[i][15:0]),
			.T_common	(T_big[i][15:0] ? (T_big[0][15:0] - 16'd1) : 16'd0),
			//.T_multi	(12'h9c4),		//2500
			//.T_multi	(16'h500),		//5ns
			//.T_multi	(16'hB1C),		//11.11ns
			.T_multi 	(16'hA00),		//10ns,Qx.8
			.T_o		(T_1[i][27:0])
		);
		//assign T_2[i][15:0] = T_1[i][15:0] << 1;	//200MHz
	end
   endgenerate
	
  wire [2*(`MVT_THRESHOLDS_1)-1:0] [25:0] t1_1;
  genvar j;
  generate
	for(j = 0; j < 2*(`MVT_THRESHOLDS_1); j = j + 1)
	begin : T_little_cal_gen
		T_little_cal T_little_cal_inst(
			.clk_200m ( clk_200m ),
			.reset_200m ( reset_200m ),
			.T_in		(T_little[j]),
			.T_multi	(18'h29f17),		//x*171799/2^32
                        //.T_multi	(18'h29F1),		//x*4295/2^32
			//.T_multi	(8'h5a),		//90ps
			.T_common	(16'd0),
			.T_o		(t1_1[j][25:0])
		);
	end
   endgenerate

   genvar m;
   wire [2*(`MVT_THRESHOLDS_1)-1:0] [27:0] t_temp;
   generate
	for(m = 0; m < 2*(`MVT_THRESHOLDS_1); m = m + 1)
	begin : t_temp_gen
		assign t_temp[m][27:0] = {T_1[m][27:0], 8'b0} - t1_1[m][25:0];//Qx.16
	end
   endgenerate  

  // assign delta_t = t_temp[`MVT_THRESHOLDS_1 - 1][27:0] - t_temp[0][27:0];

   integer k;
   always @(posedge clk_200m or negedge reset_200m) begin
   	if(!reset_200m)begin
   		for(k = 0; k < 2*(`MVT_THRESHOLDS); k = k + 1)
   		begin 
   			t[k][17:0] <= 'b0;
   		end
   	end
   	else begin
   		for(k = 0; k < 2*(`MVT_THRESHOLDS); k = k + 1)
   		begin : t_gen
   			t[k][17:0] <= t_temp[k][25:8];	// Qx.8
   		end
   	end
   end   

endmodule
