// Author:      lib
// Date:        2025-12-04
// Description: FIFO receiver module optimized for continuous burst reading.


`include "./param.v"

module fifo_rx
(
    input   clk,
    input   reset,

    input   rx_clk_in,
    input   fifo_data_valid,
    input   [17:0] data_in, 
    input   cordic_valid,

    output reg  [2*(`MVT_THRESHOLDS)-1:0][17:0] ti,
    output reg  [`MVT_CHANNEL-1:0][15:0] v_threshold,
    
    output reg  ti_valid
);


    localparam NUM_TI_WORDS = 2*(`MVT_THRESHOLDS);
    localparam NUM_KS_WORDS = `MVT_CHANNEL;
    localparam TOTAL_WORDS  = NUM_TI_WORDS + NUM_KS_WORDS;
    
    localparam COUNT_WIDTH  = $clog2(TOTAL_WORDS + 1);


    localparam S_IDLE       = 2'd0;
    localparam S_READ       = 2'd1; // Continuous reading state
    localparam S_OUT        = 2'd2; // Output update state

    reg [1:0] state_reg, state_next;

    // Counters for burst reading
    reg [COUNT_WIDTH-1:0] cnt_req;
    reg [COUNT_WIDTH-1:0] cnt_rec;

    reg [17:0] data_temp[0:TOTAL_WORDS-1];
    reg [1:0]  valid_reg; // track which data types have been received

    //----------------------------------------------------------------
    // 0. Receive Data from Async FIFO 
    //----------------------------------------------------------------
    reg [17:0] rx_data_reg, rx_data_reg_d0;
    reg        rx_valid_reg, rx_valid_reg_d0;
    reg ready;

    always @(posedge rx_clk_in or negedge reset) begin
        if (!reset) begin
            rx_data_reg      <= 18'd0;
            rx_valid_reg     <= 1'b0;
            rx_data_reg_d0   <= 18'd0;
            rx_valid_reg_d0  <= 1'b0;
        end else begin
            rx_data_reg_d0  <= data_in;
            rx_valid_reg_d0 <= fifo_data_valid;
            rx_data_reg  <= rx_data_reg_d0;
            rx_valid_reg <= rx_valid_reg_d0;
        end
    end

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            ready <= 1'b1;
        end else if(ti_valid) begin
            ready <= 1'b0;
        end else if(cordic_valid) begin
            ready <= 1'b1;
        end
    end

    wire [17:0] fifo_out_data;
    wire        fifo_out_valid;
    wire        fifo_out_empty;
    reg         rd_en; 

    // Async FIFO Instantiation
    async_fifo #(
        .WIDTH_D(18),
        .DEPTH(1024), 
        .WIDTH_A(10)
    ) rx_fifo_inst (
        .w_clk         (rx_clk_in),
        .rst_n         (reset),     
        .w_data        (rx_data_reg),
        .w_req         (rx_valid_reg), 
        .w_full        (),           
        
        .r_clk         (clk),
        .r_req         (rd_en),
        .r_data        (fifo_out_data),
        .r_data_valid  (fifo_out_valid),
        .r_empty       (fifo_out_empty)
    );



    //----------------------------------------------------------------
    // 1. FSM State Register
    //----------------------------------------------------------------
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state_reg <= S_IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    //----------------------------------------------------------------
    // 2. FSM Next-State Logic & Read Enable Control
    //----------------------------------------------------------------
    always @(*) begin
        state_next = state_reg;
        rd_en      = 1'b0;

        case (state_reg)
            S_IDLE: begin
                if (!fifo_out_empty) begin
                    state_next = S_READ;
                end else begin
                    state_next = S_IDLE;
                end
            end

            S_READ: begin
                if ((!fifo_out_empty) && (cnt_req < TOTAL_WORDS) && ready) begin
                    rd_en = 1'b1;
                end else begin
                    rd_en = 1'b0;
                end
                // cnt_req reaches TOTAL_WORDS before cnt_rec due to latency.
                if (cnt_rec >= TOTAL_WORDS) begin
                    state_next = S_OUT;
                end else begin
                    state_next = S_READ;
                end
            end

            S_OUT: begin
                rd_en      = 1'b0;
                state_next = S_IDLE;
            end

            default: begin
                state_next = S_IDLE;
            end
        endcase
    end

    //----------------------------------------------------------------
    // 3. Sequential Logic (Counters, Data Latching, Output)
    //----------------------------------------------------------------
    integer i;
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            cnt_req        <= 'd0;
            cnt_rec        <= 'd0;
            
            for (i = 0; i < TOTAL_WORDS; i = i + 1) begin
                data_temp[i] <= 'd0;
            end          
            ti             <= 'h0;
            v_threshold      <= 'h0;
            ti_valid       <= 'b0;         
            valid_reg      <= 'd0;
        end else begin
            case (state_reg)
                S_IDLE: begin
                    cnt_req   <= 'd0;
                    cnt_rec   <= 'd0;
                    valid_reg <= 'd0;
                    ti_valid  <= 1'b0;
                end

                S_READ: begin
                    if (rd_en) begin
                        cnt_req <= cnt_req + 1;
                    end

                    if (fifo_out_valid) begin
                        if (cnt_rec < TOTAL_WORDS) begin
                            data_temp[cnt_rec] <= fifo_out_data;
                        end
                        case (cnt_rec)
                            NUM_TI_WORDS - 1:   valid_reg[0] <= 1'b1; // ti done
                            TOTAL_WORDS  - 1:   valid_reg[1] <= 1'b1; // v_threshold done
                            default:            valid_reg    <= valid_reg;
                        endcase
                        cnt_rec <= cnt_rec + 1;
                    end
                end

                S_OUT: begin
                    // Reassemble data packets
                    for (i = 0; i < NUM_TI_WORDS; i = i + 1) begin
                        ti[i] <= data_temp[i];
                    end 
                    for (i = NUM_TI_WORDS; i < TOTAL_WORDS; i = i + 1) begin
                        v_threshold[i-NUM_TI_WORDS] <= data_temp[i];
                    end                  
                    ti_valid <= valid_reg[1];
                end

                default: begin
                    cnt_req  <= cnt_req;
                    cnt_rec  <= cnt_rec;
                    ti       <= ti;
                    ti_valid <= ti_valid;
                    valid_reg <= valid_reg;
                end
            endcase
        end
    end

endmodule