// Author: lib
// Date: 2026-03-16
// Description: parameterized j2 calculation
`include "./param.v"
module j2_cal #(
    parameter J2_W = 49,
    parameter H2_W = 39,
    parameter J1_W = 39,
    parameter MAX_J2_W = 49,
    parameter MAX_H2_W = 39
)(
    input  [J2_W-1:0]        j2,
    input  [H2_W-1:0]        h2,
    input  [J1_W-1:0]        j1,
    input                    clk_200m,
    input                    reset_200m,
    input                    j2_valid,
    input                    h2_valid,
    input                    j1_valid,
    output                   o_valid,
    output signed [31:0]     j2_new
);
    wire [MAX_J2_W-1:0] j2_padded;
    wire [MAX_H2_W-1:0] h2_padded;
    wire [MAX_H2_W-1:0] j1_padded;
    
    // zero extension
    // assign j2_padded = (J2_W < MAX_J2_W) ? {{(MAX_J2_W - J2_W){1'b0}}, j2} : j2[MAX_J2_W-1:0];
    // assign h2_padded = (H2_W < MAX_H2_W) ? {{(MAX_H2_W - H2_W){1'b0}}, h2} : h2[MAX_H2_W-1:0];
    // assign j1_padded = (J1_W < MAX_H2_W) ? {{(MAX_H2_W - J1_W){1'b0}}, j1} : j1[MAX_H2_W-1:0];

    generate
        if (J2_W < MAX_J2_W) begin : gen_j2_pad
            assign j2_padded = {{(MAX_J2_W - J2_W){1'b0}}, j2};
        end else begin : gen_j2_trunc
            assign j2_padded = j2[MAX_J2_W-1:0];
        end
        
        if (H2_W < MAX_H2_W) begin : gen_h2_pad
            assign h2_padded = {{(MAX_H2_W - H2_W){1'b0}}, h2};
        end else begin : gen_h2_trunc
            assign h2_padded = h2[MAX_H2_W-1:0];
        end
        
        if (J1_W < MAX_H2_W) begin : gen_j1_pad
            assign j1_padded = {{(MAX_H2_W - J1_W){1'b0}}, j1};
        end else begin : gen_j1_trunc
            assign j1_padded = j1[MAX_H2_W-1:0];
        end
    endgenerate


    reg signed [MAX_J2_W:0] j2_reg;
    reg signed [MAX_H2_W:0] h2_reg;
    reg signed [MAX_H2_W:0] j1_reg;
    
    reg j2_ready, h2_ready, j1_ready;
    wire valid;

    // latch j2
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            j2_reg   <= 'd0;
            j2_ready <= 1'b0;
        end else if (valid) begin
            j2_ready <= 1'b0;
        end else if (j2_valid) begin
            j2_reg   <= $signed ({1'b0, j2_padded});
            j2_ready <= 1'b1;  
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
            h2_reg   <= $signed ({1'b0, h2_padded});
            h2_ready <= 1'b1;  
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
            j1_reg   <= $signed ({1'b0, j1_padded});
            j1_ready <= 1'b1;  
        end 
    end

    wire [MAX_J2_W:0] quotient_sig;
    wire [MAX_H2_W:0] remain_sig;
    assign valid = j2_ready && h2_ready && j1_ready;

    divide_50_40bit divide_50_40bit_inst (
        .clock    ( clk_200m ),
        .aclr     ( ~reset_200m ),
        .denom    ( h2_reg ),
        .numer    ( j2_reg ),
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

    wire signed [MAX_J2_W + 24 : 0] j2_temp; 

    IntToFixed_Parallel #(
        .QUOTIENT_WIDTH(MAX_J2_W+1),
        .OPERAND_WIDTH (MAX_H2_W+1),
        .FRACTIONAL_BITS (24),
        .PIPELINE_STAGES (8)
    ) IntToFixed_Parallel_inst (
        .clk         (clk_200m),
        .rst_n       (reset_200m),
        .i_valid     (valid_d),
        .i_quotient  (quotient_sig),
        .i_remainder (remain_sig),
        .i_divisor   (h2_reg),    
        .o_valid     (o_valid),
        .o_q_out     (j2_temp) 
    );

    wire signed [MAX_H2_W : 0] j1_temp; // 40, Qx.24

    // align fractional bits
    assign j1_temp =  j1_reg >>> $clog2(2*`MVT_CHANNEL);
    assign j2_new  = j2_temp[31:0] - j1_temp[31:0];

endmodule
