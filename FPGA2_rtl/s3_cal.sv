// Author: lib
// Date: 2026-03-16
// Description: parameterized s3 calculation
`include "./param.v"
module s3_cal #(
    parameter S3_W = 37,
    parameter H3_W = 33,
    parameter S1_W = 33,
    parameter MAX_S3_W = 37,
    parameter MAX_H3_W = 33,
    parameter MAX_S1_W = 33
)(
    input  [S3_W-1:0]        s3,
    input  [H3_W-1:0]        h3,
    input  [S1_W-1:0]        s1,
    input                    clk_200m,
    input                    reset_200m,
    input                    s3_valid,
    input                    h3_valid,
    input                    s1_valid,
    output                   o_valid,
    output signed [31:0]     s3_new
);
    wire [MAX_S3_W-1:0] s3_padded;
    wire [MAX_H3_W-1:0] h3_padded;
    wire [MAX_S1_W-1:0] s1_padded;
    
    // zero extension
    // assign s3_padded = (S3_W < MAX_S3_W) ? {{(MAX_S3_W - S3_W){1'b0}}, s3} : s3[MAX_S3_W-1:0];
    // assign h3_padded = (H3_W < MAX_H3_W) ? {{(MAX_H3_W - H3_W){1'b0}}, h3} : h3[MAX_H3_W-1:0];
    // assign s1_padded = (S1_W < MAX_S1_W) ? {{(MAX_S1_W - S1_W){1'b0}}, s1} : s1[MAX_S1_W-1:0];

    generate
        if (S3_W < MAX_S3_W) begin : gen_s3_pad
            assign s3_padded = {{(MAX_S3_W - S3_W){1'b0}}, s3};
        end else begin : gen_s3_trunc
            assign s3_padded = s3[MAX_S3_W-1:0];
        end
        
        if (H3_W < MAX_H3_W) begin : gen_h3_pad
            assign h3_padded = {{(MAX_H3_W - H3_W){1'b0}}, h3};
        end else begin : gen_h3_trunc
            assign h3_padded = h3[MAX_H3_W-1:0];
        end
        
        if (S1_W < MAX_S1_W) begin : gen_s1_pad
            assign s1_padded = {{(MAX_S1_W - S1_W){1'b0}}, s1};
        end else begin : gen_s1_trunc
            assign s1_padded = s1[MAX_S1_W-1:0];
        end
    endgenerate

    reg signed [MAX_S3_W:0] s3_reg;
    reg signed [MAX_H3_W:0] h3_reg;
    reg signed [MAX_S1_W:0] s1_reg;
    
    reg s3_ready, h3_ready, s1_ready;
    wire valid;

    // latch s3
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s3_reg   <= 'd0;
            s3_ready <= 1'b0;
        end else if (valid) begin
            s3_ready <= 1'b0;
        end else if (s3_valid) begin
            s3_reg   <= $signed({1'b0, s3_padded});
            s3_ready <= 1'b1;  
        end 
    end

    // latch h3
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            h3_reg   <= 'd0;
            h3_ready <= 1'b0;
        end else if (valid) begin
            h3_ready <= 1'b0;
        end else if (h3_valid) begin
            h3_reg   <= $signed({1'b0, h3_padded});
            h3_ready <= 1'b1;  
        end 
    end

    // latch s1
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s1_reg   <= 'd0;
            s1_ready <= 1'b0;
        end else if (valid) begin
            s1_ready <= 1'b0;
        end else if (s1_valid) begin
            s1_reg   <= $signed({1'b0, s1_padded});
            s1_ready <= 1'b1;  
        end 
    end

    wire [MAX_S3_W:0] quotient_sig;
    wire [MAX_H3_W:0] remain_sig;
    assign valid = s3_ready && h3_ready && s1_ready;

    divide_38_34bit divide_38_34bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h3_reg ),
        .numer    ( s3_reg ),
        .quotient ( quotient_sig ), 
        .remain   ( remain_sig )    
    );

    wire valid_d;
    pipe_stage #(
        .DATA_WIDTH(1),
        .STAGES (16),
        .RESET_VALUE (0)
    ) pipe_stage_inst (
        .i_clk        (clk_200m),
        .i_rst_n      (reset_200m),
        .i_data       (valid),
        .o_data       (valid_d)
    );

    wire signed [MAX_S3_W + 24 : 0] s3_temp; 

    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_S3_W+1),
        .OPERAND_WIDTH (MAX_H3_W+1),
        .FRACTIONAL_BITS (24)
        //.PIPELINE_STAGES (8)
    ) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (h3_reg),    
        .o_valid     (o_valid),
        .o_q_out     (s3_temp) 
    );

    wire signed [MAX_S1_W : 0] s1_temp;
    // align fractional bits
    assign s1_temp =  s1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign s3_new  = s3_temp[31:0] - s1_temp[31:0];

endmodule
