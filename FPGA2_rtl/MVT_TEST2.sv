`include "param.v"
module MVT_TEST2(
    input          clk_40m_max10,

    input [17:0]    fifo_data,
    input           fifo_data_valid,
    input           rx_clk_in,

    output          o_spi_sck,
    output          o_spi_cso,
    output          o_spi_mosi,

    output          tx_pin_data,
    output          DE
  );
   
    wire                                clk_50m               ;
    wire                                clk_200m              ;
    wire                                clk_10m               ;
    wire                                reset_50m             ;
    wire                                reset_200m            ;
    wire                                reset_10m             ;


    wire                                ti_raw_valid          ;
  	wire	[2*(`MVT_CHANNEL)-1:0][17:0]	ti_raw                ;			          

    wire  [`MVT_CHANNEL-1:0][15:0]      v_threshold           ;

    wire  [31:0]                        cordic_result         ;
    wire                                cordic_valid          ;
    wire                                tx_done               ;
    wire  [2*(`MVT_CHANNEL)-1:0] [17:0] ti_opt					      ;
    wire           				              ti_opt_valid				  ;
    wire signed[31:0] 					      	final_a				        ;
    wire signed[31:0] 					      	final_b					      ;
    wire signed[31:0] 					      	final_c					      ;
    wire              					      	final_a_valid		    	;
    wire              					      	final_b_valid		    	;
    wire              					      	final_c_valid		    	;
    wire 								                ln_v_max_valid				;
    wire signed [31:0] 						      ln_v_max			      	;


    assign DE = 1'b1;
    
    clock_control_block  clock_control_block_inst(
      .clk_40m_max10    (clk_40m_max10),
      .clk_50m          (clk_50m),
      .clk_200m         (clk_200m),
      .clk_10m          (clk_10m)
    );
    
    reset_control_block   reset_control_block_inst(
      .clk_200m           (clk_200m),
      .reset_50m          (reset_50m),
      .reset_200m         (reset_200m),
      .reset_10m          (reset_10m)
    );


    fifo_rx fifo_rx_inst(
      .clk            (clk_200m),
  	  .reset          (reset_200m),
  	  .rx_clk_in      (rx_clk_in),
      .fifo_data_valid(fifo_data_valid),
      .data_in        (fifo_data),
      .cordic_valid   (cordic_valid),
      .ti             (ti_raw),
      .ti_valid       (ti_raw_valid),
      .v_threshold    (v_threshold)
    );

    dac_block     dac_block_inst(
      .clk        (clk_10m    ),
      .reset      (reset_10m  ),
      .o_spi_sck  (o_spi_sck  ),
      .o_spi_cso  (o_spi_cso  ),
      .o_spi_mosi (o_spi_mosi )
    );    


  ti_optimization_ctrl #(
      .ITER_NUM(6)
  ) ti_optimization_ctrl_inst (
      .clk_200m       		(clk_200m),
      .reset_200m     		(reset_200m),
      .ti_in          		(ti_raw),
      .ti_valid_in    		(ti_raw_valid),
      .v_threshold    		(v_threshold),
      .ti_out         		(ti_opt),
      .ti_valid_out   		(ti_opt_valid),
      .final_a        		(final_a),
      .final_b        		(final_b),
      .final_c        		(final_c),
      .final_a_valid  		(final_a_valid),
      .final_b_valid  		(final_b_valid),
      .final_c_valid  		(final_c_valid)
  );


  energy_cal energy_cal_inst(
	 .clk_200m              (clk_200m),
	 .reset_200m            (reset_200m),
	 .a                     (final_a),
	 .b                     (final_b),
	 .c                     (final_c),
	 .a_valid               (final_a_valid),
	 .b_valid               (final_b_valid),
	 .c_valid               (final_c_valid),
	 .ln_v_max              (ln_v_max),
	 .o_valid               (ln_v_max_valid)
  );

  exp_cordic_pipeline exp_cordic_pipeline_inst(
    .clk                  (clk_200m), 
    .rst_n                (reset_200m), 
    .valid_in             (ln_v_max_valid), 
    .x_in                 (ln_v_max),
    .valid_out            (cordic_valid), 
    .result_out           (cordic_result)
  ); 

  cordic_uart_bridge cordic_uart_bridge_inst(
    .clk_200m       (clk_200m),
    .reset_200m     (reset_200m),
    .clk_10m        (clk_10m),
    .reset_10m      (reset_10m),
    .cordic_valid   (cordic_valid),
    .cordic_result  (cordic_result),
    .tx_pin_data    (tx_pin_data),
    .tx_done        (tx_done)
  );

 
 
endmodule
