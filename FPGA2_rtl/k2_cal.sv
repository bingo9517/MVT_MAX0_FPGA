// Author: lib
// Date: 2026-03-16
// Description: parameterized k2 calculation
`include "./param.v"
module k2_cal #(
    parameter K2_W = 43,
    parameter H2_W = 39,
    parameter K1_W = 33,
    parameter MAX_K2_W = 43,
    parameter MAX_H2_W = 39,
    parameter MAX_K1_W = 33
)(
    input  [K2_W-1:0]        k2,
    input  [H2_W-1:0]        h2,
    input  [K1_W-1:0]        k1,
    input                    clk_200m,
    input                    reset_200m,
    input                    k2_valid,
    input                    h2_valid,
    input                    k1_valid,
    output                   o_valid,
    output signed [31:0]     k2_new
);
    wire [MAX_K2_W-1:0] k2_padded;
    wire [MAX_H2_W-1:0] h2_padded;
    wire [MAX_K1_W-1:0] k1_padded;
    
    // zero extension
    // assign k2_padded = (K2_W < MAX_K2_W) ? {{(MAX_K2_W - K2_W){1'b0}}, k2} : k2[MAX_K2_W-1:0];
    // assign h2_padded = (H2_W < MAX_H2_W) ? {{(MAX_H2_W - H2_W){1'b0}}, h2} : h2[MAX_H2_W-1:0];
    // assign k1_padded = (K1_W < MAX_K1_W) ? {{(MAX_K1_W - K1_W){1'b0}}, k1} : k1[MAX_K1_W-1:0];

    generate
        if (K2_W < MAX_K2_W) begin : gen_k2_pad
            assign k2_padded = {{(MAX_K2_W - K2_W){1'b0}}, k2};
        end else begin : gen_k2_trunc
            assign k2_padded = k2[MAX_K2_W-1:0];
        end
        
        if (H2_W < MAX_H2_W) begin : gen_h2_pad
            assign h2_padded = {{(MAX_H2_W - H2_W){1'b0}}, h2};
        end else begin : gen_h2_trunc
            assign h2_padded = h2[MAX_H2_W-1:0];
        end
        
        if (K1_W < MAX_K1_W) begin : gen_k1_pad
            assign k1_padded = {{(MAX_K1_W - K1_W){1'b0}}, k1};
        end else begin : gen_k1_trunc
            assign k1_padded = k1[MAX_K1_W-1:0];
        end
    endgenerate

    reg signed [MAX_K2_W:0] k2_reg;
    reg signed [MAX_H2_W:0] h2_reg;
    reg signed [MAX_K1_W:0] k1_reg;
    
    reg k2_ready, h2_ready, k1_ready;
    wire valid;

    // latch k2
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            k2_reg   <= 'd0;
            k2_ready <= 1'b0;
        end else if (valid) begin
            k2_ready <= 1'b0;
        end else if (k2_valid) begin
            k2_reg   <= $signed({1'b0, k2_padded});
            k2_ready <= 1'b1;  
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

    // latch k1
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            k1_reg   <= 'd0;
            k1_ready <= 1'b0;
        end else if (valid) begin
            k1_ready <= 1'b0;
        end else if (k1_valid) begin
            k1_reg   <= $signed({1'b0, k1_padded});
            k1_ready <= 1'b1;  
        end 
    end

    wire [MAX_K2_W:0] quotient_sig;
    wire [MAX_H2_W:0] remain_sig;
    assign valid = k2_ready && h2_ready && k1_ready;

    divide_44_40bit divide_44_40bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h2_reg ),
        .numer    ( k2_reg ),
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

    wire signed [MAX_K2_W + 24 : 0] k2_temp; 

    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_K2_W+1),
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
        .o_q_out     (k2_temp) 
    );


    wire signed [MAX_K1_W : 0] k1_temp; // Qx.24
    assign k1_temp =  k1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign k2_new  = k2_temp[31:0] - k1_temp[31:0];

endmodule
