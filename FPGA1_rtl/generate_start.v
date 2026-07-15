// Author: lib
// Date: 2026-04-14
// Description: Start pulse generator with delay and retrigger logic;
//              START/next_start is active low, clk_200m domain.

module generate_start #(
    parameter  DELAY_CYCLES = 64
)(
    input   clk_200m  ,
    input   reset_200m,
//    input   [7:0]   rx_data      ,
//    input           rx_done      ,
//    output          AcqRstSignal ,
    input   next_start,
    output  START     
);

    reg [6:0] cnt;
    reg       init_done;
    reg       START_reg;

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            cnt       <= 7'd0;
            init_done <= 1'b0;
            START_reg <= 1'b1; 
        end else begin
            START_reg <= 1'b1; 
            if (!init_done) begin
                if (cnt == DELAY_CYCLES - 7'd1) begin
                    init_done <= 1'b1;
                    START_reg <= 1'b0; 
                end else begin
                    cnt <= cnt + 7'd1;
                end
            end else if (next_start) begin
                START_reg <= 1'b0; 
            end
        end
    end

 //   assign AcqRstSignal = ( (rx_data == 8'h52) & rx_done )?1'b0:1'b1;    
    
    assign START = START_reg;

endmodule