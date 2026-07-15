// Author:      lib
// Date:        2025-11-03
// Description: This module is used to bridge the cordic result to the UART.
//               The cordic result is stored in a FIFO and then sent to the UART.
//               A fixed 8'hFF for sync is sent before every result. 

module cordic_uart_bridge (
    input             clk_200m,
    input             reset_200m,
    input [23:0]      cordic_result,
    input             cordic_valid,

    input             clk_10m,
    input             reset_10m,
    output            tx_done,
    output            tx_pin_data
);

    wire              fifo_full;
    wire              fifo_empty;
    wire [23:0]       fifo_rdata;
    wire              fifo_r_req;
    wire              fifo_r_data_valid;
    wire              uart_cnt_en;
    wire [7:0]        uart_tx_data;

    async_fifo #(
        .WIDTH_D(24),
        .DEPTH(1024),
        .WIDTH_A(10)
    ) cordic_to_uart_fifo_inst (
        .w_clk      (clk_200m),
        .rst_n    	(reset_200m),
        .w_data     (cordic_result),
        .w_req      (cordic_valid && !fifo_full),
        .w_full     (fifo_full),

        .r_clk      (clk_10m),
        .r_req      (fifo_r_req),
        .r_data     (fifo_rdata),
        .r_data_valid (fifo_r_data_valid),
        .r_empty    (fifo_empty)
    );

    uart_tx uart_tx_top_inst (
        .clk      	(clk_10m),
        .rst_n    	(reset_10m),
        .data      	(uart_tx_data),
        .valid      (uart_cnt_en),
        .ready      (tx_done),
        .tx  		(tx_pin_data)
    );

    localparam FSM_IDLE         = 4'b0000;
    localparam FSM_REQ_DATA     = 4'b0001;
    localparam FSM_WAIT_DATA    = 4'b0010;
    localparam FSM_LATCH_DATA   = 4'b0011;
    localparam FSM_SEND_BYTE    = 4'b0100;
    localparam FSM_WAIT_TX_1    = 4'b0101;
    localparam FSM_WAIT_TX_2    = 4'b0110;
    localparam FSM_POLL_TX_DONE = 4'b0111;
    localparam FSM_CHECK_NEXT   = 4'b1000;

    reg [3:0] state, next_state;
    
    reg       fifo_r_req_reg;
    reg       uart_cnt_en_reg;
    
    reg [23:0] data_buffer_reg;
    reg [1:0]  byte_counter_reg;

    assign fifo_r_req  = fifo_r_req_reg;
    assign uart_cnt_en = uart_cnt_en_reg;

    assign uart_tx_data = (byte_counter_reg == 2'd0) ? 8'hFF :
                          (byte_counter_reg == 2'd1) ? data_buffer_reg[7:0]   :
                          (byte_counter_reg == 2'd2) ? data_buffer_reg[15:8]  :
                                                       data_buffer_reg[23:16];

    always @(posedge clk_10m or negedge reset_10m) begin
        if (!reset_10m) begin
            state <= FSM_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            FSM_IDLE: begin
                if (!fifo_empty) begin
                    next_state = FSM_REQ_DATA;
                end
            end
            
            FSM_REQ_DATA: begin
                next_state = FSM_WAIT_DATA;
            end

            FSM_WAIT_DATA: begin
                next_state = FSM_LATCH_DATA;
            end
            
            FSM_LATCH_DATA: begin
                next_state = FSM_SEND_BYTE;
            end
            
            FSM_SEND_BYTE: begin
                next_state = FSM_WAIT_TX_1;
            end

            FSM_WAIT_TX_1: begin
                next_state = FSM_WAIT_TX_2;
            end

            FSM_WAIT_TX_2: begin
                next_state = FSM_POLL_TX_DONE;
            end

            FSM_POLL_TX_DONE: begin
                if (tx_done) begin
                    next_state = FSM_CHECK_NEXT;
                end else begin
                    next_state = FSM_POLL_TX_DONE;
                end
            end
            
            FSM_CHECK_NEXT: begin
                if (byte_counter_reg < 2'd3) begin
                    next_state = FSM_SEND_BYTE;
                end else begin
                    if (!fifo_empty) begin
                        next_state = FSM_REQ_DATA;
                    end else begin
                        next_state = FSM_IDLE;
                    end
                end
            end

            default: begin
                next_state = FSM_IDLE;
            end
        endcase
    end

    always @(posedge clk_10m or negedge reset_10m) begin
        if (!reset_10m) begin
            fifo_r_req_reg   <= 1'b0;
            uart_cnt_en_reg  <= 1'b0;
            data_buffer_reg  <= 24'b0;
            byte_counter_reg <= 2'b0;
        end else begin
            fifo_r_req_reg  <= 1'b0;
            uart_cnt_en_reg <= 1'b0;
            
            case (state)
                FSM_IDLE: begin
                end

                FSM_REQ_DATA: begin
                    fifo_r_req_reg <= 1'b1;
                end

                FSM_WAIT_DATA: begin
                end

                FSM_LATCH_DATA: begin
                    if (fifo_r_data_valid) begin
                        data_buffer_reg <= fifo_rdata;
                        byte_counter_reg <= 2'd0;
                    end
                end
                
                FSM_SEND_BYTE: begin
                    uart_cnt_en_reg <= 1'b1;
                end
                
                FSM_WAIT_TX_1: begin
                end

                FSM_WAIT_TX_2: begin
                end

                FSM_POLL_TX_DONE: begin
                end
                
                FSM_CHECK_NEXT: begin
                    if (byte_counter_reg < 2'd3) begin
                        byte_counter_reg <= byte_counter_reg + 1;
                    end else begin
                        byte_counter_reg <= 2'd0; 
                    end
                end
                
                default: begin
                    byte_counter_reg <= 2'd0;
                end
            endcase
        end
    end

endmodule