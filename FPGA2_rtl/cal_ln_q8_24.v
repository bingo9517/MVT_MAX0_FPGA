/*
 * Author       : lib
 * Date         : 2026-07-16
 * Description  : 32-bit pipelined natural logarithm (ln) calculator.
 * Input        : Q8.24 unsigned fixed-point (a). Supports 0 < x < 256.
 * Output       : Q8.24 signed fixed-point (ln_value).
 * Architecture : Range reduction (x = m * 2^k) + PWL.
 */

module cal_ln_q8_24 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_i,
    input  wire [31:0]  a,
    output reg          valid_o,
    output reg  [31:0]  ln_value
);

    //==========================================================================
    // Stage 1: Leading One Detection (LOD), Normalization & k*ln(2) MUX
    //==========================================================================
    reg  [4:0]  lop_s1;
    reg         is_zero_s1_comb;
    reg  [31:0] norm_m_s1_comb;
    reg signed [31:0] k_ln2_s1_comb;
    
    reg  [31:0] norm_m_s1;
    reg signed [31:0] k_ln2_s1;
    reg         is_zero_s1;
    reg         vld_s1;

    always @(*) begin
        is_zero_s1_comb = 1'b0;
        casez (a)
            32'b1???_????_????_????_????_????_????_???? : lop_s1 = 5'd31;
            32'b01??_????_????_????_????_????_????_???? : lop_s1 = 5'd30;
            32'b001?_????_????_????_????_????_????_???? : lop_s1 = 5'd29;
            32'b0001_????_????_????_????_????_????_???? : lop_s1 = 5'd28;
            32'b0000_1???_????_????_????_????_????_???? : lop_s1 = 5'd27;
            32'b0000_01??_????_????_????_????_????_???? : lop_s1 = 5'd26;
            32'b0000_001?_????_????_????_????_????_???? : lop_s1 = 5'd25;
            32'b0000_0001_????_????_????_????_????_???? : lop_s1 = 5'd24;
            32'b0000_0000_1???_????_????_????_????_???? : lop_s1 = 5'd23;
            32'b0000_0000_01??_????_????_????_????_???? : lop_s1 = 5'd22;
            32'b0000_0000_001?_????_????_????_????_???? : lop_s1 = 5'd21;
            32'b0000_0000_0001_????_????_????_????_???? : lop_s1 = 5'd20;
            32'b0000_0000_0000_1???_????_????_????_???? : lop_s1 = 5'd19;
            32'b0000_0000_0000_01??_????_????_????_???? : lop_s1 = 5'd18;
            32'b0000_0000_0000_001?_????_????_????_???? : lop_s1 = 5'd17;
            32'b0000_0000_0000_0001_????_????_????_???? : lop_s1 = 5'd16;
            32'b0000_0000_0000_0000_1???_????_????_???? : lop_s1 = 5'd15;
            32'b0000_0000_0000_0000_01??_????_????_???? : lop_s1 = 5'd14;
            32'b0000_0000_0000_0000_001?_????_????_???? : lop_s1 = 5'd13;
            32'b0000_0000_0000_0000_0001_????_????_???? : lop_s1 = 5'd12;
            32'b0000_0000_0000_0000_0000_1???_????_???? : lop_s1 = 5'd11;
            32'b0000_0000_0000_0000_0000_01??_????_???? : lop_s1 = 5'd10;
            32'b0000_0000_0000_0000_0000_001?_????_???? : lop_s1 = 5'd9;
            32'b0000_0000_0000_0000_0000_0001_????_???? : lop_s1 = 5'd8;
            32'b0000_0000_0000_0000_0000_0000_1???_???? : lop_s1 = 5'd7;
            32'b0000_0000_0000_0000_0000_0000_01??_???? : lop_s1 = 5'd6;
            32'b0000_0000_0000_0000_0000_0000_001?_???? : lop_s1 = 5'd5;
            32'b0000_0000_0000_0000_0000_0000_0001_???? : lop_s1 = 5'd4;
            32'b0000_0000_0000_0000_0000_0000_0000_1??? : lop_s1 = 5'd3;
            32'b0000_0000_0000_0000_0000_0000_0000_01?? : lop_s1 = 5'd2;
            32'b0000_0000_0000_0000_0000_0000_0000_001? : lop_s1 = 5'd1;
            32'b0000_0000_0000_0000_0000_0000_0000_0001 : lop_s1 = 5'd0;
            default : begin
                lop_s1 = 5'd0;
                is_zero_s1_comb = 1'b1; // Flag for log(0) singularity
            end
        endcase
    end

    // Normalization and pre-calculated signed constant MUX for k * ln(2)
    // For Q8.24, k = lop_s1 - 24. Value = k * 11629080.
    always @(*) begin
        // Shift left to align the leading '1' to MSB (bit 31)
        norm_m_s1_comb = a << (5'd31 - lop_s1);

        case (lop_s1)
            5'd31: k_ln2_s1_comb =  32'sd81403560;
            5'd30: k_ln2_s1_comb =  32'sd69774480;
            5'd29: k_ln2_s1_comb =  32'sd58145400;
            5'd28: k_ln2_s1_comb =  32'sd46516320;
            5'd27: k_ln2_s1_comb =  32'sd34887240;
            5'd26: k_ln2_s1_comb =  32'sd23258160;
            5'd25: k_ln2_s1_comb =  32'sd11629080;
            5'd24: k_ln2_s1_comb =  32'sd0;
            5'd23: k_ln2_s1_comb = -32'sd11629080;
            5'd22: k_ln2_s1_comb = -32'sd23258160;
            5'd21: k_ln2_s1_comb = -32'sd34887240;
            5'd20: k_ln2_s1_comb = -32'sd46516320;
            5'd19: k_ln2_s1_comb = -32'sd58145400;
            5'd18: k_ln2_s1_comb = -32'sd69774480;
            5'd17: k_ln2_s1_comb = -32'sd81403560;
            5'd16: k_ln2_s1_comb = -32'sd93032640;
            5'd15: k_ln2_s1_comb = -32'sd104661720;
            5'd14: k_ln2_s1_comb = -32'sd116290800;
            5'd13: k_ln2_s1_comb = -32'sd127919880;
            5'd12: k_ln2_s1_comb = -32'sd139548960;
            5'd11: k_ln2_s1_comb = -32'sd151178040;
            5'd10: k_ln2_s1_comb = -32'sd162807120;
            5'd9:  k_ln2_s1_comb = -32'sd174436200;
            5'd8:  k_ln2_s1_comb = -32'sd186065280;
            5'd7:  k_ln2_s1_comb = -32'sd197694360;
            5'd6:  k_ln2_s1_comb = -32'sd209323440;
            5'd5:  k_ln2_s1_comb = -32'sd220952520;
            5'd4:  k_ln2_s1_comb = -32'sd232581600;
            5'd3:  k_ln2_s1_comb = -32'sd244210680;
            5'd2:  k_ln2_s1_comb = -32'sd255839760;
            5'd1:  k_ln2_s1_comb = -32'sd267468840;
            5'd0:  k_ln2_s1_comb = -32'sd279097920;
            default: k_ln2_s1_comb = 32'sd0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s1     <= 1'b0;
            norm_m_s1  <= 32'd0;
            k_ln2_s1   <= 32'sd0;
            is_zero_s1 <= 1'b0;
        end else begin
            vld_s1     <= valid_i;
            if (valid_i) begin
                norm_m_s1  <= norm_m_s1_comb;
                k_ln2_s1   <= k_ln2_s1_comb;
                is_zero_s1 <= is_zero_s1_comb;
            end
        end
    end

    //==========================================================================
    // Stage 2: ROM Read (48-bit Wide for Enhanced Precision)
    //==========================================================================
    wire [7:0]  addr_s1;
    wire [22:0] delta_s1;
    wire [47:0] rom_q_s2;        
    wire [23:0] rom_base_s2;
    wire [23:0] rom_slope_s2;
    
    reg  [22:0] delta_s2;
    reg signed [31:0] k_ln2_s2;
    reg         is_zero_s2;
    reg         vld_s2;

    assign addr_s1  = norm_m_s1[30:23]; 
    assign delta_s1 = norm_m_s1[22:0];  


    ln_lut_rom_256x48 u_ln_lut (
        .address ( addr_s1 ),
        .clock   ( clk ),
        .rden    ( vld_s1 ),           
        .q       ( rom_q_s2 )          
    );

    assign rom_base_s2  = rom_q_s2[47:24]; // Base  Q0.24
    assign rom_slope_s2 = rom_q_s2[23:0];  // Slope Q1.23

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s2     <= 1'b0;
            delta_s2   <= 23'd0;
            k_ln2_s2   <= 32'sd0;
            is_zero_s2 <= 1'b0;
        end else begin
            vld_s2     <= vld_s1;
            if (vld_s1) begin
                delta_s2   <= delta_s1;
                k_ln2_s2   <= k_ln2_s1;
                is_zero_s2 <= is_zero_s1;
            end
        end
    end

    //==========================================================================
    // Stage 3: High-Precision Multiplier IP (24x23)
    //==========================================================================
    wire [46:0] mult_result_s3; // 24 + 23 = 47 bits
    reg signed [31:0] k_ln2_s3;
    reg  [23:0] base_s3;
    reg         is_zero_s3;
    reg         vld_s3;

    multi_24x23bit multi_24x23bit_inst (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( rom_slope_s2 ),          // 24-bit Q1.23
        .datab  ( delta_s2 ),              // 23-bit relative fractional
        .result ( mult_result_s3 )         // 47-bit product
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s3     <= 1'b0;
            k_ln2_s3   <= 32'sd0;
            base_s3    <= 24'd0;
            is_zero_s3 <= 1'b0;
        end else begin
            vld_s3     <= vld_s2;
            if (vld_s2) begin
                k_ln2_s3   <= k_ln2_s2;
                base_s3    <= rom_base_s2;
                is_zero_s3 <= is_zero_s2;
            end
        end
    end

    //==========================================================================
    // Stage 4: Signed Accumulation & Exception Handling
    //==========================================================================
    // Weight logic: Product has a theoretical LSB weight of 2^-54
    // Target Q8.24 requires right shift of (54 - 24) = 30 bits.
    wire [31:0] delta_adj_s4;
    assign delta_adj_s4 = {15'd0, mult_result_s3[46:30]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o  <= 1'b0;
            ln_value <= 32'd0;
        end else begin
            valid_o  <= vld_s3;
            if (vld_s3) begin
                if (is_zero_s3) begin
                    // ln(0) = -inf, output max negative value of Q8.24
                    ln_value <= 32'h8000_0000; 
                end else begin
                    ln_value <= k_ln2_s3 + $signed({8'd0, base_s3}) + $signed(delta_adj_s4);
                end
            end
        end
    end

endmodule
