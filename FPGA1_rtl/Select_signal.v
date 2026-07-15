//-----------------------------------------------------------------------------
// Author      : lib
// Date        : 2026-04-15
// Description : glitch-free switching. 
//-----------------------------------------------------------------------------

module Select_signal (
    input       clk_200m      ,
    input       reset_200m    ,
    input       Select_S      ,
    input       calibration_S ,
    input       lut_finish    ,
    input       r_Signal      ,
    
    output      mvt_datain    ,
    output      MUX_S         
);
    reg         calib_d1;
    reg         calib_d2;
    reg         calib_d3;
    wire        calib_neg;
    reg         lut_finish_r;
    wire        lut_finish_pos;
    reg         r_MUX_S;
    reg         wait_switch_flag;

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            calib_d1 <= 1'b0;
            calib_d2 <= 1'b0;
            calib_d3 <= 1'b0;
        end else begin
            calib_d1 <= calibration_S;
            calib_d2 <= calib_d1;
            calib_d3 <= calib_d2;
        end
    end

    assign calib_neg = (~calib_d2) & calib_d3;

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            lut_finish_r <= 1'b0;
        end else begin
            lut_finish_r <= lut_finish;
        end
    end

    assign lut_finish_pos = lut_finish & (~lut_finish_r);

    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            r_MUX_S          <= 1'b0;
            wait_switch_flag <= 1'b0;
        end else begin
            if (Select_S) begin
                r_MUX_S          <= 1'b1;
                wait_switch_flag <= 1'b0; 
            end else if (r_MUX_S) begin
                if (lut_finish_pos || wait_switch_flag) begin
                    if (calib_neg) begin
                        r_MUX_S          <= 1'b0;
                        wait_switch_flag <= 1'b0; 
                    end else begin
                        wait_switch_flag <= 1'b1; 
                    end
                end
            end
        end
    end

    assign mvt_datain = r_MUX_S ? calibration_S : r_Signal;
    assign MUX_S      = r_MUX_S;

endmodule