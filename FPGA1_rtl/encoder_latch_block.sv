`include "./param.v"

module encoder_latch_block
(
  input                               clk_200m        ,
  input                               reset_200m      ,
  input  [15:0]                       coarsecounter   ,
  //input  [`MVT_THRESHOLDS_1-1:0][23:0]  coarsecounter_n ,
  input  [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH_POWER-2:0]   datain_p        ,
  input  [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH_POWER-2:0]   datain_n        ,

  output [`MVT_THRESHOLDS_1-1:0]        dataout_valid_p ,
  output [`MVT_THRESHOLDS_1-1:0][31:0]  dataout_p       ,
  output [`MVT_THRESHOLDS_1-1:0]        dataout_valid_n ,
  output [`MVT_THRESHOLDS_1-1:0][31:0]  dataout_n       
);

  genvar i;
  generate  
    for(i = 0; i < `MVT_THRESHOLDS_1; i = i + 1)
    begin:u0
      encoder_latch_p   positive_edge(
        .clk_200m        (clk_200m          ),
        .reset_200m      (reset_200m        ),
        .coarsecounter   (coarsecounter     ),
        .datain          (datain_p[i]       ),
        .dataout_valid   (dataout_valid_p[i]),
        .dataout         (dataout_p[i]      )
      ); 
    end
  endgenerate
  
  genvar j;
  generate  
    for(j = 0; j < `MVT_THRESHOLDS_1; j = j + 1)
    begin:u1
      encoder_latch_n   negative_edge(
        .clk_200m        (clk_200m          ),
        .reset_200m      (reset_200m        ),
        .coarsecounter   (coarsecounter     ),
        .datain          (datain_n[j]       ),
        .dataout_valid   (dataout_valid_n[j]),
        .dataout         (dataout_n[j]      )
      ); 
    end
  endgenerate
  
endmodule

