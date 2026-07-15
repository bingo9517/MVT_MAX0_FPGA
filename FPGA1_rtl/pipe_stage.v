/****************************************************************************
* @Description:       pipe_stage.v
* @Author:     lib
* @Date:       2025-09-11
****************************************************************************/
module pipe_stage #(
    parameter DATA_WIDTH  = 1,      
    parameter STAGES      = 2,      
    parameter RESET_VALUE = 0       
) (
    input                           i_clk,      
    input                           i_rst_n,    
    input      [DATA_WIDTH-1:0]     i_data,     
    output     [DATA_WIDTH-1:0]     o_data      
);
    integer i;
    reg [DATA_WIDTH-1:0] pipeline_q [STAGES-1:0];

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                pipeline_q[i] <= RESET_VALUE;
            end
        end else begin
            pipeline_q[0] <= i_data;
            for ( i = 1; i < STAGES; i = i + 1) begin
                pipeline_q[i] <= pipeline_q[i-1];
            end
        end
    end
    assign o_data = (STAGES > 0) ? pipeline_q[STAGES-1] : i_data;
endmodule
