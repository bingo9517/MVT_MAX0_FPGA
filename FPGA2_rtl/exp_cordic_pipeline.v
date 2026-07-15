 /**
 * - Author: lib
 * - Date: 2025-07-07
 * - Description:   pipelined implementation of e^x using CORDIC.
 * - Latency: Fixed, 7 + N_ITER cycles.
 */
module exp_cordic_pipeline #(
    parameter N_ITER = 18
) (
    input                       clk,
    input                       rst_n,

    input                       valid_in,
    input      signed [31:0]    x_in,//Q16.16

    output                      valid_out,
    output     reg signed [31:0]    result_out//Q16.16
);
    localparam S_REDUCE = 4;
    localparam S_INIT   = 1;
    localparam S_SUM    = 1;
    localparam S_SHIFT  = 1;
    localparam TOTAL_STAGES = S_REDUCE + S_INIT + N_ITER + S_SUM + S_SHIFT ;//24
	
    localparam signed [31:0] C_LN2 = 32'h0000B172;
    localparam signed [31:0] C_INV_LN2 = 32'h00017154;
    localparam signed [31:0] C_INV_KH = 32'h00013521;
	
    reg  signed [31:0]  x_pipe_rr [3:0];
    reg  signed [15:0]  k_reg;
	
    localparam CORDIC_PIPE_LEN = S_INIT + N_ITER + S_SUM;//20
    wire  signed [31:0]  x_pipe [CORDIC_PIPE_LEN-1:0];
    wire  signed [31:0]  y_pipe [CORDIC_PIPE_LEN-1:0];
    wire  signed [31:0]  z_pipe [CORDIC_PIPE_LEN-1:0];
    wire  signed [15:0]  k_pipe [CORDIC_PIPE_LEN+1:0];
    reg                 valid_pipe [TOTAL_STAGES:0];

    reg  signed [31:0]  x_pipe_0_reg;
    reg  signed [31:0]  y_pipe_0_reg;
    reg  signed [31:0]  z_pipe_0_reg;


    assign x_pipe[0] = x_pipe_0_reg;
    assign y_pipe[0] = y_pipe_0_reg;
    assign z_pipe[0] = z_pipe_0_reg;

    always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			x_pipe_rr[0] <= 32'd0;
			valid_pipe[0]   <= 1'd0;
		end
		else if (valid_in) begin
			x_pipe_rr[0] <= x_in;
			valid_pipe[0]   <= valid_in;
		end
		else begin
			x_pipe_rr[0] <= 32'd0;
			valid_pipe[0]   <= 1'd0;	
		end
    end


    wire signed [31:0] mult1_p, mult2_p;
    reg signed [31:0] sub_res_rr;


    //1 latency
    fix_point_multiplier_wrapper mult_inv_ln2 ( 
	.clock(clk), 
	.dataa(x_pipe_rr[0]), 
	.datab(C_INV_LN2), 
	.result(mult1_p) 
	); // for k
	
    //1 latency
    fix_point_multiplier_wrapper mult_ln2	  ( 
	.clock(clk), 
	.dataa({k_reg, 16'b0}), 
	.datab(C_LN2), 
	.result(mult2_p) 
	); // for z
	
    
    sync_regs #(16) u_k_pipe_0 (.clk(clk), .rstn(rst_n), .in(k_reg), .out(k_pipe[0])); 
	
    always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		x_pipe_rr[1] <= 32'b0;
		x_pipe_rr[2] <= 32'b0;
		x_pipe_rr[3] <= 32'b0;			
//		k_pipe[0]    <= 15'b0;			
		k_reg		 <= 16'b0;
		sub_res_rr   <= 32'b0;
		//mult2_p_reg  <= 32'b0;
	end else begin
		x_pipe_rr[1] <= x_pipe_rr[0];
		x_pipe_rr[2] <= x_pipe_rr[1];
		x_pipe_rr[3] <= x_pipe_rr[2];
		k_reg     	 <= mult1_p[31:16] + mult1_p[15]; 
//		k_pipe[0]    <= k_reg;
		sub_res_rr   <= x_pipe_rr[3] - mult2_p;

	end	

    end


    always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		x_pipe_0_reg <= 32'd0;
		y_pipe_0_reg <= 32'd0;
		z_pipe_0_reg <= 32'd0;
	end
	else if (valid_pipe[4])begin
		x_pipe_0_reg <= C_INV_KH;
		y_pipe_0_reg <= 32'd0;
		z_pipe_0_reg <= sub_res_rr;	
	end
	else begin
		x_pipe_0_reg <= 32'd0;
		y_pipe_0_reg <= 32'd0;
		z_pipe_0_reg <= 32'd0;		
	end
    end

    genvar i;
    generate
        for (i = 0; i < N_ITER; i = i + 1) begin : cordic_pipeline_stage
	    wire [5:0] loop_index = i;
            wire signed [31:0] atanh_val;
            //wire [5:0]         iter_idx = i + 1; // Iteration from 1 to 16
            
            wire [5:0] corrected_idx;
			
	    cordic_iteration_sequence cordic_iteration_sequence_lookup (
		.iteration_count(loop_index),
		.actual_i(corrected_idx)
	    );			
            
            atanh_rom atanh_lookup (
                .iter_idx(corrected_idx),
                .data_out(atanh_val)
            );

            wire d_sign = z_pipe[loop_index][31];
            wire signed [31:0] x_shifted = x_pipe[loop_index] >>> corrected_idx;
            wire signed [31:0] y_shifted = y_pipe[loop_index] >>> corrected_idx;
            
            wire signed [31:0] x_out = d_sign ? (x_pipe[loop_index] - y_shifted) : (x_pipe[loop_index] + y_shifted);
            wire signed [31:0] y_out = d_sign ? (y_pipe[loop_index] - x_shifted) : (y_pipe[loop_index] + x_shifted);
            wire signed [31:0] z_out = d_sign ? (z_pipe[loop_index] + atanh_val) : (z_pipe[loop_index] - atanh_val);

            
            wire signed [15:0] k_pipe_iter1 ;
            wire signed [31:0] x_pipe_iter1 ;
            wire signed [31:0] y_pipe_iter1 ;
            wire signed [31:0] z_pipe_iter1 ;
            assign k_pipe[i+1] = k_pipe_iter1;
            assign x_pipe[i+1] = x_pipe_iter1;
            assign y_pipe[i+1] = y_pipe_iter1;
            assign z_pipe[i+1] = z_pipe_iter1;

            sync_regs #(16) u_k_pipe_iter (.clk(clk), .rstn(rst_n), .in(k_pipe[loop_index]), .out(k_pipe_iter1)); // rh
            sync_regs #(32) u_x_pipe_iter (.clk(clk), .rstn(rst_n), .in(x_out), .out(x_pipe_iter1)); // rh
            sync_regs #(32) u_y_pipe_iter (.clk(clk), .rstn(rst_n), .in(y_out), .out(y_pipe_iter1)); // rh
            sync_regs #(32) u_z_pipe_iter (.clk(clk), .rstn(rst_n), .in(z_out), .out(z_pipe_iter1)); // rh
            
//            always @(posedge clk or negedge rst_n) begin
//                if (!rst_n) begin
//                    x_pipe[loop_index+1] <= 32'd0;
//                    y_pipe[loop_index+1] <= 32'd0;
//                    z_pipe[loop_index+1] <= 32'd0;
//                    k_pipe[loop_index+1] <= 16'd0;
//                end else begin
//                    x_pipe[loop_index+1] <= x_out;
//                    y_pipe[loop_index+1] <= y_out;
//                    z_pipe[loop_index+1] <= z_out;
//                    k_pipe[loop_index+1] <= k_pipe[loop_index]; // Pass k through the pipeline
//                end
//            end
        end
    endgenerate

      sync_regs #(16) u_k_pipe_N1 (.clk(clk), .rstn(rst_n), .in(k_pipe[N_ITER]), .out(k_pipe[N_ITER+1])); // rh
      sync_regs #(16) u_k_pipe_N2 (.clk(clk), .rstn(rst_n), .in(k_pipe[N_ITER+1]), .out(k_pipe[N_ITER+2])); // rh
      sync_regs #(16) u_k_pipe_N3 (.clk(clk), .rstn(rst_n), .in(k_pipe[N_ITER+2]), .out(k_pipe[N_ITER+3])); // rh
      sync_regs #(32) u_x_pipe_N1 (.clk(clk), .rstn(rst_n), .in(x_pipe[N_ITER]+y_pipe[N_ITER]), .out(x_pipe[N_ITER+1])); // rh
//    always @(posedge clk or negedge rst_n) begin
//		if (!rst_n) begin
//			x_pipe[N_ITER+1] <= 32'd0;
//			k_pipe[N_ITER+1] <= 15'd0;
//			k_pipe[N_ITER+2] <= 15'd0;
//			k_pipe[N_ITER+3] <= 15'd0;
//		end
//		else begin
//			x_pipe[N_ITER+1] <= x_pipe[N_ITER] + y_pipe[N_ITER]; // Store sum in x_pipe
//			k_pipe[N_ITER+1] <= k_pipe[N_ITER];
//			k_pipe[N_ITER+2] <= k_pipe[N_ITER+1];
//			k_pipe[N_ITER+3] <= k_pipe[N_ITER+2];
//		end
//    end


    localparam SHIFT_STAGE_IDX = N_ITER + 1;
    wire signed [31:0] sum_val = x_pipe[SHIFT_STAGE_IDX];
    wire signed [15:0] k_val   = k_pipe[SHIFT_STAGE_IDX + 2];
    
    //assign result_out = k_val[15] ? (sum_val >>> -k_val) : (sum_val <<< k_val);
    always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		result_out <= 32'd0;			
	end
	else begin
		result_out <= k_val[15] ? (sum_val >>> -k_val) : (sum_val <<< k_val);
	end
    end
     

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(j=1; j <= TOTAL_STAGES; j=j+1) begin
                valid_pipe[j] <= 1'b0;
            end
        end else begin
            for(j=1; j <= TOTAL_STAGES; j=j+1) begin
                valid_pipe[j] <= valid_pipe[j-1];
            end
        end
    end
    
    assign valid_out = valid_pipe[TOTAL_STAGES];

endmodule


module sync_regs  (
 clk,
 rstn,
 in,
 out
);
 parameter DW = 32;
 input clk;
 input rstn;
 input [DW-1 : 0] in;
 output reg [DW-1 : 0] out;

  always @(posedge clk or negedge rstn) 
    if (!rstn) 
      out <= {DW{1'b0}};
    else 
      out <= in;
endmodule

