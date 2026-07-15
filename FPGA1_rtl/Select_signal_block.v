`include "./param.v"
module Select_signal_block(
    input                         clk_200m      ,
    input                         reset_200m    ,
    input                         Select_S      ,
    input                         calibration_S ,
    input                         lut_finish    ,
    input   [`MVT_THRESHOLDS_1-1:0] r_Signal      ,
              
    output  [`MVT_THRESHOLDS_1-1:0] mvt_datain    ,
    output  [`MVT_THRESHOLDS_1-1:0] MUX_S         
);

    genvar i;
    generate
        for(i = 0;i<`MVT_THRESHOLDS_1;i = i+1)begin:Select_signal_top
            Select_signal       u0(
              .clk_200m         (clk_200m         ),
              .reset_200m       (reset_200m       ),
              .Select_S         (Select_S         ),
              .calibration_S    (calibration_S    ),
              .r_Signal         (r_Signal[i]      ),
              .lut_finish       (lut_finish       ),
              .MUX_S            (MUX_S[i]         ),
              .mvt_datain       (mvt_datain[i]    ) 
            );
        end
    endgenerate
endmodule