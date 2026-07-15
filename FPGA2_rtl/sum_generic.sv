module sum_generic #(
    parameter DATA_WIDTH = 16,
    parameter NUM_INPUTS = 32
) (
    input wire clk,
    input wire rst_n,
    input wire [NUM_INPUTS-1:0] [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output [DATA_WIDTH + $clog2(NUM_INPUTS) - 1:0] sum_out,
    output valid_out
);

//    // assert that NUM_INPUTS is a power of 2
//    initial begin
//        if ((NUM_INPUTS & (NUM_INPUTS - 1)) != 0 && NUM_INPUTS != 0) begin
//            $fatal(1, "Error: NUM_INPUTS in sum_generic module must be a power of two.");
//        end
//    end


    // number of pipeline stages 
    localparam NUM_STAGES = $clog2(NUM_INPUTS);

    genvar stage;
    generate
        for (stage = 0; stage < NUM_STAGES; stage = stage + 1) begin : gen_sum_pipeline_stage
        
            localparam IS_FIRST_STAGE = (stage == 0);
            localparam NUM_ITEMS_IN = NUM_INPUTS / (2**stage);
            localparam WIDTH_IN     = DATA_WIDTH + stage;
            localparam NUM_ITEMS_OUT = NUM_INPUTS / (2**(stage + 1));
            localparam WIDTH_OUT     = DATA_WIDTH + stage + 1;

            wire [NUM_ITEMS_IN-1:0] [WIDTH_IN-1:0] stage_data_in;
            wire stage_valid_in;

            reg [NUM_ITEMS_OUT-1:0] [WIDTH_OUT-1:0] stage_sum;
            reg stage_valid;

            if (IS_FIRST_STAGE) begin
                assign stage_data_in = data_in;
                assign stage_valid_in = valid_in;
            end else begin               
                assign stage_data_in = gen_sum_pipeline_stage[stage-1].stage_sum;
                assign stage_valid_in = gen_sum_pipeline_stage[stage-1].stage_valid;
            end

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_valid <= 1'b0;
                    for (int i = 0; i < NUM_ITEMS_OUT; i++) begin
                        stage_sum[i] <= '0;
                    end
                end else begin                  
                    stage_valid <= stage_valid_in;                  
                    for (int i = 0; i < NUM_ITEMS_OUT; i++) begin
                        stage_sum[i] <= stage_data_in[2*i] + stage_data_in[2*i + 1];
                    end
                end
            end
        end
    endgenerate

    // outputs from the last stage
    assign sum_out = gen_sum_pipeline_stage[NUM_STAGES-1].stage_sum[0];
    assign valid_out = gen_sum_pipeline_stage[NUM_STAGES-1].stage_valid;

endmodule
