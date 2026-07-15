 
 module Coarse_counter3(
	input wire clk,
	input wire rst_n,
	input start,
	//input valid,
	output reg [15:0] counter
);

/*
 	reg r_async_flag;
	wire w_ack_clear;
	reg r_sync_d1, r_sync_d2;
	wire valid;

	always @(posedge start or posedge w_ack_clear or negedge rst_n) begin
		if(!rst_n) begin
			r_async_flag <= 1'b0;
		end
		else if(w_ack_clear) begin
			r_async_flag <=1'b0;
		end
		else begin
			r_async_flag <= 1'b1;
		end 
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_sync_d1 <= 1'b0;
			r_sync_d2 <= 1'b0;
		end
		else begin
			r_sync_d1 <= r_async_flag;
			r_sync_d2 <= r_sync_d1;
		end
	end

	assign w_ack_clear = r_sync_d2;

	assign valid = r_sync_d1 && ~r_async_flag;
*/
	always @(posedge clk or  negedge rst_n )
	begin
		if(!rst_n)
		begin
			counter <= 'd0;
		end
		else if(start)
		begin
			counter <= 'd0;
		end	
		else
		begin
			counter <= counter + 1'b1;
		end
  end

endmodule