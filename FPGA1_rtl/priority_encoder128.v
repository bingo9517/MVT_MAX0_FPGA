module priority_encoder128
#(
  parameter PRIORITY_BIT  = 0,
  parameter PRIORITY_DATA = 0,
  parameter INPUT_WIDTH   = 128,
  parameter OUTPUT_WIDTH  = 8
)
(
  input                         clk_200m,
  input                         reset_200m,
  input      [INPUT_WIDTH-1:0]  datain,
  
  output reg [OUTPUT_WIDTH-1:0] dataout
);

  wire  [OUTPUT_WIDTH-2:0] data_h;
  wire  [OUTPUT_WIDTH-2:0] data_l;
  wire  [OUTPUT_WIDTH-1:0] dataout_temp;
  
  priority_encoder64   
    #(
      .PRIORITY_BIT    (PRIORITY_BIT),
      .PRIORITY_DATA   (PRIORITY_DATA)
    )
    high_64_bit(
      .clk_200m        (clk_200m),
      .reset_200m      (reset_200m),
      .datain          (datain[INPUT_WIDTH-1:INPUT_WIDTH/2]),
      .dataout         (data_h)
    ); 
    
  priority_encoder64
    #(
      .PRIORITY_BIT    (PRIORITY_BIT),
      .PRIORITY_DATA   (PRIORITY_DATA)
    )
    low_64_bit(
      .clk_200m        (clk_200m),
      .reset_200m      (reset_200m),
      .datain          (datain[INPUT_WIDTH/2-1:0]),
      .dataout         (data_l)
    ); 

  generate
    if(PRIORITY_BIT == 0)
      assign dataout_temp = data_l[OUTPUT_WIDTH-2] ? (data_h + 8'd64) : {1'd0,data_l};
    else
      assign dataout_temp = data_h[OUTPUT_WIDTH-2] ? (data_l + 8'd64) : {1'd0,data_h};
  endgenerate
  
  always@(posedge clk_200m or negedge reset_200m)
  begin
    if(!reset_200m)
      dataout <= 'd0;
    else
      dataout <= dataout_temp;
  end 
endmodule
