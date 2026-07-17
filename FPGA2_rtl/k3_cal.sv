// Author: lib
// Date: 2026-03-13
// Description: parameterized k3 calculation 
`include "./param.v"
module k3_cal #(
    parameter K3_W = 37,
    parameter H3_W = 33,
    parameter K1_W = 33,
    parameter MAX_K3_W = 37,
    parameter MAX_H3_W = 33
)(
    input  [K3_W-1:0]        k3,       
    input  [H3_W-1:0]        h3,        
    input  [K1_W-1:0]        k1,       
    input                    k3_valid,
    input                    h3_valid,
    input                    k1_valid,
    input                    clk_200m,
    input                    reset_200m,
    output                   o_valid,
    output signed [31:0]     k3_new    // Q8.24
);

    wire [MAX_K3_W-1:0] k3_padded;
    wire [MAX_H3_W-1:0] h3_padded;
    wire [MAX_H3_W-1:0] k1_padded;
    
    // zero extension ,bit width  MAX_K3_W, MAX_H3_W
    // assign k3_padded = (K3_W < MAX_K3_W) ? {{(MAX_K3_W - K3_W){1'b0}}, k3} : k3[MAX_K3_W-1:0];
    // assign h3_padded = (H3_W < MAX_H3_W) ? {{(MAX_H3_W - H3_W){1'b0}}, h3} : h3[MAX_H3_W-1:0];
    // assign k1_padded = (K1_W < MAX_H3_W) ? {{(MAX_H3_W - K1_W){1'b0}}, k1} : k1[MAX_H3_W-1:0];

    //for compile warning
    generate
        if (K3_W < MAX_K3_W) begin : gen_k3_pad
            assign k3_padded = {{(MAX_K3_W - K3_W){1'b0}}, k3};
        end else begin : gen_k3_trunc
            assign k3_padded = k3[MAX_K3_W-1:0];
        end
        
        if (H3_W < MAX_H3_W) begin : gen_h3_pad
            assign h3_padded = {{(MAX_H3_W - H3_W){1'b0}}, h3};
        end else begin : gen_h3_trunc
            assign h3_padded = h3[MAX_H3_W-1:0];
        end
        
        if (K1_W < MAX_H3_W) begin : gen_k1_pad
            assign k1_padded = {{(MAX_H3_W - K1_W){1'b0}}, k1};
        end else begin : gen_k1_trunc
            assign k1_padded = k1[MAX_H3_W-1:0];
        end
    endgenerate

    //bit width MAX_K3_W + 1 , MAX_H3_W +1 for signed operation
    reg signed [MAX_K3_W:0] k3_reg;
    reg signed [MAX_H3_W:0] h3_reg;
    reg signed [MAX_H3_W:0] k1_reg;
    
    reg k3_ready, h3_ready, k1_ready;
    wire valid;

    // latch k3
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            k3_reg   <= 'd0;
            k3_ready <= 1'b0;
        end else if (valid) begin
            k3_ready <= 1'b0;
        end else if (k3_valid) begin
            k3_reg   <= $signed({1'b0, k3_padded}); 
            k3_ready <= 1'b1;  
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

    wire [MAX_K3_W:0] quotient_sig;//38
    wire [MAX_H3_W:0] remain_sig;//34
    
    assign valid = k3_ready && h3_ready && k1_ready;


    divide_38_34bit divide_38_34bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h3_reg ),
        .numer    ( k3_reg ),
        .quotient ( quotient_sig ), // int
        .remain   ( remain_sig )    // int
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

    wire signed [MAX_K3_W + 24 : 0] k3_temp; // Qx.24
    
    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_K3_W+1), // 38
        .OPERAND_WIDTH (MAX_H3_W+1), // 34
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
        .o_q_out     (k3_temp) // Qx.24
    );

    wire signed [MAX_H3_W : 0] k1_temp; // 34, Qx.24

    assign k1_temp =  k1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign k3_new  = k3_temp[31:0] - k1_temp[31:0];

endmodule
