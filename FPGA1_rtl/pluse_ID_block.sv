`include "./param.v"
module pluse_ID_block(
    input                                 clk_200m                ,
    input                                 reset_200m              ,
    input   [`MVT_THRESHOLDS_1-1:0][23:0]   p_lut_q                 ,
    input   [`MVT_THRESHOLDS_1-1:0][23:0]   n_lut_q                 ,
    input   [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_p_all_dalay     ,
    input   [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_n_all_dalay     ,
    input   [`MVT_THRESHOLDS_1-1:0]         q_valid                 ,

    output  [`MVT_THRESHOLDS_1-1:0][111:0]  dataout                 ,
    output                                mvt_event_valid         
);

    wire  [`MVT_THRESHOLDS_1-1:0]           latch                   ;

    pluse_ID          u0(
      .clk_200m       (clk_200m       ),
      .reset_200m     (reset_200m     ),
      .q_valid        (q_valid        ),
      .latch          (latch          ),
      .mvt_event_valid(mvt_event_valid)
    );
    
    ch_latch_block        u1(
      .clk_200m           (clk_200m           ),
      .reset_200m         (reset_200m         ),
      .p_lut_q            (p_lut_q            ),
      .n_lut_q            (n_lut_q            ),
      .dataout_p_all_dalay(dataout_p_all_dalay),
      .dataout_n_all_dalay(dataout_n_all_dalay),
      .q_valid            (q_valid            ),
      .latch              (latch              ),
      .dataout            (dataout            )
    );
endmodule