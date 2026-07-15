module    dacconfig(
  input               clk         ,
  input               reset       ,
  input       [255:0] configdata  ,
  input               enable      ,
  input               configenable,
  output  reg [23:0]  spidata     ,
  output  reg         spienable   ,
  output  reg [1:0]   adr         
  );
  reg [4:0]    mcnt;
  reg [255:0]  configdata_temp;
  
  reg [8:0]    current_state;
  reg [8:0]    next_state;
  
  parameter idle = 9'b0_0000_0001;
  parameter   s0 = 9'b0_0000_0010;
  parameter   s1 = 9'b0_0000_0100;
  parameter   s2 = 9'b0_0000_1000;
  parameter   s3 = 9'b0_0001_0000;
  parameter   s4 = 9'b0_0010_0000;
  parameter   s5 = 9'b0_0100_0000;
  parameter   s6 = 9'b0_1000_0000;
  parameter   s7 = 9'b1_0000_0000;
  
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      current_state<=idle;
    else
      current_state<=next_state;
  end
  always@(*)
  begin
    if(!reset)
      next_state = idle;
    else
      begin
        case(current_state)
          idle:next_state = (!enable) ? s0 : idle;
            s0:next_state = s1;
            s1:next_state = s2;
            s2:next_state = s3;
            s3:next_state = configenable ? s4 : s3;
            s4:next_state = mcnt > 5'd15 ? s7 : s5;
            s5:next_state = s6;
            s6:next_state = s3;
            s7:next_state = idle;
          default:next_state = 4'd0;
        endcase
      end
  end
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      mcnt<=5'd0;
    else
      begin
        case(next_state)
          idle:mcnt<=5'd0;
            s0:mcnt<=mcnt;
            s1:mcnt<=mcnt;
            s2:mcnt<=mcnt;
            s3:mcnt<=mcnt;
            s4:mcnt<=mcnt+1'b1;
            s5:mcnt<=mcnt;
            s6:mcnt<=mcnt;
            s7:mcnt<=5'd0;
          default:mcnt<=5'b00000;
        endcase
      end
  end
  
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      configdata_temp<=256'd0;
    else
      begin
        case(next_state)
          idle:configdata_temp<=256'd0;
            s0:configdata_temp<=configdata;
            s1:configdata_temp<=configdata_temp;
            s2:configdata_temp<=configdata_temp;
            s3:configdata_temp<=configdata_temp;
            s4:configdata_temp<={16'd0,configdata_temp[255:16]};
            s5:configdata_temp<=configdata_temp;
            s6:configdata_temp<=configdata_temp;
            s7:configdata_temp<=configdata_temp;
          default:configdata_temp<=256'd0;
        endcase
      end
  end
  
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      spidata<=24'd0;
    else
      begin
        case(next_state)
          idle:spidata<=24'd0;
            s0:spidata<=spidata;
            s1:spidata<={4'b0011,mcnt[3:0],configdata_temp[15:0]};
            s2:spidata<=spidata;
            s3:spidata<=spidata;
            s4:spidata<=spidata;
            s5:spidata<={4'b0011,mcnt[3:0],configdata_temp[15:0]};
            s6:spidata<=spidata;
            s7:spidata<=spidata;
          default:spidata<=32'd0;
        endcase
      end
  end
  
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      adr<=2'b00;
    else
      begin
        case(next_state)
          idle:adr<=2'b00;
            s0:adr<=2'b00;
            s1:adr<=2'b01;
            s2:adr<=2'b01;
            s3:adr<=2'b01;
            s4:adr<=2'b01;
            s5:adr<=2'b01;
            s6:adr<=2'b01;
            s7:adr<=2'b01;
          default:adr<=2'b00;
        endcase
      end
  end
  
  always@(posedge clk or negedge reset)
  begin
    if(!reset)
      spienable<=1'b0;
    else
      begin
        case(next_state)
          idle:spienable<=1'b0;
            s0:spienable<=1'b0;
            s1:spienable<=1'b0;
            s2:spienable<=1'b1;
            s3:spienable<=1'b1;
            s4:spienable<=1'b0;
            s5:spienable<=1'b0;
            s6:spienable<=1'b1;
            s7:spienable<=1'b0;
          default:spienable<=1'b0;
        endcase
      end
  end
  
  endmodule