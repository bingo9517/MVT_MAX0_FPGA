// Author: lib
// Date: 2026-07-14
// Description: 1-D delta search optimizer with single cost core.

`include "./param.v"

module ti_optimization_ctrl #(
    parameter ITER_NUM = 8 
)(
    input  wire                                 clk_200m,
    input  wire                                 reset_200m,
    
    input  wire [2*(`MVT_CHANNEL)-1:0][17:0]    ti_in,
    input  wire                                 ti_valid_in,
    input  wire [`MVT_CHANNEL-1:0][15:0]        v_threshold,

    output reg  [2*(`MVT_CHANNEL)-1:0][17:0]    ti_out,
    output reg                                  ti_valid_out,
    
    output reg  signed [31:0]                   final_a,
    output reg  signed [31:0]                   final_b,
    output reg  signed [31:0]                   final_c,
    output reg                                  final_a_valid,
    output reg                                  final_b_valid,
    output reg                                  final_c_valid
);

    // FSM states
    localparam S_IDLE       = 4'd0,
               S_EVAL_0     = 4'd1,
               S_WAIT_0     = 4'd2,
               S_EVAL_1     = 4'd3,
               S_WAIT_1     = 4'd4,
               S_EVAL_2     = 4'd5,
               S_WAIT_2     = 4'd6,
               S_EVAL_3     = 4'd7,
               S_WAIT_3     = 4'd8,
               S_COMPARE    = 4'd9,
               S_EVAL_FINAL = 4'd10,
               S_WAIT_FINAL = 4'd11,
               S_DONE       = 4'd12;

    localparam COST_WIDTH = 64 + $clog2(2*(`MVT_CHANNEL)); 

    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [7:0] iter_cnt;
    reg signed [19:0] best_delta;
    reg [17:0]        t0_reg;       
    
    reg [2*(`MVT_CHANNEL)-1:0][17:0] ti_init_array;
    reg [`MVT_CHANNEL-1:0][15:0]     v_threshold_reg;
    reg [2*(`MVT_CHANNEL)-1:0][17:0] mux_ti_0;
    reg                                 mux_valid_0;
    
    wire [COST_WIDTH-1:0] cost_out_w;
    wire                  cost_valid_w;
    reg  [COST_WIDTH-1:0] cost_reg     [0:3];

    wire signed [31:0] w_a_out, w_b_out, w_c_out;
    wire w_a_valid, w_b_valid, w_c_valid;


    signal_rebuild_cost u_cost_0(
        .clk_200m    (clk_200m),
        .reset_200m  (reset_200m),
        .ti          (mux_ti_0),
        .ti_valid    (mux_valid_0),
        .v_threshold (v_threshold_reg),
        .cost_out    (cost_out_w),
        .cost_valid  (cost_valid_w),
        .a_out       (w_a_out),
        .b_out       (w_b_out),
        .c_out       (w_c_out),
        .a_valid_out (w_a_valid),
        .b_valid_out (w_b_valid),
        .c_valid_out (w_c_valid)
    );

    wire [17:0] step_val;
    assign step_val = t0_reg >> (2 + iter_cnt); 
    
    wire signed [19:0] s_step = $signed({2'b00, step_val});
    wire signed [19:0] d_offset [0:3];
    
    assign d_offset[0] = -s_step;
    assign d_offset[1] = 20'sd0;
    assign d_offset[2] = s_step;
    assign d_offset[3] = (s_step <<< 1);

    localparam signed [20:0] MAX_TI_VAL = 21'sd262143;

    function [17:0] apply_offset;
        input [17:0] val;
        input signed [19:0] off;
        reg signed [20:0] temp;
        begin
            temp = $signed({1'b0, val}) - off;
            if (temp < 0) 
                apply_offset = 18'd0;
            else if (temp > MAX_TI_VAL) 
                apply_offset = 18'h3FFFF;
            else 
                apply_offset = temp[17:0];
        end
    endfunction

    // Min cost index selection
    wire [1:0]  min_idx_01 = (cost_reg[0] <= cost_reg[1]) ? 2'd0 : 2'd1;
    wire [COST_WIDTH-1:0] min_val_01 = (cost_reg[0] <= cost_reg[1]) ? cost_reg[0] : cost_reg[1];

    wire [1:0]  min_idx_23 = (cost_reg[2] <= cost_reg[3]) ? 2'd2 : 2'd3;
    wire [COST_WIDTH-1:0] min_val_23 = (cost_reg[2] <= cost_reg[3]) ? cost_reg[2] : cost_reg[3];
    wire [1:0]  final_min_idx = (min_val_01 <= min_val_23) ? min_idx_01 : min_idx_23;

    // FSM State Register (1st segment)
    always @(posedge clk_200m or negedge reset_200m) begin
        if(!reset_200m) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    always @(*) begin
        next_state = current_state;
        case(current_state)
            S_IDLE: begin
                if(ti_valid_in) 
                    next_state = S_EVAL_0;
            end
            S_EVAL_0: begin
                next_state = S_WAIT_0;
            end
            S_WAIT_0: begin
                if(cost_valid_w) 
                    next_state = S_EVAL_1;
            end
            S_EVAL_1: begin
                next_state = S_WAIT_1;
            end
            S_WAIT_1: begin
                if(cost_valid_w) 
                    next_state = S_EVAL_2;
            end
            S_EVAL_2: begin
                next_state = S_WAIT_2;
            end
            S_WAIT_2: begin
                if(cost_valid_w) 
                    next_state = S_EVAL_3;
            end
            S_EVAL_3: begin
                next_state = S_WAIT_3;
            end
            S_WAIT_3: begin
                if(cost_valid_w) 
                    next_state = S_COMPARE;
            end
            S_COMPARE: begin
                if(iter_cnt == ITER_NUM - 1) 
                    next_state = S_EVAL_FINAL;
                else 
                    next_state = S_EVAL_0;
            end
            S_EVAL_FINAL: begin
                next_state = S_WAIT_FINAL;
            end
            S_WAIT_FINAL: begin
                if(w_a_valid) 
                    next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    integer i;
    always @(posedge clk_200m or negedge reset_200m) begin
        if(!reset_200m) begin
            iter_cnt        <= 8'd0;
            best_delta      <= 20'sd0;
            t0_reg          <= 18'd0;
            ti_out          <= 'd0;
            ti_valid_out    <= 1'b0;
            mux_ti_0        <= 'd0;
            v_threshold_reg <= 'd0;
            mux_valid_0     <= 1'b0;

            cost_reg[0]     <= 'd0;
            cost_reg[1]     <= 'd0;
            cost_reg[2]     <= 'd0;
            cost_reg[3]     <= 'd0;

            final_a         <= 32'd0;
            final_b         <= 32'd0;
            final_c         <= 32'd0;
            final_a_valid   <= 1'b0;
            final_b_valid   <= 1'b0;
            final_c_valid   <= 1'b0;
            ti_init_array   <= 'd0;
        end else begin
            ti_valid_out  <= 1'b0;
            mux_valid_0   <= 1'b0;
            final_a_valid <= 1'b0;
            final_b_valid <= 1'b0;
            final_c_valid <= 1'b0;

            case(current_state)
                S_IDLE: begin
                    if(ti_valid_in) begin
                        ti_init_array   <= ti_in;
                        v_threshold_reg <= v_threshold;
                        t0_reg          <= ti_in[0];
                        best_delta      <= $signed({2'b00, ti_in[0] >> 1}); 
                        iter_cnt        <= 8'd0;
                    end
                end

                S_EVAL_0: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        mux_ti_0[i] <= apply_offset(ti_init_array[i], best_delta + d_offset[0]);
                    end
                    mux_valid_0 <= 1'b1;
                end

                S_WAIT_0: begin
                    if(cost_valid_w) cost_reg[0] <= cost_out_w;
                end

                S_EVAL_1: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        mux_ti_0[i] <= apply_offset(ti_init_array[i], best_delta + d_offset[1]);
                    end
                    mux_valid_0 <= 1'b1;
                end

                S_WAIT_1: begin
                    if(cost_valid_w) cost_reg[1] <= cost_out_w;
                end

                S_EVAL_2: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        mux_ti_0[i] <= apply_offset(ti_init_array[i], best_delta + d_offset[2]);
                    end
                    mux_valid_0 <= 1'b1;
                end

                S_WAIT_2: begin
                    if(cost_valid_w) cost_reg[2] <= cost_out_w;
                end

                S_EVAL_3: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        mux_ti_0[i] <= apply_offset(ti_init_array[i], best_delta + d_offset[3]);
                    end
                    mux_valid_0 <= 1'b1;
                end

                S_WAIT_3: begin
                    if(cost_valid_w) cost_reg[3] <= cost_out_w;
                end

                S_COMPARE: begin
                    best_delta <= best_delta + d_offset[final_min_idx];
                    if(iter_cnt != ITER_NUM - 1) begin
                        iter_cnt <= iter_cnt + 8'd1;
                    end
                end
                
                S_EVAL_FINAL: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        mux_ti_0[i] <= apply_offset(ti_init_array[i], best_delta);
                    end
                    mux_valid_0 <= 1'b1;
                end

                S_WAIT_FINAL: begin
                    if(w_a_valid) begin
                        final_a       <= w_a_out;
                        final_a_valid <= 1'b1;
                    end
                    if(w_b_valid) begin
                        final_b       <= w_b_out;
                        final_b_valid <= 1'b1;
                    end
                    if(w_c_valid) begin
                        final_c       <= w_c_out;
                        final_c_valid <= 1'b1;
                    end
                end

                S_DONE: begin
                    for(i = 0; i < 2*`MVT_CHANNEL; i = i + 1) begin
                        ti_out[i] <= apply_offset(ti_init_array[i], best_delta);
                    end
                    ti_valid_out <= 1'b1;
                end

                default: ;
            endcase
        end
    end

endmodule