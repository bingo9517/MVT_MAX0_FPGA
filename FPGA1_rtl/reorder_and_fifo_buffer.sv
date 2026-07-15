// Author:      lib
// Date:        2026-07-13
// Description: Reorder buffer and async FIFO   TI and VTH data.

`include "./param.v"

module reorder_and_fifo_buffer (

    input                                           clk_200m,       
    input                                           reset_200m,     
    input                                           rd_clk,        
 
    input                                           packet_start,   
    //input                                           cordic_valid,

    input   [2*(`MVT_THRESHOLDS)-1:0][17:0]         ti_in,
    input                                           ti_valid,
    input   [`MVT_CHANNEL-1:0][15:0]                vth_in,

    output  [17:0]                                  fifo_rdata, 
    output                                          fifo_data_valid, 
    output                                          tx_clk_out
);

//================================================================
// Part 1: Data Buffering
//================================================================
wire                                        fifo_full;
wire                                        fifo_empty;
wire                                        fifo_rd_en;

reg [2*(`MVT_THRESHOLDS)-1:0][17:0]         ti_reg;
reg [`MVT_CHANNEL-1:0][15:0]                vth_reg;
reg                                         ti_arrived;
reg                                         clear_flags;


always @(posedge clk_200m or negedge reset_200m) begin
    if (!reset_200m) begin
        ti_arrived <= 1'b0;
    end else if (clear_flags) begin 
        ti_arrived <= 1'b0;
    end else begin
        if (ti_valid) begin
            ti_arrived <= 1'b1; 
        end
    end
end


always @(posedge clk_200m or negedge reset_200m) begin
    if (!reset_200m) begin
        ti_reg  <= 'd0;
        vth_reg <= 'd0;
    end else begin
        if (ti_valid) begin
            ti_reg  <= ti_in;
            vth_reg <= vth_in;
        end
    end
end

//================================================================
// Part 2: Sequential Write Controller FSM (3-Segment)
//================================================================
localparam S_IDLE      = 2'd0;
localparam S_WRITE_TI  = 2'd1; 
localparam S_WRITE_VTH = 2'd2; 

reg [1:0]  current_state, next_state;
reg [17:0] fifo_wdata; 
reg        fifo_winc;
reg [7:0]  ti_write_idx; 
reg [7:0]  vth_write_idx;

wire ti_write_done  = (ti_write_idx  == 2*(`MVT_THRESHOLDS) - 1);
wire vth_write_done = (vth_write_idx == `MVT_CHANNEL - 1);


always @(posedge clk_200m or negedge reset_200m) begin
    if (!reset_200m) begin
        current_state <= S_IDLE;
    end else begin
        current_state <= next_state;
    end
end


always @(*) begin
    next_state = current_state;
    case (current_state)
        S_IDLE: begin
            if (packet_start) begin
                next_state = S_WRITE_TI;
            end
        end
        S_WRITE_TI: begin
            if (ti_arrived && ti_write_done) begin
                next_state = S_WRITE_VTH;
            end
        end
        S_WRITE_VTH: begin
            if (ti_arrived && vth_write_done) begin
                next_state = S_IDLE;
            end
        end
        default: next_state = S_IDLE;
    endcase
end


always @(posedge clk_200m or negedge reset_200m) begin
    if (!reset_200m) begin
        fifo_wdata    <= 18'b0;
        fifo_winc     <= 1'b0;
        clear_flags   <= 1'b0;
        ti_write_idx  <= 8'd0;
        vth_write_idx <= 8'd0;
    end else begin
        fifo_winc   <= 1'b0;
        clear_flags <= 1'b0;

        case (current_state)
            S_IDLE: begin
                ti_write_idx  <= 8'd0;
                vth_write_idx <= 8'd0;
            end
            
            S_WRITE_TI: begin
                if (ti_arrived) begin
                    fifo_wdata <= ti_reg[ti_write_idx];
                    fifo_winc  <= 1'b1;
                    if (ti_write_done) begin
                        ti_write_idx <= 8'd0;
                    end else begin
                        ti_write_idx <= ti_write_idx + 1'b1;
                    end
                end
            end

            S_WRITE_VTH: begin
                if (ti_arrived) begin
                    fifo_wdata <= {2'b00, vth_reg[vth_write_idx]};
                    fifo_winc  <= 1'b1;
                    if (vth_write_done) begin
                        vth_write_idx <= 8'd0;
                        clear_flags   <= 1'b1; 
                    end else begin
                        vth_write_idx <= vth_write_idx + 1'b1;
                    end
                end
            end

            default: ; 
        endcase
    end
end

//================================================================
// Part 3: Asynchronous FIFO & clk_out
//================================================================
// reg cordic_valid_d0;
// reg cordic_valid_d1;
// always @(posedge clk_200m or negedge reset_200m) begin
//     if (!reset_200m) begin
//         cordic_valid_d0 <= 1'b0;
//         cordic_valid_d1 <= 1'b0;
//     end else begin
//         cordic_valid_d0 <= cordic_valid;
//         cordic_valid_d1 <= cordic_valid_d0;
//     end
// end

assign tx_clk_out = rd_clk;
//assign fifo_rd_en = cordic_valid_d0 & ~cordic_valid_d1;
assign fifo_rd_en = !fifo_empty;

async_fifo #(
    .WIDTH_D(18),   
    .DEPTH(128),
    .WIDTH_A(7)
) tx_fifo_inst (
    // Write side
    .w_clk         (clk_200m),
    .rst_n         (reset_200m),
    .w_data        (fifo_wdata),
    .w_req         (fifo_winc && !fifo_full),
    .w_full        (fifo_full),
   
    // Read side
    .r_clk         (rd_clk),
    .r_req         (fifo_rd_en),
    .r_data        (fifo_rdata),
    .r_data_valid  (fifo_data_valid), 
    .r_empty       (fifo_empty)
);

endmodule