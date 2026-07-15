module dac_block(
    input                 clk         ,
    input                 reset       ,
    //  input               i_enable  ,
    //  input      [255:0]  i_data    ,
  
    output                o_spi_sck   ,
    output                o_spi_cso   ,
    output                o_spi_cst   ,
    output                o_spi_mosi  
);

  wire [23:0]   spidata   ;
  wire          spienable ;
  wire [1:0]    adr       ;
  wire          txdone    ;
  
          
  dacconfig           u1(
      .clk            (clk    ),
      .reset          (reset   ),
////**SAE_1**//
      .configdata({
       16'h63D6,16'h5D97,16'h5758,16'h5119,
       16'h4AE7,16'h44A8,16'h3E69,16'h624F,
       16'h5605,16'h49BB,16'h3D71,16'h3127,
       16'h24DD,16'h1893,16'h0C49,16'h0068
      }),//122,244,366,488,610,732,854,976,1098,1220,1342,1464,1586,1708,1830,1952
//    .configdata     (i_data   ),
//    .enable         (i_enable ),
      .enable         (1'b0     ),
      .configenable   (txdone   ),
      .spidata        (spidata  ),
      .spienable      (spienable),
      .adr            (adr      )
    );
  
  
  spi_module        u2(
     .clk_50m       (clk      ),  
     .reset_50m     (reset     ),
     .i_tx_en       (spienable),
     .i_data_in     (spidata  ),
     .adr           (adr      ),
     .o_tx_done     (txdone   ),
     .o_spi_sck     (o_spi_sck),
     .o_spi_cso     (o_spi_cso),
     .o_spi_cst     (o_spi_cst),
     .o_spi_mosi    (o_spi_mosi)      
    );
  endmodule