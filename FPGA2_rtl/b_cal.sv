module b_cal(
	input signed [31:0] s2_new,
	input signed [31:0] k2_new,
	input signed [31:0] c,
	input signed [31:0] j2_new,
	input clk_200m,
	input reset_200m,
	input s2_new_valid,
	input k2_new_valid,
	input c_valid,
	input j2_new_valid,
	output o_valid,
	output signed [31:0] b
);

    reg signed [31:0]  s2_new_reg, k2_new_reg;
	reg signed [31:0]  c_reg, j2_new_reg;
    reg        s2_new_ready, k2_new_ready, c_ready, j2_new_ready;
	wire valid;
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

	// latch k2_new
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            k2_new_reg   <= 'd0;
            k2_new_ready <= 0;
        end else if (valid) begin
            k2_new_ready <= 1'b0;  
        end
        else if (k2_new_valid) begin
            k2_new_reg   <= k2_new;
            k2_new_ready <= 1'b1;  
        end 

    end

	// latch c
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            c_reg   <= 'd0;
            c_ready <= 0;
        end else if (valid) begin
            c_ready <= 1'b0;  
        end
        else if (c_valid) begin
            c_reg   <= c;
            c_ready <= 1'b1;  
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

	wire signed [31:0] quotient_sig;
	wire signed [31:0] remain_sig;

	assign valid =  s2_new_ready && k2_new_ready && c_ready && j2_new_ready;

	wire signed [63:0] result_sig;
	wire signed [31:0] numer_in;

        reg  signed [31:0] numer_in_r;

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            numer_in_r   <= 'd0;
        end
        else begin
            numer_in_r  <= numer_in;
        end
    end

	multi_32x32bit	multi_32x32bit_inst (
    .clock ( clk_200m ),
    .aclr ( ~reset_200m ),
	.dataa ( k2_new_reg ),
	.datab ( c_reg ),
	.result ( result_sig )
	);
	assign numer_in = s2_new_reg - result_sig[55:24];

	divide_32_32bit_sign divide_32_32bit_sign_inst (
    .clock ( clk_200m ),
    .aclr ( ~reset_200m ),
	.denom ( j2_new_reg ),
	.numer ( numer_in_r ),
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
	
    wire signed [55:0] b_temp;

	IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(32),
        .OPERAND_WIDTH (32),
        .FRACTIONAL_BITS (24)
        //.PIPELINE_STAGES (8)
	) IntToFixed_Parallel_inst1 (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (j2_new_reg),
        .o_valid     (o_valid),
        .o_q_out     (b_temp)
    );
	
	assign b = b_temp[31:0];


endmodule
