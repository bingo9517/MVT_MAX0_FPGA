// Author: lib
// Date: 2026-03-16
// Description: parameterized j3 calculation
`include "./param.v"
module j3_cal #(
    parameter J3_W = 43,
    parameter H3_W = 33,
    parameter J1_W = 39,
    parameter MAX_J3_W = 43,
    parameter MAX_H3_W = 33,
    parameter MAX_J1_W = 39
)(
    input  [J3_W-1:0]        j3,
    input  [H3_W-1:0]        h3,
    input  [J1_W-1:0]        j1,
    input                    clk_200m,
    input                    reset_200m,
    input                    j3_valid,
    input                    h3_valid,
    input                    j1_valid,
    output                   o_valid,
    output signed [31:0]     j3_new
);
    wire [MAX_J3_W-1:0] j3_padded;
    wire [MAX_H3_W-1:0] h3_padded;
    wire [MAX_J1_W-1:0] j1_padded;
    
    // zero extension
    // assign j3_padded = (J3_W < MAX_J3_W) ? {{(MAX_J3_W - J3_W){1'b0}}, j3} : j3[MAX_J3_W-1:0];
    // assign h3_padded = (H3_W < MAX_H3_W) ? {{(MAX_H3_W - H3_W){1'b0}}, h3} : h3[MAX_H3_W-1:0];
    // assign j1_padded = (J1_W < MAX_J1_W) ? {{(MAX_J1_W - J1_W){1'b0}}, j1} : j1[MAX_J1_W-1:0];

    generate
        if (J3_W < MAX_J3_W) begin : gen_j3_pad
            assign j3_padded = {{(MAX_J3_W - J3_W){1'b0}}, j3};
        end else begin : gen_j3_trunc
            assign j3_padded = j3[MAX_J3_W-1:0];
        end
        
        if (H3_W < MAX_H3_W) begin : gen_h3_pad
            assign h3_padded = {{(MAX_H3_W - H3_W){1'b0}}, h3};
        end else begin : gen_h3_trunc
            assign h3_padded = h3[MAX_H3_W-1:0];
        end
        
        if (J1_W < MAX_J1_W) begin : gen_j1_pad
            assign j1_padded = {{(MAX_J1_W - J1_W){1'b0}}, j1};
        end else begin : gen_j1_trunc
            assign j1_padded = j1[MAX_J1_W-1:0];
        end
    endgenerate

    reg signed [MAX_J3_W:0] j3_reg;
    reg signed [MAX_H3_W:0] h3_reg;
    reg signed [MAX_J1_W:0] j1_reg;
    
    reg j3_ready, h3_ready, j1_ready;
    wire valid;

    // latch j3
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            j3_reg   <= 'd0;
            j3_ready <= 1'b0;
        end else if (valid) begin
            j3_ready <= 1'b0;
        end else if (j3_valid) begin
            j3_reg   <= $signed({1'b0, j3_padded});
            j3_ready <= 1'b1;  
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

    // latch j1
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            j1_reg   <= 'd0;
            j1_ready <= 1'b0;
        end else if (valid) begin
            j1_ready <= 1'b0;
        end else if (j1_valid) begin
            j1_reg   <= $signed({1'b0, j1_padded});
            j1_ready <= 1'b1;  
        end 
    end

    wire [MAX_J3_W:0] quotient_sig;
    wire [MAX_H3_W:0] remain_sig;
    assign valid = j3_ready && h3_ready && j1_ready;

    divide_44_34bit divide_44_34bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h3_reg ),
        .numer    ( j3_reg ),
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

    wire signed [MAX_J3_W + 24 : 0] j3_temp; 

    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_J3_W+1),
        .OPERAND_WIDTH (MAX_H3_W+1),
        .FRACTIONAL_BITS (24),
        .PIPELINE_STAGES (8)
    ) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (h3_reg),    
        .o_valid     (o_valid),
        .o_q_out     (j3_temp) 
    );

    wire signed [MAX_J1_W : 0] j1_temp; // Qx.24
    // align fractional bits
    assign j1_temp =  j1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign j3_new  = j3_temp[31:0] - j1_temp[31:0];

endmodule
