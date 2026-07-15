// -----------------------------------------------------------------------------
// Author       : lib
// Date         : 2026-06-01
// Description  : data fetch with parameterized priority group selection.
//                Flattened v_threshold and ti_sel_out into FIFO.
// -----------------------------------------------------------------------------
`include "./param.v"

module data_fetch #(
    parameter SEL_GROUPS = 4 // >= 2 and <= MVT_THRESHOLDS
)(
    input clk_200m,
    input reset_200m,
    input      [`MVT_THRESHOLDS_1-1:0][111:0] temp_dataout,
    input      temp_dataout_valid,    
    input  [255:0] i_data,
    
    //input      cordic_valid,      

    output     [SEL_GROUPS-1:0] [15:0] v_threshold , 
    output     [2*SEL_GROUPS-1:0][17:0] ti_sel_out,
    output     ti_sel_valid
);

  reg [`MVT_THRESHOLDS_1-1:0] [111:0] data_t;
  integer i,j,k,m;
  reg temp_dataout_valid_d;
  wire temp_dataout_valid_posedge;
  wire [17:0] delta_t;
  
  reg [2*SEL_GROUPS-1:0][17:0] ti_sel_out_temp;
  reg [3:0] sel_g [0:SEL_GROUPS-1];
  wire [15:0] data_segments [0:15];
  reg [2*(`MVT_THRESHOLDS_1)-1:0] [15:0] T;
  reg [2*(`MVT_THRESHOLDS_1)-1:0] [23:0] t1;
  
  wire [2*(`MVT_THRESHOLDS)-1:0][17:0] ti;
  reg [7:0] v_cnt;

  reg  [SEL_GROUPS-1:0] [15:0] v_threshold_int;
  reg  [2*SEL_GROUPS-1:0][17:0] ti_sel_out_int;
  wire ti_sel_valid_int;

  localparam FIFO_WIDTH = (SEL_GROUPS * 16) + (2 * SEL_GROUPS * 18);
  localparam FIFO_DEPTH = 32; 
  
  wire [FIFO_WIDTH-1:0] fifo_data_in;
  wire [FIFO_WIDTH-1:0] fifo_data_out;
  
  wire push_req_n;
  wire pop_req_n;
  wire pop_empty_int;
  wire push_error_int;
  wire pop_error_int;

  wire ti_ready;
  reg  downstream_busy;

  genvar g;
  generate 
    for(g = 0; g < 16; g = g + 1) begin : gen_unpack
	    assign data_segments[g] = i_data[g*16 +: 16];
    end
  endgenerate

  always @(posedge clk_200m or negedge reset_200m) begin
    if (!reset_200m) begin
      v_threshold_int <= 'd0;
    end else begin
	    v_threshold_int[0] <= data_segments[sel_g[0]];
      for (i = 1; i < SEL_GROUPS; i = i + 1) begin
        v_threshold_int[i] <= data_segments[sel_g[SEL_GROUPS-i]];
      end
    end
  end 

  always @ (posedge clk_200m or negedge reset_200m) begin
    if(!reset_200m) begin
      temp_dataout_valid_d <= 'd0;
    end else begin
      temp_dataout_valid_d <= temp_dataout_valid;
    end
  end

  assign temp_dataout_valid_posedge = temp_dataout_valid & ~temp_dataout_valid_d;

  always @ (posedge clk_200m or negedge reset_200m) begin
    if(!reset_200m) begin
      data_t <= 'd0;
    end else if(temp_dataout_valid) begin
      for(i = 0; i < `MVT_THRESHOLDS_1; i = i + 1) begin
        data_t[i] <= temp_dataout[i];
      end
    end else begin
      data_t <= data_t;
    end
  end

  always @ (posedge clk_200m or negedge reset_200m) begin
    if(!reset_200m) begin
      T <= 'd0;
    end else begin
      for(i = 0; i < `MVT_THRESHOLDS_1; i = i + 1) begin
        T[i][15:0] <= data_t[i][111:96];
        T[i+`MVT_THRESHOLDS_1][15:0] <= data_t[`MVT_THRESHOLDS_1-1-i][55:40];
      end
    end
  end

  always @ (posedge clk_200m or negedge reset_200m) begin
    if(!reset_200m) begin
      t1 <= 'd0;
    end else begin
      for(i = 0; i < `MVT_THRESHOLDS_1; i = i + 1) begin
        t1[i][23:0] <= data_t[i][79:56];
        t1[i+`MVT_THRESHOLDS_1][23:0] <= data_t[`MVT_THRESHOLDS_1-1-i][23:0];
      end
    end
  end
  
  ti_cal ti_cal_inst(
    .clk_200m   (clk_200m),
    .reset_200m (reset_200m),
    .T_big      (T),
    .T_little   (t1),
    .t          (ti)	
  );

  always @(*) begin
    for (k = 0; k < SEL_GROUPS; k = k + 1) begin
      sel_g[k] = k[3:0];
    end
    v_cnt = 8'd0;

    for (j = `MVT_THRESHOLDS-1; j >= 1; j = j - 1) begin
      if ((ti[j] != 18'd0) && (ti[2*`MVT_THRESHOLDS-1-j] != 18'd0)) begin
        if (v_cnt < (SEL_GROUPS - 1)) begin
          sel_g[v_cnt + 1] = j[3:0];
          v_cnt = v_cnt + 8'd1;
        end
      end
    end
  end

  always @(posedge clk_200m or negedge reset_200m) begin
    if(!reset_200m) begin
      ti_sel_out_temp <= 'd0;
    end else begin
      ti_sel_out_temp[0] <= ti[0];
      ti_sel_out_temp[2*SEL_GROUPS-1] <= ti[2*`MVT_THRESHOLDS-1];

      for (k = 1; k < SEL_GROUPS; k = k + 1) begin
        ti_sel_out_temp[k]   <= ti[sel_g[SEL_GROUPS-k]];
        ti_sel_out_temp[2*SEL_GROUPS-1-k] <= ti[2*`MVT_THRESHOLDS-1-sel_g[SEL_GROUPS-k]];
      end
    end
  end

  assign delta_t = ti_sel_out_temp[SEL_GROUPS][17:0] - ti_sel_out_temp[0][17:0];

  always @(*) begin
    for (m = 0; m < 2*SEL_GROUPS; m = m + 1) begin
      ti_sel_out_int[m] = ti_sel_out_temp[m] + delta_t;
    end
  end
   
  pipe_stage #(
    .DATA_WIDTH(1),
    .STAGES (5),
    .RESET_VALUE (0)
  ) pipe_stage_sel_inst (
    .i_clk        (clk_200m),
    .i_rst_n      (reset_200m),
    .i_data       (temp_dataout_valid_posedge),
    .o_data       (ti_sel_valid_int)
  );

  // ---------------------------------------------------------------------------
  // Flatten signals 
  // ---------------------------------------------------------------------------

  assign {v_threshold, ti_sel_out} = {v_threshold_int, ti_sel_out_int};
  assign ti_sel_valid = ti_sel_valid_int;

endmodule
