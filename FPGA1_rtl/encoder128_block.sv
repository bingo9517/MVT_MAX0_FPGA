`include "./param.v"

module encoder128_block
#(
    parameter INPUT_WIDTH  = 128,
    parameter OUTPUT_WIDTH = 8
)
(
    input                                           clk_200m    ,
    input                                           reset_200m  ,
    input  [`MVT_THRESHOLDS_1-1:0][INPUT_WIDTH-1:0]   datain    ,
    // input  [`MVT_THRESHOLDS_1-1:0][INPUT_WIDTH-1:0]   datain_n    ,
  
    output [`MVT_THRESHOLDS_1-1:0][OUTPUT_WIDTH-2:0]  dataout_p   ,
    output [`MVT_THRESHOLDS_1-1:0][OUTPUT_WIDTH-2:0]  dataout_n   
);

    wire  [`MVT_THRESHOLDS_1-1:0][OUTPUT_WIDTH-1:0]  t_dataout_p;
    wire  [`MVT_THRESHOLDS_1-1:0][OUTPUT_WIDTH-1:0]  t_dataout_n;

  genvar i;
  generate
    for(i = 0; i < `MVT_THRESHOLDS_1; i = i + 1)
    begin:encoder_p
      priority_encoder128
      #(
        .PRIORITY_BIT    (0),
        .PRIORITY_DATA   (0)
      )
      positive_edge(
        .clk_200m        (clk_200m      ),
        .reset_200m      (reset_200m    ),
        .datain          (datain[i]     ),
        .dataout         (t_dataout_p[i])
      );
      assign dataout_p[i] = t_dataout_p[i][OUTPUT_WIDTH-2:0];
    end
  endgenerate
  
  genvar j;
  generate
    for(j = 0; j < `MVT_THRESHOLDS_1; j = j + 1)
    begin:encoder_n
      priority_encoder128
      #(
        .PRIORITY_BIT    (0),
        .PRIORITY_DATA   (1)
      )
      negative_edge(
        .clk_200m        (clk_200m      ),
        .reset_200m      (reset_200m    ),
        .datain          (datain[j]     ),
        .dataout         (t_dataout_n[j])
      ); 
      assign dataout_n[j] = t_dataout_n[j][OUTPUT_WIDTH-2:0];
    end
  endgenerate
endmodule
