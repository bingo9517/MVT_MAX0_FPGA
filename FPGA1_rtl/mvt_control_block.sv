`include "./param.v"
module mvt_control_block
(
    input                                 clk_200m            ,
    input                                 reset_200m          ,
    //input                                 start               ,
	
    input                                 Select_S            ,
    input                                 calibration_S       ,
    input   [`MVT_THRESHOLDS_1-1:0]         r_Signal            ,

    output  [`MVT_THRESHOLDS_1-1:0][111:0]  dataout             ,
    output                                mvt_event_valid     
);

    wire                         [15:0] coarsecounter       ;
	
    wire    [`MVT_THRESHOLDS_1-1:0]       mvt_datain          ;
    wire    [`MVT_THRESHOLDS_1-1:0]       MUX_S               ;
    wire    [`MVT_THRESHOLDS_1-1:0]       lut_finish          ;
    wire    [`MVT_THRESHOLDS_1-1:0][31:0] sync_dataout_p      ;
    wire    [`MVT_THRESHOLDS_1-1:0]       sync_dataout_valid_p;
    wire    [`MVT_THRESHOLDS_1-1:0][31:0] sync_dataout_n      ;
    wire    [`MVT_THRESHOLDS_1-1:0]       sync_dataout_valid_n;
    wire    [`MVT_THRESHOLDS_1-1:0][23:0] p_lut_q            ;
    wire    [`MVT_THRESHOLDS_1-1:0][23:0] n_lut_q            ;
    wire    [`MVT_THRESHOLDS_1-1:0][31:0] dataout_p_all_dalay;
    wire    [`MVT_THRESHOLDS_1-1:0][31:0] dataout_n_all_dalay;
    wire    [`MVT_THRESHOLDS_1-1:0]       q_valid            ;
    
    Select_signal_block u0(
      .clk_200m         (clk_200m         ),
      .reset_200m       (reset_200m       ),
      .Select_S         (Select_S         ),
      .calibration_S    (calibration_S    ),
      .r_Signal         (r_Signal         ),
      .lut_finish       (lut_finish[0]    ),
      .MUX_S            (MUX_S            ),
      .mvt_datain       (mvt_datain       ) 
    );

/*     Coarse_counter3     u1(
      .clock           (clk_200m      ),
      .q               (coarsecounter )
    ); */
	
	// mvt_event_valid negedge
	/* reg mvt_valid_reg;
	wire valid;
    always @(posedge clk_200m or negedge reset_200m) begin
        if (!reset_200m) begin
            mvt_valid_reg   <= 'd0;
		end
		else begin
			mvt_valid_reg <= mvt_event_valid;
		end
	end
	
	
	assign valid = ~mvt_event_valid && mvt_valid_reg; */
	
    Coarse_counter3     u1(
	.clk(clk_200m),
	.rst_n(reset_200m),
	.start(mvt_event_valid),
	//.valid(valid),
	.counter(coarsecounter)
    );	

    mvt_process             u2(
      .clk_200m             (clk_200m            ),
      .reset_200m           (reset_200m          ),
      .coarsecounter        (coarsecounter       ),
      .datain               (mvt_datain          ),
      .sync_dataout_valid_p (sync_dataout_valid_p),
      .sync_dataout_p       (sync_dataout_p      ),
      .sync_dataout_valid_n (sync_dataout_valid_n),
      .sync_dataout_n       (sync_dataout_n      )
    );
    genvar i;
    generate
        for(i = 0;i<`MVT_THRESHOLDS_1;i = i+1)begin:ram_control_block
            ram_control_block         u3(
              .clk_200m               (clk_200m                 ),
              .reset_200m             (reset_200m               ),
              .dataout_valid_p        (sync_dataout_valid_p[i]  ),
              .dataout_p_fine         (sync_dataout_p[i][`TDC_LENGTH_POWER-2:0]   ),
              .dataout_p_all          (sync_dataout_p[i]        ),
              .dataout_valid_n        (sync_dataout_valid_n[i]  ),
              .dataout_n_fine         (sync_dataout_n[i][`TDC_LENGTH_POWER-2:0]   ),
              .dataout_n_all          (sync_dataout_n[i]        ),
              .Select_S               (Select_S                 ),
              .MUX_S                  (MUX_S[i]                 ),
              .lut_finish_ram1        (lut_finish[i]            ),
              .p_lut_q                (p_lut_q[i]               ),
              .n_lut_q                (n_lut_q[i]               ),
              .dataout_p_all_dalay    (dataout_p_all_dalay[i]   ),
              .dataout_n_all_dalay    (dataout_n_all_dalay[i]   ),
              .q_valid                (q_valid[i]               )
            );
        end
    endgenerate
    
    pluse_ID_block          u4(
      .clk_200m             (clk_200m           ),
      .reset_200m           (reset_200m         ),
      .p_lut_q              (p_lut_q            ),
      .n_lut_q              (n_lut_q            ),
      .dataout_p_all_dalay  (dataout_p_all_dalay),
      .dataout_n_all_dalay  (dataout_n_all_dalay),
      .q_valid              (q_valid            ),
      .dataout              (dataout            ),
      .mvt_event_valid      (mvt_event_valid    )
    );


endmodule
