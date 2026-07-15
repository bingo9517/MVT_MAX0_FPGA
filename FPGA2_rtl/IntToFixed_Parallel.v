// Author:         lib
// Date:           2025-11-18
/**
 *  QUOTIENT_WIDTH - Bit width of the integer quotient.
 *  OPERAND_WIDTH  - Bit width of the remainder and divisor.
 *  PIPELINE_STAGES - Number of pipeline stages for fractional calculation
 *  Handles signed inputs where remainder can be negative.
 */

module IntToFixed_Parallel #(
    parameter QUOTIENT_WIDTH = 8,
    parameter OPERAND_WIDTH  = 16,
    parameter FRACTIONAL_BITS = 16,
    parameter PIPELINE_STAGES = 4  
)(
    input wire                      clk,
    input wire                      rst_n, 
    input wire                      i_valid,

    input wire signed  [QUOTIENT_WIDTH-1:0] i_quotient,  // Changed to signed
    input wire signed  [OPERAND_WIDTH-1:0]  i_remainder, // Changed to signed
    input wire signed  [OPERAND_WIDTH-1:0]  i_divisor,   // Changed to signed 

    output wire                     o_valid,
    output wire signed  [QUOTIENT_WIDTH+FRACTIONAL_BITS-1:0] o_q_out // Changed to signed
);
    localparam BITS_PER_STAGE = FRACTIONAL_BITS / PIPELINE_STAGES; 
    wire remainder_is_negative = i_remainder[OPERAND_WIDTH-1]; 
    
    wire signed [QUOTIENT_WIDTH-1:0] adjusted_quotient;
    wire [OPERAND_WIDTH:0]           adjusted_remainder; 
    wire [OPERAND_WIDTH-1:0]         adjusted_divisor;   

    assign adjusted_quotient = remainder_is_negative ? (i_quotient - 1'b1) : i_quotient;
    wire signed [OPERAND_WIDTH-1:0] pos_remainder_calc = i_remainder + i_divisor;

    assign adjusted_remainder = remainder_is_negative ? 
                                {1'b0, pos_remainder_calc} : 
                                {1'b0, i_remainder};          

    assign adjusted_divisor = i_divisor[OPERAND_WIDTH-1:0];

    reg [PIPELINE_STAGES:0]          valid_pipe;
    reg signed [QUOTIENT_WIDTH-1:0]  quotient_pipe [0:PIPELINE_STAGES]; 
    reg [OPERAND_WIDTH:0]            remainder_pipe [0:PIPELINE_STAGES]; 
    reg [OPERAND_WIDTH-1:0]          divisor_pipe [0:PIPELINE_STAGES];  
    reg [FRACTIONAL_BITS-1:0]        frac_accum_pipe [0:PIPELINE_STAGES]; 
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe[0] <= 1'b0;
            quotient_pipe[0] <= 0; 
            remainder_pipe[0] <= 0;
            divisor_pipe[0] <= 0;
            frac_accum_pipe[0] <= 0;
        end else begin 
            valid_pipe[0] <= i_valid;
            if (i_valid) begin 
                quotient_pipe[0] <= adjusted_quotient;
                remainder_pipe[0] <= adjusted_remainder;   
                divisor_pipe[0] <= adjusted_divisor;     
                frac_accum_pipe[0] <= 0;
            end
        end
    end


    genvar stage, bit_idx;
    generate 
        for (stage = 0; stage < PIPELINE_STAGES; stage = stage + 1) begin : gen_pipeline_stage
            localparam START_BIT = stage * BITS_PER_STAGE;
            localparam END_BIT = (stage == PIPELINE_STAGES-1) ? 
                                FRACTIONAL_BITS-1 : 
                                (stage + 1) * BITS_PER_STAGE - 1; 
            
            localparam STAGE_BITS = END_BIT - START_BIT + 1; 
           
            wire [OPERAND_WIDTH:0] stage_remainders [0:STAGE_BITS]; 
            wire [STAGE_BITS-1:0] stage_frac_bits; 
            
            assign stage_remainders[0] = remainder_pipe[stage];
            
            for (bit_idx = 0; bit_idx < STAGE_BITS; bit_idx = bit_idx + 1) begin : gen_stage_bits
                
                wire [OPERAND_WIDTH:0] shifted_rem = stage_remainders[bit_idx] << 1;
                wire [OPERAND_WIDTH:0] extended_divisor = {1'b0, divisor_pipe[stage]}; 
                wire subtract_en = (shifted_rem >= extended_divisor);
                
                assign stage_frac_bits[STAGE_BITS-1-bit_idx] = subtract_en;
                assign stage_remainders[bit_idx+1] = subtract_en ? 
                    (shifted_rem - extended_divisor) : shifted_rem; 
            end 
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_pipe[stage+1] <= 1'b0;
                    quotient_pipe[stage+1] <= 0; 
                    remainder_pipe[stage+1] <= 0;
                    divisor_pipe[stage+1] <= 0;
                    frac_accum_pipe[stage+1] <= 0;
                end else begin 
                    valid_pipe[stage+1] <= valid_pipe[stage];
                    quotient_pipe[stage+1] <= quotient_pipe[stage]; 
                    remainder_pipe[stage+1] <= stage_remainders[STAGE_BITS];
                    divisor_pipe[stage+1] <= divisor_pipe[stage];
                    
                    
                    if (stage == 0) begin
                        frac_accum_pipe[stage+1] <= {{(FRACTIONAL_BITS-STAGE_BITS){1'b0}}, stage_frac_bits};
                    end else begin 
                        frac_accum_pipe[stage+1] <= (frac_accum_pipe[stage] << STAGE_BITS) |
                                                    ({{(FRACTIONAL_BITS-STAGE_BITS){1'b0}}, stage_frac_bits});
                    end
                end
            end
            
        end
    endgenerate

    assign o_valid = valid_pipe[PIPELINE_STAGES];
    assign o_q_out = {quotient_pipe[PIPELINE_STAGES], frac_accum_pipe[PIPELINE_STAGES]};

endmodule
