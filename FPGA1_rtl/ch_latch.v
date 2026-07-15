module ch_latch(
    input           clk_200m                ,
    input           reset_200m              ,
    input   [23:0]  p_lut_q                 ,
    input   [23:0]  n_lut_q                 ,
    input   [31:0]  dataout_p_all_dalay     ,
    input   [31:0]  dataout_n_all_dalay     ,
    input           q_valid                 ,
    input           latch                   ,
    
    output  [111:0] dataout                 
);
    reg [111:0] dataout_reg;
    assign dataout = dataout_reg;
    always@(posedge clk_200m or negedge reset_200m)begin
      if(!reset_200m)begin
        dataout_reg <= 112'd0;
      end else begin
        if(q_valid)begin
          dataout_reg   <= {dataout_p_all_dalay,p_lut_q,dataout_n_all_dalay,n_lut_q};
        end else begin
          if(!latch)
            dataout_reg <= dataout;
          else
            dataout_reg <= 112'd0;
        end
      end
    end
endmodule