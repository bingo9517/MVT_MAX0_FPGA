// Author: lib
// Date: 2026-04-14
// Description: use oversampling for synchronous frequency counter.
// Note: Tosc period is more than 2x of clk_200m period.

module VGTA #(
    parameter [15:0] N = 16'd2048
)(
    input  wire        clk_200m  ,
    input  wire        reset_200m,
    input  wire        Tosc      ,
    input  wire        START     , 
    output reg         next_start,
    output reg  [15:0] Dout      ,
    output reg         Dout_valid
);

   wire clk_tosc;
   `ifdef SMIC125
      CLKBUFV6_9TR U_BUF (.I(Tosc), .Z(clk_tosc));
   `elsif SMIC150
      CLKBUFV6_9TR U_BUF (.I(Tosc), .Z(clk_tosc));
   `elsif SHS125
      CLKBUFX8 U_BUF (.A(Tosc), .Y(clk_tosc));
   `else
      assign clk_tosc = Tosc;
   `endif


    reg tosc_sync1, tosc_sync2, tosc_sync3;
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            tosc_sync1 <= 1'b0;
            tosc_sync2 <= 1'b0;
            tosc_sync3 <= 1'b0;
        end else begin
            tosc_sync1 <= clk_tosc;
            tosc_sync2 <= tosc_sync1;
            tosc_sync3 <= tosc_sync2;
        end
    end

  
    wire tosc_rising = tosc_sync2 & ~tosc_sync3;

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] SYNC = 2'd1;
    localparam [1:0] MEAS = 2'd2;

    reg [1:0] current_state;
    reg [1:0] next_state;
    
    reg [15:0] tosc_cnt;
    reg [15:0] clk_cnt;

  
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
                if (!START) next_state = SYNC;
            end
            SYNC: begin
                if (tosc_rising) next_state = MEAS;
            end
            MEAS: begin
                if (tosc_rising && (tosc_cnt == N - 16'd1)) begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end


    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            tosc_cnt   <= 16'd0;
            clk_cnt    <= 16'd0;
            Dout       <= 16'd0;
            Dout_valid <= 1'b0;
            next_start <= 1'b0;
        end else begin
            Dout_valid <= 1'b0;
            next_start <= 1'b0;

            case (current_state)
                IDLE: begin
                    tosc_cnt <= 16'd0;
                    clk_cnt  <= 16'd0;
                end
                SYNC: begin
                    tosc_cnt <= 16'd0;
                    clk_cnt  <= 16'd0;
                end
                MEAS: begin
                    clk_cnt <= clk_cnt + 16'd1;
                    if (tosc_rising) begin
                        tosc_cnt <= tosc_cnt + 16'd1;
                        if (tosc_cnt == N - 16'd1) begin
                            Dout       <= clk_cnt;
                            Dout_valid <= 1'b1;
                            next_start <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule