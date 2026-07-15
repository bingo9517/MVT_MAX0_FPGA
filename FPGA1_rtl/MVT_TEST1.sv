`include "param.v"
module MVT_TEST1(
    input                         clk_40m_max10         ,
    input   [`MVT_THRESHOLDS_1-1:0] r_Signal            ,

    output [17:0]               fifo_rdata              ,
    output                      fifo_data_valid         ,
    output                      tx_clk_out
  );
   
    wire                                clk_50m               ;
    wire                                clk_200m              ;
    wire                                clk_10m               ;
    wire                                reset_50m             ;
    wire                                reset_200m            ;
    wire                                reset_10m             ;
    wire                                Tosc                  ;
    wire                                Select_S              ;
    
    wire  [`MVT_THRESHOLDS_1-1:0][111:0]  dataout               ;
    wire                                mvt_event_valid       ;
    wire  [`MVT_CHANNEL-1:0][15:0]      v_threshold         ;
    wire                                ti_raw_valid      ;
    wire [2*(`MVT_CHANNEL)-1:0][17:0]   ti_raw            ;
  

    clock_control_block  u1(
      .clk_40m_max10    (clk_40m_max10),
      .clk_50m          (clk_50m),
      .clk_200m         (clk_200m),
      .clk_10m          (clk_10m)
    );
    
    reset_control_block   u2(
      .clk_200m           (clk_200m),
      .reset_50m          (reset_50m),
      .reset_200m         (reset_200m),
      .reset_10m          (reset_10m)
    );
    
    TEMP                  u4(
      .clk_200m           (clk_200m           ),
      .reset_200m         (reset_200m         ),
      .Tosc               (Tosc               ),
      .Select_S           (Select_S           )
    );

    mvt_control_block         u3(
      .clk_200m               (clk_200m                 ),
      .reset_200m             (reset_200m               ),
      .Select_S               (Select_S                 ),
      .calibration_S          (Tosc                     ),
      .r_Signal               (r_Signal                 ),
      .dataout                (dataout                  ),
      .mvt_event_valid        (mvt_event_valid          )
    );


    // fetch raw ti
    data_fetch 	#(
	    .SEL_GROUPS(`MVT_CHANNEL)
    )	data_fetch_inst(
      .clk_200m             	(clk_200m),
      .reset_200m           	(reset_200m),
      .temp_dataout         	(dataout),
      .temp_dataout_valid   	(mvt_event_valid),   
	    .i_data			            ({32'h0, 32'h0, 32'h0, 32'h0, 32'h05DC_0578, 32'h0514_04B0, 32'h02BC_0258, 32'h01F4_0190}),
	    .v_threshold          	(v_threshold),
      .ti_sel_out             (ti_raw),
      .ti_sel_valid           (ti_raw_valid)
    );
    
  wire temp_dataout_valid_posedge;
  reg temp_dataout_valid_d;
  
  always @ (posedge clk_200m or negedge reset_200m)
  begin
    if(!reset_200m)
    begin
      temp_dataout_valid_d <= 'd0;
    end
    else 
    begin
      temp_dataout_valid_d <= mvt_event_valid;
    end
  end

  assign temp_dataout_valid_posedge = mvt_event_valid & ~temp_dataout_valid_d;

  reorder_and_fifo_buffer reorder_inst (
    .clk_200m       (clk_200m),
    .reset_200m     (reset_200m),
    .rd_clk         (clk_50m),

    .packet_start   (temp_dataout_valid_posedge), 
    .ti_in          (ti_raw),
    .ti_valid       (ti_raw_valid),

    .vth_in         (v_threshold),
    .fifo_rdata     (fifo_rdata),
    .fifo_data_valid(fifo_data_valid),
    .tx_clk_out     (tx_clk_out)
  );
     
    

endmodule
