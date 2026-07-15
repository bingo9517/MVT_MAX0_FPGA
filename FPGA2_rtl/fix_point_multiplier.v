
module fix_point_multiplier (
  input            clock    ,
  input            aclr,
  input  [31 :0]   dataa  ,
  input  [31 :0]   datab  ,
  output [63 :0]   result 
);

//DW02_mult_2_stage_inst #(.A_width(32), .B_width(32))
DW02_mult_2_stage_inst 
U1 ( .inst_A(dataa),
.inst_B(datab),
.inst_TC(1'b1),
.inst_CLK(clock),
.PRODUCT_inst(result) 
);


endmodule

