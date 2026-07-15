// Author: lib
// Date: 2026-04-16
// Description: LUT RAM control add delay.

`include "./param.v"
module lut_ram_control #(
    parameter WAIT_CYCLES  = 5'd3 ,
    parameter FINISH_DELAY = 5'd20
)(
    input                                 clk_200m        ,
    input                                 reset_200m      ,
    input      [23:0]                     cal_q           ,
    input                                 cal_finish      ,
    input                                 MUX_S           ,
    input                                 dataout_valid   ,
    input      [`TDC_LENGTH_POWER-2:0]    dataout_fine    ,

    output reg [23:0]                     lut_data        ,
    output reg [`TDC_LENGTH_POWER-2:0]    lut_address     ,
    output reg                            lut_wren        ,
    output reg                            lut_rden        ,
    output reg                            lut_finish      
);


    localparam IDLE   = 5'b00001;
    localparam WAIT   = 5'b00010;
    localparam ACC    = 5'b00100;
    localparam FINISH = 5'b01000;
    localparam LUT    = 5'b10000;

    reg [4:0] current_state;
    reg [4:0] next_state;
    reg [4:0] delay_cnt;


    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    always @(*) begin
        next_state = current_state; 
        case (current_state)
            IDLE: begin
                if (cal_finish) 
                    next_state = WAIT;
            end

            WAIT: begin
                if (delay_cnt == WAIT_CYCLES) 
                    next_state = ACC;
            end

            ACC: begin
                if (lut_address == `CARRYCHAIN_LENGTH - 1) 
                    next_state = FINISH;
            end

            FINISH: begin
                if (!MUX_S && (delay_cnt == FINISH_DELAY)) 
                    next_state = LUT;
            end

            LUT: begin
                if (MUX_S) 
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end


    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            delay_cnt   <= 5'd0;
            lut_data    <= 24'd0;
            lut_address <= 'd0;
            lut_wren    <= 1'b0;
            lut_rden    <= 1'b0;
            lut_finish  <= 1'b0;
        end else begin
            delay_cnt   <= 5'd0;
            lut_data    <= 24'd0;
            lut_address <= 'd0;
            lut_wren    <= 1'b0;
            lut_rden    <= 1'b0;
            lut_finish  <= 1'b0;

            case (next_state)
                IDLE: begin
                end
                WAIT: begin
                    delay_cnt   <= delay_cnt + 1'b1;
                end
                ACC: begin
                    lut_data    <= lut_data + cal_q;
                    lut_address <= lut_address + 1'b1;
                    lut_wren    <= 1'b1;
                end
                FINISH: begin
                    lut_finish  <= 1'b1;
                    if (!MUX_S) begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                end
                LUT: begin
                    lut_address <= dataout_fine;
                    lut_rden    <= dataout_valid;
                end
                default: begin

                end
            endcase
        end
    end

endmodule
