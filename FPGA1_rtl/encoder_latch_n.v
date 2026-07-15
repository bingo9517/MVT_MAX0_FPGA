`include "./param.v"
module encoder_latch_n(
  input             clk_200m        ,
  input             reset_200m      ,
  input  [15:0]     coarsecounter   ,
  input  [`TDC_LENGTH_POWER-2:0]      datain          ,
  
  output reg        dataout_valid   ,
  output reg [31:0] dataout         
);

  always@(posedge clk_200m or negedge reset_200m)begin
    if(!reset_200m)begin
      dataout_valid <= 'd0;
      dataout       <= 'd0;
    end else begin
      dataout_valid <= ((datain == 'd0) || (datain ==`CARRYCHAIN_LENGTH)) ? 1'b0 : 1'b1;
      dataout       <= {coarsecounter,{17-`TDC_LENGTH_POWER{1'b0}},datain};
    end
  end
endmodule