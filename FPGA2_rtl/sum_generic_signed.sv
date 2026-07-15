// Author: lib
// Date: 2026-04-21
// Description: signed pipelined adder tree 

module sum_generic_signed #(
    parameter DATA_WIDTH = 16,
    parameter NUM_INPUTS = 32
) (
    input  wire clk,
    input  wire rst_n,
    input  wire [NUM_INPUTS-1:0] [DATA_WIDTH-1:0] data_in,
    input  wire valid_in,
    output wire [DATA_WIDTH + $clog2(NUM_INPUTS) - 1:0] sum_out,
    output wire valid_out
);

    localparam NUM_STAGES = $clog2(NUM_INPUTS);

    genvar stage;
    generate
        for (stage = 0; stage < NUM_STAGES; stage = stage + 1) begin : gen_sum_pipeline_stage
        
            localparam IS_FIRST_STAGE = (stage == 0);
            localparam NUM_ITEMS_IN   = NUM_INPUTS / (2**stage);
            localparam WIDTH_IN       = DATA_WIDTH + stage;
            localparam NUM_ITEMS_OUT  = NUM_INPUTS / (2**(stage + 1));
            localparam WIDTH_OUT      = DATA_WIDTH + stage + 1;

            wire [NUM_ITEMS_IN-1:0] [WIDTH_IN-1:0] stage_data_in;
            wire stage_valid_in;

            reg  [NUM_ITEMS_OUT-1:0] [WIDTH_OUT-1:0] stage_sum;
            reg  stage_valid;

            if (IS_FIRST_STAGE) begin
                assign stage_data_in  = data_in;
                assign stage_valid_in = valid_in;
            end else begin               
                assign stage_data_in  = gen_sum_pipeline_stage[stage-1].stage_sum;
                assign stage_valid_in = gen_sum_pipeline_stage[stage-1].stage_valid;
            end

            integer i;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_valid <= 1'b0;
                    for (i = 0; i < NUM_ITEMS_OUT; i = i + 1) begin
                        stage_sum[i] <= {WIDTH_OUT{1'b0}};
                    end
                end else begin                  
                    stage_valid <= stage_valid_in;
                    for (i = 0; i < NUM_ITEMS_OUT; i = i + 1) begin
                        //sign extension for signed addition
                        stage_sum[i] <= {stage_data_in[2*i][WIDTH_IN-1], stage_data_in[2*i]} + 
                                        {stage_data_in[2*i + 1][WIDTH_IN-1], stage_data_in[2*i + 1]};
                    end
                end
            end
        end
    endgenerate

    assign sum_out   = gen_sum_pipeline_stage[NUM_STAGES-1].stage_sum[0];
    assign valid_out = gen_sum_pipeline_stage[NUM_STAGES-1].stage_valid;

endmodule