module s3_final_cal(
	input signed [31:0] s3_new,
	input signed [31:0] j3_new,
	input signed [31:0] s2_new,
	input signed [31:0] j2_new,
	input s3_new_valid,
	input j3_new_valid,
	input s2_new_valid,
	input j2_new_valid,
	input clk_200m,
	input reset_200m,
	output o_valid,
	output signed [31:0] s3_final
);

    reg signed [31:0]  s3_new_reg, s2_new_reg;
    reg signed [31:0]  j3_new_reg, j2_new_reg;
    reg        s3_new_ready, j3_new_ready, s2_new_ready, j2_new_ready;
	wire valid;
    // latch s3_new
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s3_new_reg   <= 'd0;
            s3_new_ready <= 0;
        end else if (valid) begin
            s3_new_ready <= 1'b0;  
        end
        else if (s3_new_valid) begin
            s3_new_reg   <= s3_new;
            s3_new_ready <= 1'b1;  
        end 

    end

    // latch j3_new
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            j3_new_reg   <= 'd0;
            j3_new_ready <= 0;
        end else if (valid) begin
            j3_new_ready <= 1'b0;  
        end
        else if (j3_new_valid) begin
            j3_new_reg   <= j3_new;
            j3_new_ready <= 1'b1;  
        end 

    end

    // latch s2_new
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s2_new_reg   <= 'd0;
            s2_new_ready <= 0;
        end else if (valid) begin
            s2_new_ready <= 1'b0;  
        end
        else if (s2_new_valid) begin
            s2_new_reg   <= s2_new;
            s2_new_ready <= 1'b1;  
        end 

    end

    // latch j2_new
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            j2_new_reg   <= 'd0;
            j2_new_ready <= 0;
        end else if (valid) begin
            j2_new_ready <= 1'b0;  
        end
        else if (j2_new_valid) begin
            j2_new_reg   <= j2_new;
            j2_new_ready <= 1'b1;  
        end 

    end


	wire signed [39:0] quotient_sig;
	wire signed [31:0] remain_sig;

	assign valid = s3_new_ready && j3_new_ready && s2_new_ready && j2_new_ready;

	wire signed [63:0] result_sig;
    reg  signed [63:0] result_sig_r;

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            result_sig_r   <= 'd0;
        end
        else begin
            result_sig_r  <= result_sig;
        end
    end

	multi_32x32bit_sign	multi_32x32bit_sign_inst (
    .clock ( clk_200m ),
    .aclr ( ~reset_200m ),
	.dataa ( s3_new_reg ),
	.datab ( j2_new_reg ),
	.result ( result_sig )
	);


	divide_40_32bit_sign divide_40_32bit_sign_inst (
    .clock ( clk_200m ),
    .aclr ( ~reset_200m ),
	.denom ( j3_new_reg ),
	.numer ( result_sig_r[63:24] ),
	.quotient ( quotient_sig ),
	.remain ( remain_sig )
	);

    wire valid_d;
	pipe_stage #(
	  .DATA_WIDTH(1),
	  .STAGES (18),
	  .RESET_VALUE (0)
	) pipe_stage_inst (
	  .i_clk        (clk_200m),
	  .i_rst_n      (reset_200m),
	  .i_data       (valid),
	  .o_data       (valid_d)
	);
	
	wire signed [63:0] s3_final_temp;
	IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(40),
        .OPERAND_WIDTH (32),
        .FRACTIONAL_BITS (24)
        //.PIPELINE_STAGES (8)
	) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (j3_new_reg),
        .o_valid     (o_valid),
        .o_q_out     (s3_final_temp)
    );
		
	assign s3_final = s3_final_temp[31:0] - s2_new_reg[31:0];


endmodule
