`include "./param.v"

module carrychain_cell(
  input                               clk_200m  ,
  input                               reset_200m,
  input                               datain    ,
  
  output reg [`CARRYCHAIN_LENGTH-1:0] dataout
);

  wire [`CARRYCHAIN_LENGTH-1:0] cout    ;
  wire [`CARRYCHAIN_LENGTH-1:0] combout ;

  fiftyfivenm_lcell_comb Cell(
    .dataa     (1'b1      ),
    .datab     (1'b1      ),
    .datac     (1'b1      ),
    .datad     (1'b1      ),
    .cin       (datain    ),
    .combout   (combout[0]),
    .cout      (cout[0]   )
  );
  defparam Cell.sum_lutc_input = "cin";
  defparam Cell.lut_mask = 16'h0F0F;

  genvar i;
  generate
    for(i = 1; i < `CARRYCHAIN_LENGTH; i = i + 1)
    begin:delaychain
      fiftyfivenm_lcell_comb Cell(
        .dataa     (1'b1      ),
        .datab     (1'b1      ),
        .datac     (1'b1      ),
        .datad     (1'b1      ),
        .cin       (cout[i-1] ),
        .combout   (combout[i]),
        .cout      (cout[i]   )
      );
      defparam Cell.sum_lutc_input = "cin";
      defparam Cell.lut_mask = {{(((i+1)%2)*4){1'b0}},4'hF,{((1-((i+1)%2))*4+4){1'b0}},4'hF};
    end
  endgenerate
  
  always@(posedge clk_200m or negedge reset_200m)
  begin
    if(!reset_200m)
      dataout <= 'd0;
    else
      dataout <= combout;
  end
endmodule
