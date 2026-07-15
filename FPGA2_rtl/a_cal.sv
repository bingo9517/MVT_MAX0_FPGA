// Author: lib
// Date: 2026-03-16
// Description: parameterized a calculation with explicit sign extension and width alignment
`include "./param.v"
module a_cal #(
    parameter S1_W = 33,
    parameter J1_W = 39,
    parameter K1_W = 33,
    parameter MAX_S1_W = 33,
    parameter MAX_J1_W = 39,
    parameter MAX_K1_W = 33
)(
    input                                clk_200m,
    input                                reset_200m,
    input  signed [S1_W-1:0]             s1,
    input  signed [J1_W-1:0]             j1,
    input  signed [K1_W-1:0]             k1,
    input                                s1_valid,
    input                                j1_valid,
    input                                k1_valid,
    input  signed [31:0]                 c,
    input  signed [31:0]                 b,
    input                                c_valid,
    input                                b_valid,
    output                               o_valid,
    output signed [31:0]                 a
);

    wire signed [MAX_S1_W-1:0] s1_padded;
    wire signed [MAX_J1_W-1:0] j1_padded;
    wire signed [MAX_K1_W-1:0] k1_padded;
    
    // sign extension for parameterized signed inputs
    // assign s1_padded = (S1_W < MAX_S1_W) ? {{(MAX_S1_W - S1_W){1'b0}}, s1} : s1[MAX_S1_W-1:0];
    // assign j1_padded = (J1_W < MAX_J1_W) ? {{(MAX_J1_W - J1_W){1'b0}}, j1} : j1[MAX_J1_W-1:0];
    // assign k1_padded = (K1_W < MAX_K1_W) ? {{(MAX_K1_W - K1_W){1'b0}}, k1} : k1[MAX_K1_W-1:0];

    generate
        if (S1_W < MAX_S1_W) begin : gen_s1_pad
            assign s1_padded = {{(MAX_S1_W - S1_W){1'b0}}, s1};
        end else begin : gen_s1_trunc
            assign s1_padded = s1[MAX_S1_W-1:0];
        end
        
        if (J1_W < MAX_J1_W) begin : gen_j1_pad
            assign j1_padded = {{(MAX_J1_W - J1_W){1'b0}}, j1};
        end else begin : gen_j1_trunc
            assign j1_padded = j1[MAX_J1_W-1:0];
        end
        
        if (K1_W < MAX_K1_W) begin : gen_k1_pad
            assign k1_padded = {{(MAX_K1_W - K1_W){1'b0}}, k1};
        end else begin : gen_k1_trunc
            assign k1_padded = k1[MAX_K1_W-1:0];
        end
    endgenerate

    reg signed [MAX_S1_W:0] s1_reg;
    reg signed [MAX_K1_W:0] k1_reg;
    reg signed [MAX_J1_W:0] j1_reg;
    reg signed [31:0]         b_reg, c_reg;
    
    reg s1_ready, j1_ready, k1_ready, b_ready, c_ready;
    wire valid;

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

    // latch b
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            b_reg   <= 'd0;
            b_ready <= 1'b0;
        end else if (valid) begin
            b_ready <= 1'b0;
        end else if (b_valid) begin
            b_reg   <= b;
            b_ready <= 1'b1;  
        end 
    end

    // latch c
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            c_reg   <= 'd0;
            c_ready <= 1'b0;
        end else if (valid) begin
            c_ready <= 1'b0;
        end else if (c_valid) begin
            c_reg   <= c;
            c_ready <= 1'b1;  
        end 
    end

    assign valid = s1_ready && j1_ready && k1_ready && b_ready && c_ready;

    pipe_stage #(
        .DATA_WIDTH(1),
        .STAGES (1),
        .RESET_VALUE (0)
    ) pipe_stage_inst (
        .i_clk        (clk_200m),
        .i_rst_n      (reset_200m),
        .i_data       (valid),
        .o_data       (o_valid)
    );

    wire signed [65:0] result_sig;
    wire signed [71:0] result_sig_1;

    wire signed [MAX_K1_W:0] k1_shifted = k1_reg >>> $clog2(2*`MVT_CHANNEL);
    wire signed [MAX_J1_W:0] j1_shifted = j1_reg >>> $clog2(2*`MVT_CHANNEL);

    multi_32x34bit_sign multi_32x34bit_sign_inst (
        .clock  ( clk_200m ),
        .aclr   ( ~reset_200m ),
        .dataa  ( c_reg ),       
        .datab  ( k1_shifted ),  
        .result ( result_sig )
    );

    multi_32x40bit_sign multi_32x40bit_sign_inst_1 (
        .clock  ( clk_200m ),
        .aclr   ( ~reset_200m ),
        .dataa  ( b_reg ),       
        .datab  ( j1_shifted ),  
        .result ( result_sig_1 )
    );


    wire signed [31:0] s1_ext   = s1_reg >>> $clog2(2*`MVT_CHANNEL); 
    wire signed [41:0] res1_ext = result_sig[65:24];
    wire signed [47:0] res2_ext = result_sig_1[71:24];

    assign a = s1_ext - res1_ext - res2_ext;

endmodule
