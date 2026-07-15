//-----------------------------------------------------------------------------
// Author       : lib
// Date         : 2026-04-03
// Description  : Calculate ln(x) for 16-bit Q16.0 input, output 28-bit Q4.24
//-----------------------------------------------------------------------------
module cal_ln_q16_0 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_i,
    input  wire [15:0] a,
    output reg         valid_o,
    output reg  [27:0] ln_value
);


parameter INPUT_WIDTH      = 16;
parameter OUTPUT_WIDTH     = 28;
parameter OUTPUT_DEC_WIDTH = 24;

//Q4.24
localparam [27:0] RESULT_0LN2  = 28'h000_0000; // 0
localparam [27:0] RESULT_1LN2  = 28'h0B1_7218; // 1*ln2
localparam [27:0] RESULT_2LN2  = 28'h162_E430; // 2*ln2
localparam [27:0] RESULT_3LN2  = 28'h214_5648; // 3*ln2
localparam [27:0] RESULT_4LN2  = 28'h2C5_C860; // 4*ln2
localparam [27:0] RESULT_5LN2  = 28'h377_3A78; // 5*ln2
localparam [27:0] RESULT_6LN2  = 28'h428_AC90; // 6*ln2
localparam [27:0] RESULT_7LN2  = 28'h4DA_1EA8; // 7*ln2
localparam [27:0] RESULT_8LN2  = 28'h58B_90C0; // 8*ln2
localparam [27:0] RESULT_9LN2  = 28'h63D_02D8; // 9*ln2
localparam [27:0] RESULT_10LN2 = 28'h6EE_74F0; // 10*ln2
localparam [27:0] RESULT_11LN2 = 28'h79F_E708; // 11*ln2
localparam [27:0] RESULT_12LN2 = 28'h851_5920; // 12*ln2
localparam [27:0] RESULT_13LN2 = 28'h902_CB38; // 13*ln2
localparam [27:0] RESULT_14LN2 = 28'h9B4_3D50; // 14*ln2
localparam [27:0] RESULT_15LN2 = 28'hA65_AF68; // 15*ln2


reg  [INPUT_WIDTH-1:0] shift_a;
reg  [OUTPUT_WIDTH-1:0] nln2_a;
reg                    d1_valid_i;
reg                    err_flag;

wire [OUTPUT_WIDTH-1:0] ln_value_tmp;
wire [OUTPUT_DEC_WIDTH-1:0] norm_a;
wire [OUTPUT_DEC_WIDTH-1:0] result_norm_a;


always @(posedge clk) begin
    if (valid_i) begin
        if (~|a) begin // a == 0
            shift_a  <= a;
            nln2_a   <= {(OUTPUT_WIDTH){1'b0}};
            err_flag <= 1'b1;
        end else begin
            err_flag <= 1'b0;
            casez (a) // nln2 + ln(norm_a)
                16'b1???_????_????_????: begin shift_a <= a << 0;  nln2_a <= RESULT_15LN2; end // n=15
                16'b01??_????_????_????: begin shift_a <= a << 1;  nln2_a <= RESULT_14LN2; end // n=14
                16'b001?_????_????_????: begin shift_a <= a << 2;  nln2_a <= RESULT_13LN2; end // n=13
                16'b0001_????_????_????: begin shift_a <= a << 3;  nln2_a <= RESULT_12LN2; end // n=12
                16'b0000_1???_????_????: begin shift_a <= a << 4;  nln2_a <= RESULT_11LN2; end // n=11
                16'b0000_01??_????_????: begin shift_a <= a << 5;  nln2_a <= RESULT_10LN2; end // n=10
                16'b0000_001?_????_????: begin shift_a <= a << 6;  nln2_a <= RESULT_9LN2;  end // n=9
                16'b0000_0001_????_????: begin shift_a <= a << 7;  nln2_a <= RESULT_8LN2;  end // n=8
                16'b0000_0000_1???_????: begin shift_a <= a << 8;  nln2_a <= RESULT_7LN2;  end // n=7
                16'b0000_0000_01??_????: begin shift_a <= a << 9;  nln2_a <= RESULT_6LN2;  end // n=6
                16'b0000_0000_001?_????: begin shift_a <= a << 10; nln2_a <= RESULT_5LN2;  end // n=5
                16'b0000_0000_0001_????: begin shift_a <= a << 11; nln2_a <= RESULT_4LN2;  end // n=4
                16'b0000_0000_0000_1???: begin shift_a <= a << 12; nln2_a <= RESULT_3LN2;  end // n=3
                16'b0000_0000_0000_01??: begin shift_a <= a << 13; nln2_a <= RESULT_2LN2;  end // n=2
                16'b0000_0000_0000_001?: begin shift_a <= a << 14; nln2_a <= RESULT_1LN2;  end // n=1
                default:                 begin shift_a <= a << 15; nln2_a <= RESULT_0LN2;  end // n=0
            endcase
        end
    end else begin
        shift_a  <= shift_a;
        nln2_a   <= nln2_a;
        err_flag <= err_flag;
    end
end


assign norm_a = {shift_a, {(OUTPUT_DEC_WIDTH - INPUT_WIDTH){1'b0}}};

// inst designware ip, Q0.24 input and output
DWFC_ln_24_1_1 dw_ln_inst1 (
    .a(norm_a),
    .z(result_norm_a)
);

reg [OUTPUT_DEC_WIDTH-1:0] result_norm_a_r;
reg d2_valid_i;
always @(posedge clk) begin
    if (!rst_n) begin
        result_norm_a_r <= 'b0;
    end else begin
        result_norm_a_r <= result_norm_a;
    end
end

assign ln_value_tmp = nln2_a + {4'b0, result_norm_a_r};

always @(posedge clk) begin
    if (!rst_n) begin
        d1_valid_i <= 1'b0;
	d2_valid_i <= 1'b0;
        valid_o    <= 1'b0;
    end else begin
        d1_valid_i <= valid_i;
	d2_valid_i <= d1_valid_i;
        valid_o    <= d2_valid_i;
    end
end


always @(posedge clk) begin 
    if (!rst_n) begin
        ln_value <= {(OUTPUT_WIDTH){1'b0}};
    end else begin
        if (d2_valid_i) begin
            ln_value <= err_flag ? {(OUTPUT_WIDTH){1'b0}} : ln_value_tmp;
        end else begin
            ln_value <= ln_value;
        end
    end
end

endmodule
