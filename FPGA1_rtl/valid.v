module valid(
    input               clk_200m                ,
    input               reset_200m              ,
    input               dataout_valid_p         ,
    input       [31:0]  dataout_p_all           ,
    input       [31:0]  dataout_n_all           ,
    input               MUX_S                   ,
    input               lut_finish_ram1         ,
    input               lut_finish_ram2         ,   

    output              q_valid                 ,
    output      [31:0]  dataout_p_all_dalay     ,
    output      [31:0]  dataout_n_all_dalay     
);

    wire            dataout_valid_p_dalay ;

    data_delay
    #(
        .M(1),
        .N(3)
    )
    u1
    (
        .clk        (clk_200m),
        .data_in    (dataout_valid_p),
        .data_out   (dataout_valid_p_dalay)
    );

    data_delay
    #(
        .M(32),
        .N(3)
    )
    u2
    (
        .clk        (clk_200m),
        .data_in    (dataout_p_all),
        .data_out   (dataout_p_all_dalay)
    );

    data_delay
    #(
        .M(32),
        .N(3)
    )
    u3
    (
        .clk        (clk_200m),
        .data_in    (dataout_n_all),
        .data_out   (dataout_n_all_dalay)
    );

    assign  q_valid = dataout_valid_p_dalay & !(MUX_S || lut_finish_ram1 || lut_finish_ram2);
    
    
endmodule