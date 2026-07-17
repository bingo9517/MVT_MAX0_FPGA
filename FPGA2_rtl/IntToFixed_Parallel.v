
// Author:         lib
// Date:           2026-07-17
// Description:    Serial Int to Fixed-point converter. 

module IntToFixed_Parallel #(
    parameter QUOTIENT_WIDTH  = 8,
    parameter OPERAND_WIDTH   = 16,
    parameter FRACTIONAL_BITS = 16
)(
    input  wire                                          clk,
    input  wire                                          rst_n,
    input  wire                                          i_valid,

    input  wire signed [QUOTIENT_WIDTH-1:0]              i_quotient,
    input  wire signed [OPERAND_WIDTH-1:0]               i_remainder,
    input  wire signed [OPERAND_WIDTH-1:0]               i_divisor,

    output wire                                          o_valid,
    output wire signed [QUOTIENT_WIDTH+FRACTIONAL_BITS-1:0] o_q_out
);

    // Constant function to calculate bit width
    function integer clog2;
        input integer value;
        begin
            value = value - 1;
            for (clog2 = 0; value > 0; clog2 = clog2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction

    // Auto-calculated counter width
    localparam COUNT_WIDTH = (FRACTIONAL_BITS > 1) ? clog2(FRACTIONAL_BITS) : 1;

    // FSM States
    localparam [1:0] IDLE = 2'b00,
                     CALC = 2'b01,
                     DONE = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // Datapath Registers
    reg signed [QUOTIENT_WIDTH-1:0] r_quotient;
    reg        [OPERAND_WIDTH:0]    r_remainder;
    reg        [OPERAND_WIDTH-1:0]  r_divisor;
    reg        [FRACTIONAL_BITS-1:0] r_fractional;
    reg        [COUNT_WIDTH-1:0]    r_count;
    reg                             r_valid;

    // Negative remainder adjustment (combinational)
    wire remainder_is_negative;
    wire signed [QUOTIENT_WIDTH-1:0] adjusted_quotient;
    wire signed [OPERAND_WIDTH-1:0]  pos_remainder_calc;
    wire [OPERAND_WIDTH:0]           adjusted_remainder;

    assign remainder_is_negative = i_remainder[OPERAND_WIDTH-1];
    assign adjusted_quotient = remainder_is_negative ? (i_quotient - 1'b1) : i_quotient;
    assign pos_remainder_calc = i_remainder + i_divisor;
    assign adjusted_remainder = remainder_is_negative ? 
                                {1'b0, pos_remainder_calc} : 
                                {1'b0, i_remainder};

    // Shared ALU for serial calculation
    wire [OPERAND_WIDTH:0] shifted_rem;
    wire [OPERAND_WIDTH:0] extended_div;
    wire                   enough;

    assign shifted_rem  = r_remainder << 1;
    assign extended_div = {1'b0, r_divisor};
    assign enough       = (shifted_rem >= extended_div);

    // FSM Segment 1: State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM Segment 2: Next State Logic
    always @(*) begin
        next_state = current_state; 
        case (current_state)
            IDLE: begin
                if (i_valid) begin
                    next_state = CALC;
                end
            end
            CALC: begin
                if (r_count == (FRACTIONAL_BITS - 1)) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // FSM Segment 3: Datapath and Outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_quotient   <= {QUOTIENT_WIDTH{1'b0}};
            r_remainder  <= {(OPERAND_WIDTH+1){1'b0}};
            r_divisor    <= {OPERAND_WIDTH{1'b0}};
            r_fractional <= {FRACTIONAL_BITS{1'b0}};
            r_count      <= {COUNT_WIDTH{1'b0}};
            r_valid      <= 1'b0;
        end else begin
            r_valid <= 1'b0; 
            
            case (current_state)
                IDLE: begin
                    if (i_valid) begin
                        r_quotient   <= adjusted_quotient;
                        r_remainder  <= adjusted_remainder;
                        r_divisor    <= i_divisor;
                        r_fractional <= {FRACTIONAL_BITS{1'b0}};
                        r_count      <= {COUNT_WIDTH{1'b0}};
                    end
                end
                
                CALC: begin
                    r_count      <= r_count + 1'b1;
                    r_remainder  <= enough ? (shifted_rem - extended_div) : shifted_rem;
                    r_fractional <= {r_fractional[FRACTIONAL_BITS-2:0], enough};
                end
                
                DONE: begin
                    r_valid <= 1'b1;
                end
            endcase
        end
    end

    // Output Assignment
    assign o_valid = r_valid;
    assign o_q_out = {r_quotient, r_fractional};

endmodule