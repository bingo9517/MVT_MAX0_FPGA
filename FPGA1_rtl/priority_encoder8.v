module priority_encoder8
#(
	parameter PRIORITY_BIT  = 0,
	parameter PRIORITY_DATA = 0,
	parameter INPUT_WIDTH   = 8,
	parameter OUTPUT_WIDTH  = 4
)
(
	input                         clk_200m,
	input                         reset_200m,
	input      [INPUT_WIDTH-1:0]  datain,
	
	output reg [OUTPUT_WIDTH-1:0] dataout
);

	reg [OUTPUT_WIDTH-1:0] dataout_temp;
	
	generate
		if(PRIORITY_BIT == 0)
		begin
			if(PRIORITY_DATA == 0)
			begin
				always@(*)
				begin
					casex(datain)
						8'bxxxx_xxx1:	dataout_temp = 4'd0;
						8'bxxxx_xx10:	dataout_temp = 4'd1;
						8'bxxxx_x100:	dataout_temp = 4'd2;
						8'bxxxx_1000:	dataout_temp = 4'd3;
						8'bxxx1_0000:	dataout_temp = 4'd4;
						8'bxx10_0000:	dataout_temp = 4'd5;
						8'bx100_0000:	dataout_temp = 4'd6;
						8'b1000_0000:	dataout_temp = 4'd7;
						8'b0000_0000:	dataout_temp = 4'd8;
						default:		   dataout_temp = 4'd0;
					endcase
				end
			end 
			else 
			begin
				always@(*)begin
					casex(datain)
						8'bxxxx_xxx0:	dataout_temp = 4'd0;
						8'bxxxx_xx01:	dataout_temp = 4'd1;
						8'bxxxx_x011:	dataout_temp = 4'd2;
						8'bxxxx_0111:	dataout_temp = 4'd3;
						8'bxxx0_1111:	dataout_temp = 4'd4;
						8'bxx01_1111:	dataout_temp = 4'd5;
						8'bx011_1111:	dataout_temp = 4'd6;
						8'b0111_1111:	dataout_temp = 4'd7;
						8'b1111_1111:	dataout_temp = 4'd8;
						default:		   dataout_temp = 4'd0;
					endcase
				end
			end
		end 
		else 
		begin
			if(PRIORITY_DATA == 0)
			begin
				always@(*)
				begin
					casex(datain)
						8'b1xxx_xxxx:	dataout_temp = 4'd0;
						8'b01xx_xxxx:	dataout_temp = 4'd1;
						8'b001x_xxxx:	dataout_temp = 4'd2;
						8'b0001_xxxx:	dataout_temp = 4'd3;
						8'b0000_1xxx:	dataout_temp = 4'd4;
						8'b0000_01xx:	dataout_temp = 4'd5;
						8'b0000_001x:	dataout_temp = 4'd6;
						8'b0000_0001:	dataout_temp = 4'd7;
						8'b0000_0000:	dataout_temp = 4'd8;
						default:		   dataout_temp = 4'd0;
					endcase
				end
			end 
			else 
			begin
				always@(*)
				begin
					casex(datain)
						8'b0xxx_xxxx:	dataout_temp = 4'd0;
						8'b10xx_xxxx:	dataout_temp = 4'd1;
						8'b110x_xxxx:	dataout_temp = 4'd2;
						8'b1110_xxxx:	dataout_temp = 4'd3;
						8'b1111_0xxx:	dataout_temp = 4'd4;
						8'b1111_10xx:	dataout_temp = 4'd5;
						8'b1111_110x:	dataout_temp = 4'd6;
						8'b1111_1110:	dataout_temp = 4'd7;
						8'b1111_1111:	dataout_temp = 4'd8;
						default:		   dataout_temp = 4'd0;
					endcase
				end
			end
		end
	endgenerate
	
	always@(posedge clk_200m or negedge reset_200m)
	begin
		if(!reset_200m)
			dataout <= 'd0;
		else
			dataout <= dataout_temp;
	end
endmodule
