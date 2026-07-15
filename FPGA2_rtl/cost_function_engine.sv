// -----------------------------------------------------------------------------
// Author       : lib
// Date         : 2026-04-10
// Description  : Cost Function Engine 
//                Calculates SSE based on inputs:
//                F = Sum( (a + b*ti + c*ln_ti - ln_vi)^2 )
//                Pipeline Delay Alignment 4 Stages
// -----------------------------------------------------------------------------

module cost_function_engine #(
    parameter NUM_POINTS = 32,
    parameter ACC_WIDTH  = 69
)(
    input                               clk,
    input                               rst_n,
    input                               start,
    output reg                          done,
    output reg   [ACC_WIDTH-1:0]        cost_out, 

    input  wire signed [31:0]           a,        // Q24
    input  wire signed [31:0]           b,        // Q24
    input  wire signed [31:0]           c,        // Q24

    input       [NUM_POINTS-1:0][17:0]  ti,       // Q8
    input       [NUM_POINTS-1:0][27:0]  ln_ti,    // Q24
    input       [NUM_POINTS-1:0][27:0]  ln_vi     // Q24
);

    localparam PIPE_DEPTH = 4; 

    reg [$clog2(NUM_POINTS):0]   fetch_cnt;
    reg [$clog2(NUM_POINTS)-1:0] idx;

    reg                          run_busy;
    reg [PIPE_DEPTH-1:0]         pipe_vld;


    wire signed [17:0] s0_ti;
    wire signed [27:0] s0_ln_ti;
    wire signed [27:0] s0_ln_vi;

    assign s0_ti    = ti[idx];
    assign s0_ln_ti = ln_ti[idx];
    assign s0_ln_vi = ln_vi[idx];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_cnt <= 0;
            idx       <= 0;
            run_busy  <= 1'b0;
            pipe_vld  <= 0;
        end else begin
            if (start) begin
                fetch_cnt <= 0;
                idx       <= 0;
                run_busy  <= 1'b1;
                pipe_vld  <= 0;
            end else if (run_busy) begin
                if (fetch_cnt < NUM_POINTS) begin
                    pipe_vld[0] <= 1'b1;
                    fetch_cnt   <= fetch_cnt + 1;
                    
                    if (idx < NUM_POINTS - 1) begin
                        idx <= idx + 1;
                    end
                end else begin
                    pipe_vld[0] <= 1'b0;
                end
                
                if (fetch_cnt == NUM_POINTS && pipe_vld == 0) begin
                    run_busy <= 1'b0;
                end
            end else begin
                pipe_vld[0] <= 1'b0;
            end
            

            pipe_vld[PIPE_DEPTH-1:1] <= pipe_vld[PIPE_DEPTH-2:0];
        end
    end


    wire signed [49:0] term_b_ti;    // Q24 * Q8 = Q32
    wire signed [59:0] term_c_ln_ti; // Q24 * Q24 = Q48

    // Instance: b * ti 
    multi_32x18bit_sign u_mul_b_ti (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),      
        .dataa  ( b ),           
        .datab  ( s0_ti ),       
        .result ( term_b_ti )    
    );

    // Instance: c * ln_ti 
    multi_32x28bit_sign u_mul_c_ln (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( c ),           
        .datab  ( s0_ln_ti ),    
        .result ( term_c_ln_ti ) 
    );

    //delay 1 cycle
    reg signed [27:0] dly_ln_vi;
    reg signed [31:0] dly_a;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dly_ln_vi <= 0;
            dly_a     <= 0;
        end else begin
            dly_ln_vi <= s0_ln_vi;
            dly_a     <= a;
        end
    end


    reg signed [31:0] s2_sum; // Q24

    wire              s2_vld     = pipe_vld[0];
    wire signed [31:0] a_ext      = dly_a;
    wire signed [31:0] b_ti_ext   = term_b_ti >>> 8;     // Q32 -> Q24
    wire signed [31:0] c_lnti_ext = term_c_ln_ti >>> 24; // Q48 -> Q24
    wire signed [31:0] ln_vi_ext  = dly_ln_vi;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_sum <= 0;
        end else if (s2_vld) begin
            s2_sum <= a_ext + b_ti_ext + c_lnti_ext - ln_vi_ext;
        end
    end


    wire signed [63:0] s3_square_raw; // Q16 * Q16 = Q32

    multi_32x32bit_sign u_mul_square (
        .clock  ( clk ),
        .aclr   ( ~rst_n ),
        .dataa  ( s2_sum ),
        .datab  ( s2_sum ),
        .result ( s3_square_raw )
    );


    reg  [ACC_WIDTH-1:0] acc_reg;
    
    wire s4_vld = pipe_vld[2]; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg  <= 0;
            cost_out <= 0;
            done     <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start) begin
                acc_reg  <= 0;
            end else if (run_busy) begin
                if (s4_vld) begin
                    acc_reg <= acc_reg + s3_square_raw[63:0];
                end
                
                if (pipe_vld[3] && !pipe_vld[2]) begin
                    cost_out <= acc_reg; // Q48
                    done     <= 1'b1;
                end
            end
        end
    end

endmodule
