`include "./param.v"
module mvt_process
(
    input                                   clk_200m              ,
    input                                   reset_200m            ,
    input                        [15:0]     coarsecounter         ,
    input   [`MVT_THRESHOLDS_1-1:0]           datain                ,

    output  [`MVT_THRESHOLDS_1-1:0]           sync_dataout_valid_p  ,
    output  [`MVT_THRESHOLDS_1-1:0][31:0]     sync_dataout_p        ,
    output  [`MVT_THRESHOLDS_1-1:0]           sync_dataout_valid_n  ,
    output  [`MVT_THRESHOLDS_1-1:0][31:0]     sync_dataout_n        
);

    wire [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH-1:0] carrychain_block_dataout ;
    // wire [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH-1:0] tdc_filter_dataout_p ;
    // wire [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH-1:0] tdc_filter_dataout_n ;
    carrychain_block   u0(
      .clk_200m     (clk_200m                 ),
      .reset_200m   (reset_200m               ),
      .datain       (datain                   ),
      .dataout      (carrychain_block_dataout )
    );
    
    // tdc_filter_block  u_tdc_filter_block(
    //   .clk_200m       (clk_200m                  ),
    //   .reset_200m     (reset_200m                ),
    //   .datain         (carrychain_block_dataout  ),
    //   .dataout_p      (tdc_filter_dataout_p      ),
    //   .dataout_n      (tdc_filter_dataout_n      )
    // );
    
    wire [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH_POWER-2:0] encoder256_block_dataout_p;
    wire [`MVT_THRESHOLDS_1-1:0][`TDC_LENGTH_POWER-2:0] encoder256_block_dataout_n;

    `ifdef TDC_LENGTH_1024
        encoder1024_block  #(
          .INPUT_WIDTH    (`TDC_LENGTH),
          .OUTPUT_WIDTH   (`TDC_LENGTH_POWER)
        ) u1(
          .clk_200m       (clk_200m                  ),
          .reset_200m     (reset_200m                ),
          .datain       (carrychain_block_dataout   ),
          // .datain_n       (tdc_filter_dataout_n       ),
          .dataout_p      (encoder256_block_dataout_p ),
          .dataout_n      (encoder256_block_dataout_n )
        );
    `elsif TDC_LENGTH_512
        encoder512_block  #(
          .INPUT_WIDTH    (`TDC_LENGTH),
          .OUTPUT_WIDTH   (`TDC_LENGTH_POWER)
        ) u1(
          .clk_200m       (clk_200m                  ),
          .reset_200m     (reset_200m                ),
          .datain       (carrychain_block_dataout   ),
          // .datain_n       (tdc_filter_dataout_n       ),
          .dataout_p      (encoder256_block_dataout_p ),
          .dataout_n      (encoder256_block_dataout_n )
        );

    `elsif TDC_LENGTH_256
        encoder256_block  #(
          .INPUT_WIDTH    (`TDC_LENGTH),
          .OUTPUT_WIDTH   (`TDC_LENGTH_POWER)
        ) u1(
          .clk_200m       (clk_200m                  ),
          .reset_200m     (reset_200m                ),
          .datain       (carrychain_block_dataout   ),
          // .datain_n       (tdc_filter_dataout_n       ),
          .dataout_p      (encoder256_block_dataout_p ),
          .dataout_n      (encoder256_block_dataout_n )
        );
     `elsif TDC_LENGTH_128
        encoder128_block  #(
          .INPUT_WIDTH    (`TDC_LENGTH),
          .OUTPUT_WIDTH   (`TDC_LENGTH_POWER)
        ) u1(
          .clk_200m       (clk_200m                  ),
          .reset_200m     (reset_200m                ),
          .datain       (carrychain_block_dataout   ),
          // .datain_n       (tdc_filter_dataout_n       ),
          .dataout_p      (encoder256_block_dataout_p ),
          .dataout_n      (encoder256_block_dataout_n )
        );
    `elsif TDC_LENGTH_64
        encoder64_block  #(
          .INPUT_WIDTH    (`TDC_LENGTH),
          .OUTPUT_WIDTH   (`TDC_LENGTH_POWER)
        ) u1(
          .clk_200m       (clk_200m                  ),
          .reset_200m     (reset_200m                ),
          .datain       (carrychain_block_dataout   ),
          // .datain_n       (tdc_filter_dataout_n       ),
          .dataout_p      (encoder256_block_dataout_p ),
          .dataout_n      (encoder256_block_dataout_n )
        );
    `endif
    

    wire [`MVT_THRESHOLDS_1-1:0]          encoder_latch_block_dataout_valid_p ;
    wire [`MVT_THRESHOLDS_1-1:0]          encoder_latch_block_dataout_valid_n ;
    wire [`MVT_THRESHOLDS_1-1:0][31:0]    encoder_latch_block_dataout_p       ;
    wire [`MVT_THRESHOLDS_1-1:0][31:0]    encoder_latch_block_dataout_n       ;
    // wire [`MVT_THRESHOLDS_1-1:0][23:0]    coarsecounter_p                     ;
    // wire [`MVT_THRESHOLDS_1-1:0][23:0]    coarsecounter_n                     ;

    // coarsecounter_latch u_coarsecounter_latch(
    //   .clk_200m       (clk_200m          ),
    //   .reset_200m     (reset_200m        ),
    //   .datain         (datain            ),
    //   .coarsecounter  (coarsecounter     ),
    //   .coarsecounter_p(coarsecounter_p   ),
    //   .coarsecounter_n(coarsecounter_n   )
    // );
    
    encoder_latch_block   u2(
      .clk_200m           (clk_200m                           ),
      .reset_200m         (reset_200m                         ),
      .coarsecounter      (coarsecounter                      ),
      //.coarsecounter_n    (coarsecounter_n                    ),
      .datain_p           (encoder256_block_dataout_p         ),
      .datain_n           (encoder256_block_dataout_n         ),
      .dataout_valid_p    (encoder_latch_block_dataout_valid_p),
      .dataout_valid_n    (encoder_latch_block_dataout_valid_n),
      .dataout_p          (encoder_latch_block_dataout_p      ),
      .dataout_n          (encoder_latch_block_dataout_n      )
    );
    
    latch_sync_block        u3(
      .clk_200m             (clk_200m                           ),
      .reset_200m           (reset_200m                         ),
      .dataout_valid_p      (encoder_latch_block_dataout_valid_p),
      .dataout_p            (encoder_latch_block_dataout_p      ),
      .dataout_valid_n      (encoder_latch_block_dataout_valid_n),
      .dataout_n            (encoder_latch_block_dataout_n      ),
      .sync_dataout_valid_p (sync_dataout_valid_p               ),
      .sync_dataout_p       (sync_dataout_p                     ),
      .sync_dataout_valid_n (sync_dataout_valid_n               ),
      .sync_dataout_n       (sync_dataout_n                     )
    );

endmodule
