`include "./param.v"
module ch_latch_block(
    input                                 clk_200m                ,
    input                                 reset_200m              ,
    input   [`MVT_THRESHOLDS_1-1:0][23:0]   p_lut_q                 ,
    input   [`MVT_THRESHOLDS_1-1:0][23:0]   n_lut_q                 ,
    input   [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_p_all_dalay     ,
    input   [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_n_all_dalay     ,
    input   [`MVT_THRESHOLDS_1-1:0]         q_valid                 ,
    input   [`MVT_THRESHOLDS_1-1:0]         latch                   ,

    output  [`MVT_THRESHOLDS_1-1:0][111:0]  dataout                 
);

    genvar i;
    generate
        for(i = 0;i<`MVT_THRESHOLDS_1;i = i+1)begin:ch_latch
            ch_latch               u0(
              .clk_200m            (clk_200m              ),
              .reset_200m          (reset_200m            ),
              .p_lut_q             (p_lut_q[i]            ),
              .n_lut_q             (n_lut_q[i]            ),
              .dataout_p_all_dalay (dataout_p_all_dalay[i]),
              .dataout_n_all_dalay (dataout_n_all_dalay[i]),
              .q_valid             (q_valid[i]            ),
              .latch               (latch[i]              ),
              .dataout             (dataout[i]            )
            );
        end
    endgenerate
endmodule