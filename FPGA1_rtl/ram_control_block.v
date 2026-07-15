`include "./param.v"

module ram_control_block(
    input           clk_200m                ,
    input           reset_200m              ,
    input           dataout_valid_p         ,
    input   [`TDC_LENGTH_POWER-2:0]  dataout_p_fine          ,
    input   [31:0]  dataout_p_all           ,
    input           dataout_valid_n         ,
    input   [`TDC_LENGTH_POWER-2:0]  dataout_n_fine          ,
    input   [31:0]  dataout_n_all           ,
    input           Select_S                ,
    input           MUX_S                   ,
        
    output          lut_finish_ram1         ,
    output  [23:0]  p_lut_q                 ,
    output  [23:0]  n_lut_q                 ,
    output  [31:0]  dataout_p_all_dalay     ,
    output  [31:0]  dataout_n_all_dalay     ,
    output          q_valid                 
);
    wire  [23:0]  cal_q           ;
    wire  [`TDC_LENGTH_POWER-2:0]  cal_address     ;
    wire  [23:0]  cal_data        ;
    wire          cal_rden        ;
    wire          cal_wren        ;
    wire          cal_finish      ;
    wire  [23:0]  p_lut_data      ;
    wire  [`TDC_LENGTH_POWER-2:0]  p_lut_address   ;
    wire          p_lut_wren      ;
    wire          p_lut_rden      ;
    wire  [23:0]  n_lut_data      ;
    wire  [`TDC_LENGTH_POWER-2:0]  n_lut_address   ;
    wire          n_lut_wren      ;
    wire          n_lut_rden      ;
    wire          lut_finish_ram2 ;

    cal_ram_control     u0(
      .clk_200m         (clk_200m         ),
      .reset_200m       (reset_200m       ),
      .dataout_valid_p  (dataout_valid_p  ),
      .dataout_p_fine   (dataout_p_fine   ),
      .Select_S         (Select_S         ),
      .lut_finish_ram1  (lut_finish_ram1  ),
      .lut_finish_ram2  (lut_finish_ram2  ),
      .cal_q            (cal_q            ),
      .cal_address      (cal_address      ),
      .cal_data         (cal_data         ),
      .cal_wren         (cal_wren         ),
      .cal_rden         (cal_rden         ),
      .cal_finish       (cal_finish       )
    );
    
    ip_cal_ram    u1(
      .address    (cal_address  ),
      .clock      (clk_200m     ),
      .data       (cal_data     ),
      .rden       (cal_rden     ),
      .wren       (cal_wren     ),
      .q          (cal_q        )
    );




    
    lut_ram_control     u2(
      .clk_200m         (clk_200m         ),
      .reset_200m       (reset_200m       ),
      .cal_q            (cal_q            ),
      .cal_finish       (cal_finish       ),
      .MUX_S            (MUX_S            ),
      .dataout_valid    (dataout_valid_p  ),
      .dataout_fine     (dataout_p_fine   ),
      .lut_data         (p_lut_data       ),
      .lut_address      (p_lut_address    ),
      .lut_wren         (p_lut_wren       ),
      .lut_rden         (p_lut_rden       ),
      .lut_finish       (lut_finish_ram1  )
    );
    
    ip_lut_ram  u3(
      .address  (p_lut_address),
      .clock    (clk_200m     ),
      .data     (p_lut_data   ),
      .rden     (p_lut_rden   ),
      .wren     (p_lut_wren   ),
      .q        (p_lut_q      )
    );




    lut_ram_control     u4(
      .clk_200m         (clk_200m           ),
      .reset_200m       (reset_200m         ),
      .cal_q            (cal_q              ),
      .cal_finish       (cal_finish         ),
      .MUX_S            (MUX_S              ),
      .dataout_valid    (dataout_valid_n    ),
      .dataout_fine     (dataout_n_fine     ),
      .lut_data         (n_lut_data         ),
      .lut_address      (n_lut_address      ),
      .lut_wren         (n_lut_wren         ),
      .lut_rden         (n_lut_rden         ),
      .lut_finish       (lut_finish_ram2    )
    );
    
    ip_lut_ram  u5(
      .address  (n_lut_address),
      .clock    (clk_200m     ),
      .data     (n_lut_data   ),
      .rden     (n_lut_rden   ),
      .wren     (n_lut_wren   ),
      .q        (n_lut_q      )
    );






    valid                       u6(
      .clk_200m                 (clk_200m             ),
      .reset_200m               (reset_200m           ),
      .dataout_valid_p          (dataout_valid_p      ),
      .dataout_p_all            (dataout_p_all        ),
      .dataout_n_all            (dataout_n_all        ),
      .lut_finish_ram1          (lut_finish_ram1      ),
      .lut_finish_ram2          (lut_finish_ram2      ),
      .MUX_S                    (MUX_S                ),
      .dataout_p_all_dalay      (dataout_p_all_dalay  ),
      .dataout_n_all_dalay      (dataout_n_all_dalay  ),
      .q_valid                  (q_valid              )
    );
endmodule