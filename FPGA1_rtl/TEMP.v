`include "./param.v"
module TEMP(
  input     clk_200m            ,
  input     reset_200m          ,
  //input     clk_10m             ,
  //input     reset_10m           ,
  //input     rx_pin_in           ,
            
  //output    AcqRstSignal        ,
  output    Tosc                ,
  output    Select_S      
);

 // wire  [7:0]   rx_data     ;
//  wire          rx_done     ;
  wire          START       ;
  wire  [15:0]  Dout        ;
  wire          Dout_valid  ;
  wire          next_start;


  /*
  Uart_rx_top     u1(
    .clk_10m      (clk_10m    ),
    .rst_n        (reset_10m  ),
    .rx_pin_in    (rx_pin_in  ),
    .rx_data      (rx_data    ),
    .rx_done      (rx_done    )
  );
  */
  
  
  generate_start  u_generate_start(
    .clk_200m     (clk_200m     ),
    .reset_200m   (reset_200m   ),
//    .rx_data      (rx_data      ),
 //   .rx_done      (rx_done      ),
    .next_start   (next_start   ),
    .START        (   START     )
//    .AcqRstSignal (AcqRstSignal )
  );

  retriggerable_ring_oscillator   u_ring_osc(
    .clk_200m                     (clk_200m     ),
    .reset_200m                   (reset_200m   ),
    .Tosc                         (Tosc		)
  );

  VGTA #(
      .N (16'd2048)
  ) u_VGTA (
    .Tosc               (Tosc               ),
    .clk_200m           (clk_200m           ),
    .reset_200m         (reset_200m         ),
    .START              (START              ),
    .next_start         (next_start         ),
    .Dout               (Dout               ),
    .Dout_valid         (Dout_valid         )
  );
  
  tempchange #(
      .THRESHOLD (16'sd200)
  ) u_tempchange (
    .clk_200m    (clk_200m      ),
    .reset_200m  (reset_200m    ),
    .Dout        (Dout          ),
    .Dout_valid  (Dout_valid    ),
    .Select_S    (Select_S      )
  );

endmodule
