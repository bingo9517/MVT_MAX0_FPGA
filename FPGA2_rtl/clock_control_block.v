module clock_control_block
(
  input  clk_40m_max10,
  
  output clk_50m,
  output clk_200m,
  output clk_10m
  //output clk_1m
);
  
  // pll         u0(
  //   .inclk0   (clk_40m_max10),
  //   .c0       (clk_50m),
  //   .c1       (clk_200m),
  //   .c2       (clk_10m),
  //   .locked   (pll_locked)
  // );
    reg [5:0] count_1m = 6'd0;     
    reg ce_1m = 1'b0;              
    reg [3:0] count = 4'd0;
    reg ce_10m = 1'b0;
    reg ce_50m = 1'b0;

    assign clk_200m = clk_40m_max10;
    assign clk_10m = ce_10m;
    assign clk_50m = ce_50m;
    //assign clk_1m = ce_1m;

    always @(posedge clk_40m_max10) begin
        ce_50m <= ~ce_50m;
    end    
   
    always @(posedge clk_40m_max10) begin
        if (count == 4'd9) begin
            count  <= 4'd0;
        end else begin
            count  <= count + 4'd1;
        end
    end

    always @(posedge clk_40m_max10) begin
        if (count == 4'd4) begin
             ce_10m <= 1'b1;
        end else if (count == 4'd9) begin
             ce_10m <= 1'b0;
        end
    end


    always @(posedge clk_40m_max10) begin
        if (count_1m == 6'd49) begin
            count_1m <= 6'd0;
            ce_1m <= ~ce_1m;
        end else begin
            count_1m <= count_1m + 6'd1;
        end
    end

endmodule

