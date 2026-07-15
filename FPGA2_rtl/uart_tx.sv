
module uart_tx #(
  parameter CLK_FREQ = 10_000_000,
  parameter BAUD_RATE = 128000
)(
  input   clk,
  input   rst_n,
  output reg tx,
  input   [7:0] data,
  input   valid,
  output reg ready
);

  localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
  localparam   IDLE              = 4'b0001;
  localparam   START             = 4'b0010;
  localparam   DATA              = 4'b0100;
  localparam   STOP              = 4'b1000;  
  
  reg[3:0] state;
  reg[3:0] next_state;
  reg [2:0] bit_cnt;
  reg [15:0] clk_cnt;
  reg [7:0] shift_reg;
  
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          state <= IDLE;
      end else begin
          state <= next_state;
      end
  end  
  
  always @(*) begin
      next_state = state;
      case (state)
          IDLE: begin 
			if (valid) begin
				next_state = START;
            end  
          end

          START: begin
			if (clk_cnt == BIT_PERIOD-1) begin
				next_state = DATA;
			end
          end

          DATA: begin
			if ((clk_cnt == BIT_PERIOD-1) && (bit_cnt == 7) ) begin
				next_state = STOP;
			end
          end
		  
          STOP: begin
			if (clk_cnt == BIT_PERIOD-1) begin
				next_state = IDLE;
			end
          end

          default: begin
              next_state = IDLE;
          end
      endcase
  end
	

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      //state <= IDLE;
      tx <= 1'b1;
      ready <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (valid) begin
            //state <= START;
            shift_reg <= data;
            clk_cnt <= 0;
            ready <= 1'b0;
          end
        end
        
        START: begin
          tx <= 1'b0;
          if (clk_cnt == BIT_PERIOD-1) begin
            //state <= DATA;
            clk_cnt <= 0;
            bit_cnt <= 0;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        
        DATA: begin
          tx <= shift_reg[0];
          if (clk_cnt == BIT_PERIOD-1) begin
            clk_cnt <= 0;
            shift_reg <= shift_reg >> 1;
           // if (bit_cnt == 7) begin
           //   state <= STOP;
           // end else begin
              bit_cnt <= bit_cnt + 1;
           // end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        
        STOP: begin
          tx <= 1'b1;
          if (clk_cnt == BIT_PERIOD-1) begin
            //state <= IDLE;
            ready <= 1'b1;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
      endcase
    end
  end
endmodule
