module spi_module(
    input               clk_50m     , // 全局时钟50MHz
    input               reset_50m   , // 复位信号，低电平有效
//  input               I_rx_en     , // 读使能信号
    input               i_tx_en     , // 发送使能信号
    input       [23:0]  i_data_in   , // 要发送的数据
    input       [1:0]   adr         ,
//  output  reg [31:0]  O_data_out  , // 接收到的数据
    output  reg         o_tx_done   , // 发送一个通道完毕标志位
//  output  reg         O_rx_done   , // 接收一个通道完毕标志位

    // 四线标准SPI信号定义
//  input               I_spi_miso  , // SPI串行输入，用来接收从机的数据
    output  reg         o_spi_sck   , // SPI时钟
    output  reg         o_spi_cso   , // SPI片选信号1
    output  reg         o_spi_cst   , // SPI片选信号1
    output  reg         o_spi_mosi    // SPI输出，用来给从机发送数据          
);

  reg [6:0]   R_tx_state      ; 
//reg [6:0]   R_rx_state      ;

  always @(posedge clk_50m or negedge reset_50m)
  begin
      if(!reset_50m)
          begin
              R_tx_state  <=  7'd0    ;
  //          R_rx_state  <=  7'd0    ;
              o_spi_cso   <=  1'b1    ;
              o_spi_cst   <=  1'b1    ;
              o_spi_sck   <=  1'b0    ;
              o_spi_mosi  <=  1'b0    ;
              o_tx_done   <=  1'b0    ;
  //          O_rx_done   <=  1'b0    ;
  //          O_data_out  <=  8'd0    ;
          end 
      else if(i_tx_en && adr == 2'b01) // 发送使能信号打开的情况下
          begin
              o_spi_cso <= 1'b0    ; // 把DAC1片选CS拉低
              case(R_tx_state)
                7'd1, 7'd3,  7'd5,  7'd7, 
                7'd9, 7'd11, 7'd13, 7'd15 ,
                7'd17,7'd19, 7'd21, 7'd23 ,
                7'd25,7'd27, 7'd29, 7'd31 ,
                7'd33,7'd35, 7'd37, 7'd39 ,
                7'd41,7'd43, 7'd45, 7'd47 :
                // 7'd49,7'd51, 7'd53, 7'd55 ,
                // 7'd57,7'd59, 7'd61, 7'd63 : 
                      begin
                          o_spi_sck   <=  1'b1                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd0:
                      begin
                          o_spi_mosi  <=  i_data_in[23]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd2:
                      begin
                          o_spi_mosi  <=  i_data_in[22]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd4:
                      begin
                          o_spi_mosi  <=  i_data_in[21]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd6:
                      begin
                          o_spi_mosi  <=  i_data_in[20]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd8:
                      begin
                          o_spi_mosi  <=  i_data_in[19]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                end
                7'd10:
                      begin
                          o_spi_mosi  <=  i_data_in[18]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd12:
                      begin
                          o_spi_mosi  <=  i_data_in[17]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd14:
                      begin
                          o_spi_mosi  <=  i_data_in[16]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd16:
                      begin
                          o_spi_mosi  <=  i_data_in[15]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd18:
                      begin
                          o_spi_mosi  <=  i_data_in[14]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd20:
                      begin
                          o_spi_mosi  <=  i_data_in[13]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd22:
                      begin
                          o_spi_mosi  <=  i_data_in[12]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd24:
                      begin
                          o_spi_mosi  <=  i_data_in[11]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd26:
                      begin
                          o_spi_mosi  <=  i_data_in[10]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd28:
                      begin
                          o_spi_mosi  <=  i_data_in[9]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd30:
                      begin
                          o_spi_mosi  <=  i_data_in[8]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                end
                7'd32:
                      begin
                          o_spi_mosi  <=  i_data_in[7]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd34:
                      begin
                          o_spi_mosi  <=  i_data_in[6]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd36:
                      begin
                          o_spi_mosi  <=  i_data_in[5]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd38:
                      begin
                          o_spi_mosi  <=  i_data_in[4]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd40:
                      begin
                          o_spi_mosi  <=  i_data_in[3]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd42:
                      begin
                          o_spi_mosi  <=  i_data_in[2]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd44:
                      begin
                          o_spi_mosi  <=  i_data_in[1]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd46:
                      begin
                          o_spi_mosi  <=  i_data_in[0]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b1                ;
                      end
                // 7'd48:
                //       begin
                //           o_spi_mosi  <=  i_data_in[7]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd50:
                //       begin
                //           o_spi_mosi  <=  i_data_in[6]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd52:
                //       begin
                //           o_spi_mosi  <=  i_data_in[5]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                // end
                // 7'd54:
                //       begin
                //           o_spi_mosi  <=  i_data_in[4]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd56:
                //       begin
                //           o_spi_mosi  <=  i_data_in[3]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd58:
                //       begin
                //           o_spi_mosi  <=  i_data_in[2]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd60:
                //       begin
                //           o_spi_mosi  <=  i_data_in[1]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd62:
                //       begin
                //           o_spi_mosi  <=  i_data_in[0]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b1                ;
                //       end
                  default:R_tx_state  <=  4'd0                ;   
              endcase 
          end
     else if(i_tx_en && adr == 2'b10) // 发送使能信号打开的情况下
          begin
              o_spi_cst    <=  1'b0    ; // 把DAC1片选CS拉低
              case(R_tx_state)
                7'd1, 7'd3 , 7'd5 , 7'd7  , 
                7'd9, 7'd11, 7'd13, 7'd15 ,
                7'd17,7'd19, 7'd21, 7'd23 ,
                7'd25,7'd27, 7'd29, 7'd31 ,
                7'd33,7'd35, 7'd37, 7'd39 ,
                7'd41,7'd43, 7'd45, 7'd47 :
                // 7'd49,7'd51, 7'd53, 7'd55 ,
                // 7'd57,7'd59, 7'd61, 7'd63 : 
                      begin
                          o_spi_sck   <=  1'b1                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd0:
                      begin
                          o_spi_mosi  <=  i_data_in[23]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd2:
                      begin
                          o_spi_mosi  <=  i_data_in[22]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd4:
                      begin
                          o_spi_mosi  <=  i_data_in[21]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd6:
                      begin
                          o_spi_mosi  <=  i_data_in[20]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd8:
                      begin
                          o_spi_mosi  <=  i_data_in[19]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                end
                7'd10:
                      begin
                          o_spi_mosi  <=  i_data_in[18]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd12:
                      begin
                          o_spi_mosi  <=  i_data_in[17]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd14:
                      begin
                          o_spi_mosi  <=  i_data_in[16]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd16:
                      begin
                          o_spi_mosi  <=  i_data_in[15]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd18:
                      begin
                          o_spi_mosi  <=  i_data_in[14]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd20:
                      begin
                          o_spi_mosi  <=  i_data_in[13]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd22:
                      begin
                          o_spi_mosi  <=  i_data_in[12]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd24:
                      begin
                          o_spi_mosi  <=  i_data_in[11]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd26:
                      begin
                          o_spi_mosi  <=  i_data_in[10]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd28:
                      begin
                          o_spi_mosi  <=  i_data_in[9]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd30:
                      begin
                          o_spi_mosi  <=  i_data_in[8]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                end
                7'd32:
                      begin
                          o_spi_mosi  <=  i_data_in[7]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd34:
                      begin
                          o_spi_mosi  <=  i_data_in[6]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd36:
                      begin
                          o_spi_mosi  <=  i_data_in[5]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd38:
                      begin
                          o_spi_mosi  <=  i_data_in[4]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd40:
                      begin
                          o_spi_mosi  <=  i_data_in[3]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd42:
                      begin
                          o_spi_mosi  <=  i_data_in[2]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd44:
                      begin
                          o_spi_mosi  <=  i_data_in[1]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b0                ;
                      end
                7'd46:
                      begin
                          o_spi_mosi  <=  i_data_in[0]        ;
                          o_spi_sck   <=  1'b0                ;
                          R_tx_state  <=  R_tx_state + 1'b1   ;
                          o_tx_done   <=  1'b1                ;
                      end
                // 7'd48:
                //       begin
                //           o_spi_mosi  <=  i_data_in[7]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd50:
                //       begin
                //           o_spi_mosi  <=  i_data_in[6]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd52:
                //       begin
                //           o_spi_mosi  <=  i_data_in[5]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                // end
                // 7'd54:
                //       begin
                //           o_spi_mosi  <=  i_data_in[4]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd56:
                //       begin
                //           o_spi_mosi  <=  i_data_in[3]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd58:
                //       begin
                //           o_spi_mosi  <=  i_data_in[2]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd60:
                //       begin
                //           o_spi_mosi  <=  i_data_in[1]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b0                ;
                //       end
                // 7'd62:
                //       begin
                //           o_spi_mosi  <=  i_data_in[0]        ;
                //           o_spi_sck   <=  1'b0                ;
                //           R_tx_state  <=  R_tx_state + 1'b1   ;
                //           o_tx_done   <=  1'b1                ;
                //       end
                  default:R_tx_state  <=  4'd0                ;   
              endcase 
          end
  //    else if(I_rx_en) // 接收使能信号打开的情况下
  //        begin
  //            O_spi_cs    <=  1'b0        ; // 拉低片选信号CS
  //            case(R_rx_state)
  //                4'd0, 4'd2 , 4'd4 , 4'd6  , 
  //                4'd8, 4'd10, 4'd12, 4'd14 : //整合偶数状态
  //                    begin
  //                        o_spi_sck   　　 <=  1'b0                ;
  //                        R_rx_state  　　 <=  R_rx_state + 1'b1   ;
  //                        O_rx_done   　　 <=  1'b0                ;
  //                    end
  //                4'd1:    // 接收第7位
  //                    begin                       
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[7]   <=  I_spi_miso          ;   
  //                    end
  //                4'd3:    // 接收第6位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[6]   <=  I_spi_miso          ; 
  //                    end
  //                4'd5:    // 接收第5位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[5]   <=  I_spi_miso          ; 
  //                    end 
  //                4'd7:    // 接收第4位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[4]   <=  I_spi_miso          ; 
  //                    end 
  //                4'd9:    // 接收第3位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[3]   <=  I_spi_miso          ; 
  //                    end                            
  //                4'd11:    // 接收第2位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[2]   <=  I_spi_miso          ; 
  //                    end 
  //                4'd13:    // 接收第1位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b0                ;
  //                        O_data_out[1]   <=  I_spi_miso          ; 
  //                    end 
  //                4'd15:    // 接收第0位
  //                    begin
  //                        o_spi_sck       <=  1'b1                ;
  //                        R_rx_state      <=  R_rx_state + 1'b1   ;
  //                        O_rx_done       <=  1'b1                ;
  //                        O_data_out[0]   <=  I_spi_miso          ; 
  //                    end
  //                default:R_rx_state  <=  4'd0                    ;   
  //            endcase 
  //        end    
      else
          begin
              R_tx_state  <=  7'd0    ;
  //          R_rx_state  <=  4'd0    ;
              o_tx_done   <=  1'b0    ;
  //          O_rx_done   <=  1'b0    ;
              o_spi_cso   <=  1'b1    ;
              o_spi_cst   <=  1'b1    ;
              o_spi_sck   <=  1'b0    ;
              o_spi_mosi  <=  1'b0    ;
  //          O_data_out  <=  8'd0    ;
          end      
  end
  
  endmodule
  