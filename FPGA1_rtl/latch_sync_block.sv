`include "./param.v"
module  latch_sync_block(
    input                                     clk_200m              ,
    input                                     reset_200m            ,
    input       [`MVT_THRESHOLDS_1-1:0]         dataout_valid_p       ,
    input       [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_p             ,
    input       [`MVT_THRESHOLDS_1-1:0]         dataout_valid_n       ,
    input       [`MVT_THRESHOLDS_1-1:0][31:0]   dataout_n             ,

    output  reg [`MVT_THRESHOLDS_1-1:0]         sync_dataout_valid_p  ,
    output  reg [`MVT_THRESHOLDS_1-1:0][31:0]   sync_dataout_p        ,
    output  reg [`MVT_THRESHOLDS_1-1:0]         sync_dataout_valid_n  ,
    output  reg [`MVT_THRESHOLDS_1-1:0][31:0]   sync_dataout_n        
);

    genvar i;
    generate
      for(i=0;i<`MVT_THRESHOLDS_1;i=i+1)begin:u2
        latch_sync            u0(
          .clk_200m            (clk_200m               ),
          .reset_200m          (reset_200m             ),
          .dataout_valid_p     (dataout_valid_p[i]     ),
          .dataout_p           (dataout_p[i]           ),
          .dataout_valid_n     (dataout_valid_n[i]     ),
          .dataout_n           (dataout_n[i]           ),
          .sync_dataout_valid_p(sync_dataout_valid_p[i]),
          .sync_dataout_p      (sync_dataout_p[i]      ),
          .sync_dataout_valid_n(sync_dataout_valid_n[i]),
          .sync_dataout_n      (sync_dataout_n[i]      )
        );
      end
    endgenerate
endmodule