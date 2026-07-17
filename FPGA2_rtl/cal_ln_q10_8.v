/*
 * Author       : lib
 * Date         : 2026-07-16
 * Description  : Pipelined natural logarithm (ln) calculator,4 stages, for Q10.8 input and Q4.24 output.
 *               The module uses a 256-entry ROM for ln(m) values and linear interpolation for fractional parts.
 * Input        : Q10.8 fixed-point (a).
 * Output       : Q4.24 fixed-point (ln_value).
 * ROM          : Standard single-port ROM interface (address, clock, rden, q).
 */

module cal_ln_q10_8 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_i,
    input  wire [17:0]  a,
    output reg          valid_o,
    output reg  [27:0]  ln_value
);

    //==========================================================================
    // Stage 1: Leading One Detection (LOD), Normalization & k*ln(2) MUX
    //==========================================================================
    reg  [4:0]  lop_s1;
    reg  [17:0] norm_m_s1_comb;
    reg  [3:0]  k_s1;
    reg  [27:0] k_ln2_s1_comb;
    
    reg  [17:0] norm_m_s1;
    reg  [27:0] k_ln2_s1;
    reg         vld_s1;

    // Priority encoder for Q10.8 (Valid input >= 1.0, so lop_s1 >= 8)
    always @(*) begin
        casez (a[17:8])
            10'b1????_????? : lop_s1 = 5'd17;
            10'b01???_????? : lop_s1 = 5'd16;
            10'b001??_????? : lop_s1 = 5'd15;
            10'b0001?_????? : lop_s1 = 5'd14;
            10'b00001_????? : lop_s1 = 5'd13;
            10'b00000_1???? : lop_s1 = 5'd12;
            10'b00000_01??? : lop_s1 = 5'd11;
            10'b00000_001?? : lop_s1 = 5'd10;
            10'b00000_0001? : lop_s1 = 5'd9;
            default         : lop_s1 = 5'd8;
        endcase
    end

    // Normalization and k*ln(2) LUT MUX
    always @(*) begin
        norm_m_s1_comb = a << (5'd17 - lop_s1);
        k_s1           = lop_s1 - 5'd8;

        case (k_s1)
            4'd0:    k_ln2_s1_comb = 28'd0;         // 0 * ln(2)
            4'd1:    k_ln2_s1_comb = 28'd11629080;  // 1 * ln(2) * 2^24
            4'd2:    k_ln2_s1_comb = 28'd23258160;  // 2 * ln(2) * 2^24
            4'd3:    k_ln2_s1_comb = 28'd34887240;  // 3 * ln(2) * 2^24
            4'd4:    k_ln2_s1_comb = 28'd46516320;  // 4 * ln(2) * 2^24
            4'd5:    k_ln2_s1_comb = 28'd58145400;  // 5 * ln(2) * 2^24
            4'd6:    k_ln2_s1_comb = 28'd69774480;  // 6 * ln(2) * 2^24
            4'd7:    k_ln2_s1_comb = 28'd81403560;  // 7 * ln(2) * 2^24
            4'd8:    k_ln2_s1_comb = 28'd93032640;  // 8 * ln(2) * 2^24
            4'd9:    k_ln2_s1_comb = 28'd104661720; // 9 * ln(2) * 2^24
            default: k_ln2_s1_comb = 28'd0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s1    <= 1'b0;
            norm_m_s1 <= 18'd0;
            k_ln2_s1  <= 28'd0;
        end else begin
            vld_s1    <= valid_i;
            if (valid_i) begin
                norm_m_s1 <= norm_m_s1_comb;
                k_ln2_s1  <= k_ln2_s1_comb;
            end
        end
    end

    //==========================================================================
    // Stage 2: ROM Read & Control Signals Pipeline Alignment
    //==========================================================================
    wire [7:0]  addr_s1;
    wire [8:0]  delta_s1;
    wire [40:0] rom_q_s2;        
    wire [23:0] rom_base_s2;
    wire [16:0] rom_slope_s2;
    
    reg  [8:0]  delta_s2;
    reg  [27:0] k_ln2_s2;
    reg         vld_s2;

    assign addr_s1 = norm_m_s1[16:9];  // 8-bit ROM address
    assign delta_s1 = norm_m_s1[8:0];  // 9-bit interpolation delta

    ln_lut_rom_256x41 u_ln_lut (
        .address ( addr_s1 ),
        .clock   ( clk ),
        .rden    ( vld_s1 ),           
        .q       ( rom_q_s2 )          
    );

    // Slice the 41-bit  output into base and slope
    assign rom_base_s2  = rom_q_s2[40:17]; // Upper 24 bits base
    assign rom_slope_s2 = rom_q_s2[16:0];  // Lower 17 bits slope

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s2   <= 1'b0;
            delta_s2 <= 9'd0;
            k_ln2_s2 <= 28'd0;
        end else begin
            vld_s2   <= vld_s1;
            if (vld_s1) begin
                delta_s2 <= delta_s1;
                k_ln2_s2 <= k_ln2_s1;
            end
        end
    end

    //==========================================================================
    // Stage 3: Exact Width Multiplier IP Instantiation
    //==========================================================================
    wire [25:0] mult_result_s3; 
    reg  [27:0] k_ln2_s3;
    reg  [23:0] base_s3;
    reg         vld_s3;

    multi_17x9bit multi_17x9bit_inst (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( rom_slope_s2 ),          // 17-bit
        .datab  ( delta_s2 ),              // 9-bit
        .result ( mult_result_s3 )         // 26-bit product
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s3   <= 1'b0;
            k_ln2_s3 <= 28'd0;
            base_s3  <= 24'd0;
        end else begin
            vld_s3   <= vld_s2;
            if (vld_s2) begin
                k_ln2_s3 <= k_ln2_s2;
                base_s3  <= rom_base_s2;
            end
        end
    end

    //==========================================================================
    // Stage 4: Align & Accumulate (Final Phase)
    //==========================================================================
    wire [27:0] delta_adj_s4;
    assign delta_adj_s4 = {11'd0, mult_result_s3[25:9]}; // Wire truncation

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o  <= 1'b0;
            ln_value <= 28'd0;
        end else begin
            valid_o  <= vld_s3;
            if (vld_s3) begin
                ln_value <= k_ln2_s3 + {4'd0, base_s3} + delta_adj_s4;
            end
        end
    end

endmodule
