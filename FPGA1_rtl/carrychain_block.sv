`include "./param.v"

module carrychain_block(
    input                                         clk_200m    ,
    input                                         reset_200m  ,
    input  [`MVT_THRESHOLDS_1-1:0]                  datain      ,
    
    output [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH-1:0] dataout     
);

  genvar i;
  generate
    for(i = 0; i < `MVT_THRESHOLDS_1; i = i +1)begin:u0
        carrychain_cell u0(
          .clk_200m     (clk_200m     ),
          .reset_200m   (reset_200m   ),
          .datain       (datain[i]    ),
          .dataout      (dataout[i]   )
        );
  end
  endgenerate
endmodule
  