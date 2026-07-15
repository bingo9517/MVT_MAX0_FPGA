
module ln_ti_ln_vi_cal #(
    parameter NUM_INSTANCES = 16
)(
    input clk_200m,
    input reset_200m,
    input data_en,
 
    input [NUM_INSTANCES*2-1:0][17:0] ti,
    input [NUM_INSTANCES-1:0][15:0]   vi,

    output reg [NUM_INSTANCES*2-1:0][27:0] ln_vi,
    output reg valid,
    output reg signed [NUM_INSTANCES*2-1:0][27:0] ln_ti
);
  wire [NUM_INSTANCES-1:0] valid_vi_o;
  wire [NUM_INSTANCES*2-1:0] valid_ti_o;
  wire [NUM_INSTANCES*2-1:0][27:0] ln_vi_w;
  wire signed [NUM_INSTANCES*2-1:0][27:0] ln_ti_w;
  wire valid_w;

  genvar i;
  generate
    for (i = 0; i < NUM_INSTANCES; i = i + 1) begin : cal_lnvi
      cal_ln_q16_0 cal_ln_inst (
        .clk(clk_200m),
        .rst_n(reset_200m),
        .a(vi[i]),
        .valid_i(data_en),
        .ln_value(ln_vi_w[i]),
        .valid_o(valid_vi_o[i])
      );
    end
  endgenerate
 
  genvar j;
  generate
    for (j = 0; j < 2*NUM_INSTANCES; j = j + 1) begin : cal_lnti
      cal_ln_q10_8 cal_ln_inst (
        .clk(clk_200m),
        .rst_n(reset_200m),
        .a(ti[j]),
        .valid_i(data_en),
        .ln_value(ln_ti_w[j]),
        .valid_o(valid_ti_o[j])
      );
    end
  endgenerate

  genvar k;
  generate
    for(k=0; k < NUM_INSTANCES; k = k + 1) begin: gen_ln_vi_mirror
        assign ln_vi_w[NUM_INSTANCES + k] = ln_vi_w[NUM_INSTANCES - 1 - k];
    end
  endgenerate
  
  integer m;
  
  always @(posedge clk_200m or negedge reset_200m)begin
  	if(!reset_200m) begin
  		ln_vi <= 'd0;
  		valid <= 'd0;
  		ln_ti <= 'd0;
  	end
  	else begin
  		for (m = 0; m <2*NUM_INSTANCES; m = m+ 1 ) begin
  			ln_vi[m] <= ln_vi_w[m];
  			ln_ti[m] <= ln_ti_w[m];
  		end
  		valid <= valid_w;
  	
  	end
  end

  assign valid_w = (&valid_ti_o) && (&valid_vi_o);

endmodule
