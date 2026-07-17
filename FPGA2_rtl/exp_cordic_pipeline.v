/*
 * Author       : lib
 * Date         : 2026-07-16
 * Description  : Pipelined exponential (e^x) calculator using LUT + PWL.
 * Input        : Q16.16 signed (Effective calculation range: 3.0 to 9.0).
 * Output       : Q16.16 signed.
 * Architecture : Direct segment addressing + Piece-Wise Linear interpolation.
 */

module exp_cordic_pipeline (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 valid_in,
    input  wire signed  [31:0]  x_in,       // Q16.16 
    output reg                  valid_out,
    output reg  signed  [31:0]  result_out  // Q16.16 
);

    //==========================================================================
    // Stage 1: Data slicing (Address & Delta extraction)
    //==========================================================================
    reg  [9:0]  addr_s1;
    reg  [9:0]  delta_s1;
    reg         vld_s1;

    // x_in is Q16.16. 
    // Integer part max is 9 (needs bits up to x_in[19]).
    // address (x_in[19:10]), 10 bits for delta (x_in[9:0]).
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s1   <= 1'b0;
            addr_s1  <= 10'd0;
            delta_s1 <= 10'd0;
        end else begin
            vld_s1 <= valid_in;
            if (valid_in) begin
                addr_s1  <= x_in[19:10]; 
                delta_s1 <= x_in[9:0];   
            end
        end
    end

    //==========================================================================
    // Stage 2: ROM Read (64-bit Wide: 32-bit Base + 32-bit Slope)
    //==========================================================================
    wire [63:0] rom_q_s2;        
    wire [31:0] rom_base_s2;
    wire [31:0] rom_slope_s2;
    
    reg  [9:0]  delta_s2;
    reg         vld_s2;

    exp_lut_rom_1024x64 u_exp_lut (
        .address ( addr_s1 ),
        .clock   ( clk ),
        .rden    ( vld_s1 ),           
        .q       ( rom_q_s2 )          
    );

    // Slice ROM data
    assign rom_base_s2  = rom_q_s2[63:32]; // Base  Q16.16
    assign rom_slope_s2 = rom_q_s2[31:0];  // Slope Q16.16

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s2   <= 1'b0;
            delta_s2 <= 10'd0;
        end else begin
            vld_s2 <= vld_s1;
            if (vld_s1) begin
                delta_s2 <= delta_s1;
            end
        end
    end

    //==========================================================================
    // Stage 3: Exact-width IP Multiplier (32x10)
    //==========================================================================
    wire [41:0] mult_result_s3; // 32 bits + 10 bits = 42 bits
    reg  [31:0] base_s3;
    reg         vld_s3;

    multi_32x10bit multi_32x10bit_inst (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( rom_slope_s2 ),         
        .datab  ( delta_s2 ),             
        .result ( mult_result_s3 )        
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s3  <= 1'b0;
            base_s3 <= 32'd0;
        end else begin
            vld_s3 <= vld_s2;
            if (vld_s2) begin
                base_s3 <= rom_base_s2;
            end
        end
    end

    //==========================================================================
    // Stage 4: Align & Accumulate (Final Phase)
    //==========================================================================
    // Multiplication weight calculation:
    // Slope is Q16.16. Delta is logically representing value * 2^(-16).
    // The product has a format of Q26.16.
    wire [31:0] delta_adj_s4;
    assign delta_adj_s4 = {6'd0, mult_result_s3[41:16]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out  <= 1'b0;
            result_out <= 32'd0;
        end else begin
            valid_out <= vld_s3;
            if (vld_s3) begin
                // Base (Q16.16) + Delta (Q16.16)
                result_out <= base_s3 + delta_adj_s4;
            end
        end
    end

endmodule
