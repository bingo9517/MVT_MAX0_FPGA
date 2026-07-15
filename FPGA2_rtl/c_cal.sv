module c_cal(
	input signed [31:0] s3_final,
	input signed [31:0] k3_final,
	input clk_200m,
	input reset_200m,
	input s3_final_valid,
	input k3_final_valid,
	output o_valid,
	output signed [31:0] c//Qx.24
);

    reg signed [31:0]  s3_final_reg, k3_final_reg;
    reg        s3_final_ready, k3_final_ready;
	wire valid;
    // latch s3_final
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s3_final_reg   <= 'd0;
            s3_final_ready <= 0;
        end else if (valid) begin
            s3_final_ready <= 1'b0;  
        end
        else if (s3_final_valid) begin
            s3_final_reg   <= s3_final;
            s3_final_ready <= 1'b1;  
        end 

    end

    // latch k3_final
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            k3_final_reg   <= 'd0;
            k3_final_ready <= 0;
        end else if (valid) begin
            k3_final_ready <= 1'b0;  
        end
        else if (k3_final_valid) begin
            k3_final_reg   <= k3_final;
            k3_final_ready <= 1'b1;  
        end 

    end


	wire signed [31:0] quotient_sig;
	wire signed [31:0] remain_sig;

	assign valid = s3_final_ready && k3_final_ready;


	divide_32_32bit_sign divide_32_32bit_sign_inst (
    .clock ( clk_200m ),
	.aclr ( ~reset_200m ),
	.denom ( k3_final_reg ),
	.numer ( s3_final_reg ),
	.quotient ( quotient_sig ),
	.remain ( remain_sig )
	);

    wire valid_d;
	pipe_stage #(
	  .DATA_WIDTH(1),
	  .STAGES (8),
	  .RESET_VALUE (0)
	) pipe_stage_inst (
	  .i_clk        (clk_200m),
	  .i_rst_n      (reset_200m),
	  .i_data       (valid),
	  .o_data       (valid_d)
	);
	
    wire signed [55:0] c_temp; //Qx.24
	
	IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(32),
        .OPERAND_WIDTH (32),
        .FRACTIONAL_BITS (24),
        .PIPELINE_STAGES (8)
	) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (k3_final_reg),
        .o_valid     (o_valid),
        .o_q_out     (c_temp)
    );
	
	assign c = c_temp[31:0]; 


endmodule
