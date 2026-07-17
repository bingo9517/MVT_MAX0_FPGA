/*
 * Author       : lib
 * Date         : 2026-07-16
 * Description  : Pipelined natural logarithm (ln) calculator.
 * Input        : Q16.0 unsigned integer (a).
 * Output       : Q4.24 fixed-point (ln_value).
 * Architecture : Range reduction (x = m * 2^k) + PWL.
 * ROM          : Standard single-port ROM interface (Reused from Q10.8).
 */

module cal_ln_q16_0 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_i,
    input  wire [15:0]  a,
    output reg          valid_o,
    output reg  [27:0]  ln_value
);

    //==========================================================================
    // Stage 1: Leading One Detection (LOD), Normalization & k*ln(2) MUX
    //==========================================================================
    reg  [3:0]  lop_s1;          // 0~15 for 16-bit input
    reg  [15:0] norm_m_s1_comb;
    reg  [27:0] k_ln2_s1_comb;
    
    reg  [15:0] norm_m_s1;
    reg  [27:0] k_ln2_s1;
    reg         vld_s1;

    // Priority encoder for Q16.0
    always @(*) begin
        casez (a)
            16'b1???_????_????_???? : lop_s1 = 4'd15;
            16'b01??_????_????_???? : lop_s1 = 4'd14;
            16'b001?_????_????_???? : lop_s1 = 4'd13;
            16'b0001_????_????_???? : lop_s1 = 4'd12;
            16'b0000_1???_????_???? : lop_s1 = 4'd11;
            16'b0000_01??_????_???? : lop_s1 = 4'd10;
            16'b0000_001?_????_???? : lop_s1 = 4'd9;
            16'b0000_0001_????_???? : lop_s1 = 4'd8;
            16'b0000_0000_1???_???? : lop_s1 = 4'd7;
            16'b0000_0000_01??_???? : lop_s1 = 4'd6;
            16'b0000_0000_001?_???? : lop_s1 = 4'd5;
            16'b0000_0000_0001_???? : lop_s1 = 4'd4;
            16'b0000_0000_0000_1??? : lop_s1 = 4'd3;
            16'b0000_0000_0000_01?? : lop_s1 = 4'd2;
            16'b0000_0000_0000_001? : lop_s1 = 4'd1;
            default                 : lop_s1 = 4'd0;
        endcase
    end

    always @(*) begin
        // Shift left to align the leading '1' to MSB (bit 15)
        norm_m_s1_comb = a << (4'd15 - lop_s1);

        // High-precision rounded constants for round(k * ln(2) * 2^24)
        // Since input is Q16.0, k is exactly equal to the LOP
        case (lop_s1)
            4'd0:  k_ln2_s1_comb = 28'd0;
            4'd1:  k_ln2_s1_comb = 28'd11629080;
            4'd2:  k_ln2_s1_comb = 28'd23258161;
            4'd3:  k_ln2_s1_comb = 28'd34887241;
            4'd4:  k_ln2_s1_comb = 28'd46516322;
            4'd5:  k_ln2_s1_comb = 28'd58145402;
            4'd6:  k_ln2_s1_comb = 28'd69774483;
            4'd7:  k_ln2_s1_comb = 28'd81403563;
            4'd8:  k_ln2_s1_comb = 28'd93032644;
            4'd9:  k_ln2_s1_comb = 28'd104661724;
            4'd10: k_ln2_s1_comb = 28'd116290805;
            4'd11: k_ln2_s1_comb = 28'd127919885;
            4'd12: k_ln2_s1_comb = 28'd139548966;
            4'd13: k_ln2_s1_comb = 28'd151178046;
            4'd14: k_ln2_s1_comb = 28'd162807126;
            4'd15: k_ln2_s1_comb = 28'd174436207;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s1    <= 1'b0;
            norm_m_s1 <= 16'd0;
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
    wire [6:0]  delta_s1;
    wire [40:0] rom_q_s2;        
    wire [23:0] rom_base_s2;
    wire [16:0] rom_slope_s2;
    
    reg  [6:0]  delta_s2;
    reg  [27:0] k_ln2_s2;
    reg         vld_s2;

    //  address (8 bits) and delta (remaining 7 bits)
    assign addr_s1  = norm_m_s1[14:7]; 
    assign delta_s1 = norm_m_s1[6:0];  

    ln_lut_rom_256x41 u_ln_lut (
        .address ( addr_s1 ),
        .clock   ( clk ),
        .rden    ( vld_s1 ),           
        .q       ( rom_q_s2 )          
    );

    assign rom_base_s2  = rom_q_s2[40:17]; 
    assign rom_slope_s2 = rom_q_s2[16:0];  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s2   <= 1'b0;
            delta_s2 <= 7'd0;
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
    // Stage 3: Exact Width Multiplier IP Instantiation (17x7)
    //==========================================================================
    wire [23:0] mult_result_s3; // 17 + 7 = 24 bits
    reg  [27:0] k_ln2_s3;
    reg  [23:0] base_s3;
    reg         vld_s3;

    multi_17x7bit multi_17x7bit_inst (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( rom_slope_s2 ),          // 17-bit
        .datab  ( delta_s2 ),              // 7-bit
        .result ( mult_result_s3 )         // 24-bit product
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
    // Multiplication weight: Slope(Q1.16) * Delta(Q0.15 relative) = Q1.31
    // Target output weight : Q4.24
    // Required right shift : 31 - 24 = 7 bits
    wire [27:0] delta_adj_s4;
    assign delta_adj_s4 = {11'd0, mult_result_s3[23:7]};

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