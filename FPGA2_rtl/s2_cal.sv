// Author: lib
// Date: 2026-03-16
// Description: parameterized s2 calculation
`include "./param.v"
module s2_cal #(
    parameter S2_W = 43,
    parameter H2_W = 39,
    parameter S1_W = 33,
    parameter MAX_S2_W = 43,
    parameter MAX_H2_W = 39,
    parameter MAX_S1_W = 33
)(
    input  [S2_W-1:0]        s2,
    input  [H2_W-1:0]        h2,
    input  [S1_W-1:0]        s1,
    input                    clk_200m,
    input                    reset_200m,
    input                    s2_valid,
    input                    h2_valid,
    input                    s1_valid,
    output                   o_valid,
    output signed [31:0]     s2_new
);
    wire [MAX_S2_W-1:0] s2_padded;
    wire [MAX_H2_W-1:0] h2_padded;
    wire [MAX_S1_W-1:0] s1_padded;
    
    // zero extension
    // assign s2_padded = (S2_W < MAX_S2_W) ? {{(MAX_S2_W - S2_W){1'b0}}, s2} : s2[MAX_S2_W-1:0];
    // assign h2_padded = (H2_W < MAX_H2_W) ? {{(MAX_H2_W - H2_W){1'b0}}, h2} : h2[MAX_H2_W-1:0];
    // assign s1_padded = (S1_W < MAX_S1_W) ? {{(MAX_S1_W - S1_W){1'b0}}, s1} : s1[MAX_S1_W-1:0];

    generate
        if (S2_W < MAX_S2_W) begin : gen_s2_pad
            assign s2_padded = {{(MAX_S2_W - S2_W){1'b0}}, s2};
        end else begin : gen_s2_trunc
            assign s2_padded = s2[MAX_S2_W-1:0];
        end
        
        if (H2_W < MAX_H2_W) begin : gen_h2_pad
            assign h2_padded = {{(MAX_H2_W - H2_W){1'b0}}, h2};
        end else begin : gen_h2_trunc
            assign h2_padded = h2[MAX_H2_W-1:0];
        end
        
        if (S1_W < MAX_S1_W) begin : gen_s1_pad
            assign s1_padded = {{(MAX_S1_W - S1_W){1'b0}}, s1};
        end else begin : gen_s1_trunc
            assign s1_padded = s1[MAX_S1_W-1:0];
        end
    endgenerate


    reg [MAX_S2_W:0] s2_reg;
    reg [MAX_H2_W:0] h2_reg;
    reg [MAX_S1_W:0] s1_reg;
    
    reg s2_ready, h2_ready, s1_ready;
    wire valid;

    // latch s2
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            s2_reg   <= 'd0;
            s2_ready <= 1'b0;
        end else if (valid) begin
            s2_ready <= 1'b0;
        end else if (s2_valid) begin
            s2_reg   <= $signed({1'b0, s2_padded});
            s2_ready <= 1'b1;  
        end 
    end

    // latch h2
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            h2_reg   <= 'd0;
            h2_ready <= 1'b0;
        end else if (valid) begin
            h2_ready <= 1'b0;
        end else if (h2_valid) begin
            h2_reg   <= $signed({1'b0, h2_padded});
            h2_ready <= 1'b1;  
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

    wire [MAX_S2_W:0] quotient_sig;
    wire [MAX_H2_W:0] remain_sig;
    assign valid = s2_ready && h2_ready && s1_ready;

    divide_44_40bit divide_44_40bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h2_reg ),
        .numer    ( s2_reg ),
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

    wire signed [MAX_S2_W + 24 : 0] s2_temp; 


    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_S2_W+1),
        .OPERAND_WIDTH (MAX_H2_W+1),
        .FRACTIONAL_BITS (24)
        //.PIPELINE_STAGES (8)
    ) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (h2_reg),    
        .o_valid     (o_valid),
        .o_q_out     (s2_temp) 
    );
    
    wire signed [MAX_S1_W : 0] s1_temp; // 34, Qx.24
    // align fractional bits
    assign s1_temp =  s1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign s2_new  = s2_temp[31:0] - s1_temp[31:0];

endmodule
