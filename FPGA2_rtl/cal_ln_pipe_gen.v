//-----------------------------------------------------------------------------
// Author       : lib
// Date         : 2026-04-03
// Description  : 3-stage pipelined ln(x) for arbitrary Qx.y input and Qm.n output.
//-----------------------------------------------------------------------------
module cal_ln_pipe_gen #(
    parameter INPUT_X  = 10,       // int bits of input
    parameter INPUT_Y  = 8,        // frac bits of input
    parameter OUTPUT_M = 4,        // int bits of output 
    parameter OUTPUT_N = 24,       // frac bits of output
    parameter LN2_VAL  = 11629080  
)(
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            valid_i,
    input  wire [INPUT_X+INPUT_Y-1 : 0]    a,
    output reg                             valid_o,
    output reg  [OUTPUT_M+OUTPUT_N-1 : 0]  ln_value
);

localparam INPUT_WIDTH  = INPUT_X + INPUT_Y;
localparam OUTPUT_WIDTH = OUTPUT_M + OUTPUT_N;


reg                              vld_s1;
reg                              err_flag_s1;
reg  [INPUT_WIDTH-1 : 0]         shift_a_s1;
reg  signed [8:0]                diff_k_y_s1;


reg                              vld_s2;
reg                              err_flag_s2;
reg  signed [OUTPUT_WIDTH-1 : 0] nln2_a_s2;
reg  [OUTPUT_N-1 : 0]            result_norm_a_s2;


integer i;
reg [7:0] k_idx;
reg       err_flag_cmb;


always @(*) begin
    k_idx = 8'd0;
    err_flag_cmb = 1'b1;
    for (i = INPUT_WIDTH-1; i >= 0; i = i - 1) begin
        if (a[i] && err_flag_cmb) begin
            k_idx = i[7:0];
            err_flag_cmb = 1'b0;
        end
    end
end

wire signed [8:0] k_idx_signed = {1'b0, k_idx};
wire signed [8:0] y_signed     = INPUT_Y;
wire signed [8:0] diff_cmb     = k_idx_signed - y_signed;
wire [INPUT_WIDTH-1:0] shift_cmb = a << (INPUT_WIDTH - 1 - k_idx);

always @(posedge clk) begin
    if (!rst_n) begin
        vld_s1      <= 1'b0;
        err_flag_s1 <= 1'b0;
        shift_a_s1  <= {INPUT_WIDTH{1'b0}};
        diff_k_y_s1 <= 9'd0;
    end else begin
        vld_s1      <= valid_i;
        err_flag_s1 <= err_flag_cmb;
        if (valid_i) begin
            shift_a_s1  <= err_flag_cmb ? {INPUT_WIDTH{1'b0}} : shift_cmb;
            diff_k_y_s1 <= err_flag_cmb ? 9'd0 : diff_cmb;
        end
    end
end


wire [OUTPUT_N-1 : 0] norm_a;


generate
    if (OUTPUT_N >= INPUT_WIDTH) begin : gen_pad
        assign norm_a = {shift_a_s1, {(OUTPUT_N - INPUT_WIDTH){1'b0}}};
    end else begin : gen_trunc
        assign norm_a = shift_a_s1[INPUT_WIDTH-1 : INPUT_WIDTH-OUTPUT_N];
    end
endgenerate

wire [OUTPUT_N-1 : 0] dw_z_cmb;

// inst designware ip
DWFC_ln_24_1_1 dw_ln_inst (
    .a(norm_a),
    .z(dw_z_cmb)
);

wire signed [OUTPUT_WIDTH-1 : 0] nln2_cmb = diff_k_y_s1 * $signed(LN2_VAL);

always @(posedge clk) begin
    if (!rst_n) begin
        vld_s2           <= 1'b0;
        err_flag_s2      <= 1'b0;
        nln2_a_s2        <= {OUTPUT_WIDTH{1'b0}};
        result_norm_a_s2 <= {OUTPUT_N{1'b0}};
    end else begin
        vld_s2      <= vld_s1;
        err_flag_s2 <= err_flag_s1;
        if (vld_s1) begin
            nln2_a_s2        <= nln2_cmb;
            result_norm_a_s2 <= dw_z_cmb;
        end
    end
end


wire signed [OUTPUT_WIDTH-1 : 0] result_norm_a_ext = { {OUTPUT_M{1'b0}}, result_norm_a_s2 };
wire signed [OUTPUT_WIDTH-1 : 0] adder_cmb         = nln2_a_s2 + result_norm_a_ext;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_o  <= 1'b0;
        ln_value <= {OUTPUT_WIDTH{1'b0}};
    end else begin
        valid_o  <= vld_s2;
        if (vld_s2) begin
            ln_value <= err_flag_s2 ? {OUTPUT_WIDTH{1'b0}} : adder_cmb;
        end
    end
end

endmodule
