// Author: lib
// Date: 2026-04-14
// Description: Temperature change detection with latched reference.
//    beta = delta_D/delta_T = 5.864 cnt/°C, 25°C -> 150°C, 40ps -> 47ps for max fpga

module tempchange #(
    parameter signed [15:0] THRESHOLD = 16'sd100
)(
    input          clk_200m  ,
    input          reset_200m,
    input   [15:0] Dout      ,
    input          Dout_valid,
    output reg     Select_S  
);

    localparam ST_INIT = 1'b0;
    localparam ST_WORK = 1'b1;

    reg                curr_state;
    reg                next_state;
    
    reg signed [15:0]  val_ref;
    wire signed [15:0] val_cur;
    wire signed [16:0] val_diff;
    wire signed [16:0] abs_diff;

    assign val_cur  = $signed(Dout);
    assign val_diff = val_cur - val_ref;
    assign abs_diff = (val_diff < 17'd0) ? -val_diff : val_diff;


    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            curr_state <= ST_INIT;
        end else begin
            curr_state <= next_state;
        end
    end

    always @(*) begin
        next_state = curr_state;
        case (curr_state)
            ST_INIT: begin
                if (Dout_valid) next_state = ST_WORK;
            end
            ST_WORK: begin
                next_state = ST_WORK;
            end
            default: next_state = ST_INIT;
        endcase
    end


    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            val_ref  <= 16'd0;
            Select_S <= 1'b0;
        end else begin
            Select_S <= 1'b0; 
            case (curr_state)
                ST_INIT: begin
                    if (Dout_valid) begin
                        val_ref  <= val_cur;
                        Select_S <= 1'b1; 
                    end
                end
                ST_WORK: begin
                    if (Dout_valid) begin
                        val_ref  <= val_cur;
                        if (abs_diff > THRESHOLD) begin 
                            Select_S <= 1'b1; 
                        end
                    end
                end
            endcase
        end
    end

endmodule