//-----------------------------------------------------------------------------
// Author       : lib
// Date         : 2026-04-03
// Description  : Energy calculation  
//                ln_v_max = a - c + c*ln(|c|/|b|)
//-----------------------------------------------------------------------------
module energy_cal (
    input  wire               clk_200m,
    input  wire               reset_200m,
    input  wire signed [31:0] a,        // Q8.24
    input  wire signed [31:0] b,        // Q8.24
    input  wire signed [31:0] c,        // Q8.24
    input  wire               a_valid,
    input  wire               b_valid,
    input  wire               c_valid,
    output reg  signed [31:0] ln_v_max, // Q16.16
    output reg                o_valid
);

parameter IDLE      = 3'd0;
parameter FEED_B    = 3'd1;
parameter FEED_C    = 3'd2;
parameter WAIT_B    = 3'd3;
parameter WAIT_C    = 3'd4;
parameter MULT_WAIT = 3'd5;
parameter CALC_ADD  = 3'd6;


reg  [2:0] current_state;
reg  [2:0] next_state;

reg  a_vld_r, b_vld_r, c_vld_r;
wire all_rdy = a_vld_r & b_vld_r & c_vld_r;

reg  signed [31:0] a_reg, b_reg, c_reg;
reg  signed [39:0] a_sub_c;
reg  signed [31:0] ln_b_reg;
reg  signed [31:0] delta_ln;
wire signed [63:0] mul_out;


reg                ln_vld_in;
reg  [31:0]        ln_data_in;
wire               ln_vld_out;
wire signed [31:0] ln_data_out;


always @(posedge clk_200m) begin
    if (!reset_200m) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end


always @(*) begin
    next_state = current_state;
    case (current_state)
        IDLE:      if (all_rdy) next_state = FEED_B;
        FEED_B:    next_state = FEED_C;
        FEED_C:    next_state = WAIT_B;
        WAIT_B:    if (ln_vld_out) next_state = WAIT_C;
        WAIT_C:    if (ln_vld_out) next_state = MULT_WAIT;
        MULT_WAIT: next_state = CALC_ADD; 
        CALC_ADD:  next_state = IDLE;
        default:   next_state = IDLE;
    endcase
end


always @(posedge clk_200m) begin
    if (!reset_200m) begin
        a_vld_r    <= 1'b0;
        b_vld_r    <= 1'b0;
        c_vld_r    <= 1'b0;
        o_valid    <= 1'b0;
        ln_v_max   <= 32'd0;
        ln_vld_in  <= 1'b0;
        ln_data_in <= 32'd0;
        a_reg      <= 32'd0;
        b_reg      <= 32'd0;
        c_reg      <= 32'd0;
        a_sub_c    <= 40'd0;
        ln_b_reg   <= 32'd0;
        delta_ln   <= 32'd0;
    end else begin

        o_valid   <= 1'b0;
        ln_vld_in <= 1'b0;

        if (a_valid) begin a_reg <= a; a_vld_r <= 1'b1; end
        if (b_valid) begin b_reg <= b; b_vld_r <= 1'b1; end
        if (c_valid) begin c_reg <= c; c_vld_r <= 1'b1; end

        case (current_state)
            IDLE: begin
                if (all_rdy) begin
                    a_vld_r <= 1'b0;
                    b_vld_r <= 1'b0;
                    c_vld_r <= 1'b0;
                    a_sub_c <= { {8{a_reg[31]}}, a_reg } - { {8{c_reg[31]}}, c_reg };
                end
            end
            FEED_B: begin
                ln_vld_in  <= 1'b1;
                ln_data_in <= b_reg[31] ? (~b_reg + 1'b1) : b_reg; 
            end
            FEED_C: begin
                ln_vld_in  <= 1'b1;
                ln_data_in <= c_reg[31] ? (~c_reg + 1'b1) : c_reg; 
            end
            WAIT_B: begin
                if (ln_vld_out) begin
                    ln_b_reg <= ln_data_out;
                end
            end
            WAIT_C: begin
                if (ln_vld_out) begin
                    delta_ln <= ln_data_out - ln_b_reg;
                end
            end
            MULT_WAIT: begin
                
            end
            CALC_ADD: begin
                ln_v_max <= a_sub_c[39:8] + mul_out[63:32];
                o_valid  <= 1'b1;
            end
        endcase
    end
end

//-------------------------------------------------------------------
// Multiplier (1-cycle latency)
//-------------------------------------------------------------------
// Q8.24 * Q8.24 = Q16.48
multi_32x32bit_sign multi_32x32bit_sign_inst (
    .clock  (clk_200m),
    .aclr   (~reset_200m),
    .datab  (delta_ln),
    .dataa  (c_reg),
    .result (mul_out)
);

//-------------------------------------------------------------------
// Logarithmt, input Qx.y, output Qm.n
//-------------------------------------------------------------------
cal_ln_q8_24 u_cal_ln (
    .clk      (clk_200m),
    .rst_n    (reset_200m),
    .valid_i  (ln_vld_in),
    .a        (ln_data_in),
    .valid_o  (ln_vld_out),
    .ln_value (ln_data_out)
);

endmodule
