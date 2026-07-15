// Author: lib
// Date: 2026-04-16
// Description: CAL RAM control 

`include "./param.v"
module cal_ram_control #(
    parameter MAX_CAL_CNT = 24'd250000,
    parameter WAIT_CYCLES = 2'd2
)(
    input                                 clk_200m        ,
    input                                 reset_200m      ,
    input                                 dataout_valid_p ,
    input      [`TDC_LENGTH_POWER-2:0]    dataout_p_fine  ,
    input                                 Select_S        ,
    input                                 lut_finish_ram1 ,
    input                                 lut_finish_ram2 ,
    input      [23:0]                     cal_q           ,

    output reg [`TDC_LENGTH_POWER-2:0]    cal_address     ,
    output reg [23:0]                     cal_data        ,
    output reg                            cal_wren        ,
    output reg                            cal_rden        ,
    output reg                            cal_finish      
);

    localparam IDLE     = 7'b0000001;
    localparam CLEARRAM = 7'b0000010;
    localparam READ     = 7'b0000100;
    localparam WAIT     = 7'b0001000;
    localparam WRITE    = 7'b0010000;
    localparam FINISH   = 7'b0100000;
    localparam ACC      = 7'b1000000;
    
    reg [6:0] current_state;
    reg [6:0] next_state;
    
    reg [23:0] cal_cnt;
    reg [1:0]  cal_wait_cnt;

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
                if (Select_S) 
                    next_state = CLEARRAM;
            end

            CLEARRAM: begin
                if (cal_address == `CARRYCHAIN_LENGTH - 1) 
                    next_state = READ;
            end

            READ: begin     
                if (cal_rden) 
                    next_state = WAIT;
            end

            WAIT: begin     
                if (cal_wait_cnt == WAIT_CYCLES) 
                    next_state = WRITE;
            end

            WRITE: begin    
                if (cal_cnt == MAX_CAL_CNT) 
                    next_state = FINISH; 
                else 
                    next_state = READ;
            end

            FINISH: begin  
                next_state = ACC;
            end

            ACC:  begin    
                if (lut_finish_ram1 & lut_finish_ram2) 
                    next_state = IDLE;
            end

            default:  begin
                next_state = IDLE;
            end
            
        endcase
    end
    

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            cal_address  <= 'd0;
            cal_data     <= 24'd0;
            cal_wren     <= 1'b0;
            cal_rden     <= 1'b0;
            cal_finish   <= 1'b0;
            cal_cnt      <= 24'd0;
            cal_wait_cnt <= 2'd0;
        end else begin
            cal_address  <= cal_address;
            cal_data     <= 24'd0;
            cal_wren     <= 1'b0;
            cal_rden     <= 1'b0;
            cal_finish   <= 1'b0;
            cal_cnt      <= cal_cnt;
            cal_wait_cnt <= 2'd0;

            case (next_state)
                IDLE: begin
                    cal_address  <= 'd0;
                    cal_cnt      <= 24'd0;
                end
                CLEARRAM: begin
                    cal_address  <= cal_address + 1'b1;
                    cal_wren     <= 1'b1;
                end
                READ: begin
                    cal_address  <= dataout_p_fine;
                    cal_rden     <= dataout_valid_p;
                end
                WAIT: begin
                    cal_wait_cnt <= cal_wait_cnt + 2'd1;
                end
                WRITE: begin
                    cal_data     <= cal_q + 1'b1;
                    cal_wren     <= 1'b1;
                    cal_cnt      <= cal_cnt + 24'd1;
                end
                FINISH: begin
                    cal_address  <= 'd0;
                    cal_cnt      <= 24'd0;
                    cal_finish   <= 1'b1;
                end
                ACC: begin
                    cal_address  <= cal_address + 1'b1;
                    cal_rden     <= 1'b1;
                    cal_cnt      <= 24'd0;
                end
                default: begin
                    cal_address  <= 'd0;
                    cal_cnt      <= 24'd0;
                end
            endcase
        end
    end

endmodule
