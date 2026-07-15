// Author: lib
// Date: 2026-03-13
// Description:  Parameterized corresponding to k1-k3, j1-j3, h2-h3, s1-s3.
`include "./param.v"
module signal_rebuild_cost(
    input 	                           clk_200m,
    input 	                           reset_200m,
    input        [2*(`MVT_CHANNEL)-1:0][17:0] ti,
    input 	                           ti_valid,
    input   [`MVT_CHANNEL-1:0][15:0]    v_threshold,
    //input                                    v_enable,

    output wire signed [64 + $clog2(2*(`MVT_CHANNEL)) -1 : 0]  cost_out,
    output                                       cost_valid,
    output wire signed [31:0]                        a_out,
    output wire signed [31:0]                        b_out,
    output wire signed [31:0]                        c_out,
    output wire                                      a_valid_out,
    output wire                                      b_valid_out,
    output wire                                      c_valid_out
);


    localparam WIDTH_28 = 28 + $clog2(2*(`MVT_CHANNEL));
    localparam WIDTH_18 = 18 + $clog2(2*(`MVT_CHANNEL));
    localparam WIDTH_34 = 34 + $clog2(2*(`MVT_CHANNEL));
    localparam WIDTH_32 = 32 + $clog2(2*(`MVT_CHANNEL));
    localparam WIDTH_38 = 38 + $clog2(2*(`MVT_CHANNEL));
    localparam WIDTH_44 = 44 + $clog2(2*(`MVT_CHANNEL));

    //=====================================================
    // step 1: cal fitted sum，Qx.24
    //=====================================================

    //localparam ln_10 = 16'h24D8; // Q4.12
    localparam ln_10 = 28'h24D7637; // ln(10) = 2.302585093,Q4.24 
    integer i;

    reg [`MVT_CHANNEL-1:0] [15:0] v;
    always @ (*)
    begin
        if(!reset_200m)
        begin
            v = 'd0;
        end
        else 
        begin
            for(i = 0; i < `MVT_CHANNEL; i = i+1) begin
                v[i][15:0] = v_threshold[i][15:0];
            end
        end
    end

    wire signed [2*(`MVT_CHANNEL)-1:0][27:0] ln_ti;//Q4.24
    reg  [2*(`MVT_CHANNEL)-1:0][27:0] ln_vi;//Q4.24
    wire ln_vi_ln_ti_valid;
    ln_ti_ln_vi_cal #(
        .NUM_INSTANCES(`MVT_CHANNEL)
    ) ln_ti_ln_vi_cal_inst (
        .clk_200m(clk_200m),
        .reset_200m(reset_200m),
        .data_en(ti_valid),
        .ti(ti),
        .vi(v),
        .ln_vi(ln_vi),
        .valid(ln_vi_ln_ti_valid),
        .ln_ti(ln_ti)
    );


    wire [WIDTH_28-1:0] k1, h3;//Qx.24
    wire k1_valid;

    ln_ti_sum ln_ti_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .ln_ti         (ln_ti),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (k1_valid),
        .ln_ti_sum     (k1)   
    );


    wire [WIDTH_38-1:0] k2, j3;//Qx.24
    wire k2_valid;

    ti_ln_ti_sum ti_ln_ti_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (k2_valid),
        .ti            (ti),
        .ln_ti         (ln_ti),
        .sum           (k2)
    );


    wire [WIDTH_32-1:0] k3;//Qx.24
    wire k3_valid;

    ln_ti_ln_ti_sum ln_ti_ln_ti_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (k3_valid),
        .ln_ti         (ln_ti),
        .sum           (k3) 
    );

    assign j3 = k2;
    assign h3 = k1;


    wire [WIDTH_18-1:0] j1_temp;//Qx.8
    wire [WIDTH_34-1:0] j1, h2; // for Qx.24
    assign j1 = {j1_temp, 16'b0};
    wire j1_valid;

    ti_sum ti_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .ti_valid      (ti_valid),
        .valid_out     (j1_valid),
        .t             (ti),
        .t_sum         (j1_temp)
    );

    assign h2 = j1;

    wire [WIDTH_44-1:0] j2;
    wire j2_valid;

    ti_ti_cal ti_ti_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ti_valid),
        .valid_out     (j2_valid),
        .ti            (ti),
        .sum           (j2)
    );


    wire [WIDTH_28-1:0] s1;
    wire s1_valid;

    ln_vi_sum ln_vi_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (s1_valid),
        .ln_vi         (ln_vi),
        .sum           (s1)
    );

    wire [WIDTH_38-1:0] s2;
    wire s2_valid;

    ln_vi_ti_sum ln_vi_ti_sum_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (s2_valid),
        .ln_vi         (ln_vi),
        .ti            (ti),
        .sum           (s2)
    );
    
    wire [WIDTH_32-1:0] s3;
    wire s3_valid;

    ln_vi_ln_ti_sum ln_vi_ln_ti_sum_inst(
        .ln_vi         (ln_vi),
        .ln_ti         (ln_ti),
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .valid_in      (ln_vi_ln_ti_valid),
        .valid_out     (s3_valid),
        .sum           (s3)
    );

    //=====================================================
    // step 2: update coef, output Qx.24
    //=====================================================

    wire signed [31:0] k3_new;
    wire k3_new_valid;

    k3_cal #(
        .K3_W(WIDTH_32),
        .H3_W(WIDTH_28),
        .K1_W(WIDTH_28)
    ) k3_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .k3            (k3),
        .h3            (h3),
        .k1            (k1),
        .k3_valid      (k3_valid),
        .h3_valid      (k1_valid),
        .k1_valid      (k1_valid),
        .o_valid       (k3_new_valid),
        .k3_new        (k3_new)
    );


    wire signed [31:0] k2_new;
    wire k2_new_valid;

    k2_cal #(
        .K2_W(WIDTH_38),
        .H2_W(WIDTH_34),
        .K1_W(WIDTH_28)
    ) k2_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .k2            (k2),
        .h2            (h2),
        .k1            (k1),
        .k2_valid      (k2_valid),
        .h2_valid      (j1_valid),
        .k1_valid      (k1_valid),
        .o_valid       (k2_new_valid),
        .k2_new        (k2_new)
    );


    wire signed [31:0] j3_new;
    wire j3_new_valid;

    j3_cal #(
        .J3_W(WIDTH_38),
        .H3_W(WIDTH_28),
        .J1_W(WIDTH_34)
    ) j3_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .j3            (j3),
        .h3            (h3),
        .j1            (j1),
        .j3_valid      (k2_valid),
        .h3_valid      (k1_valid),
        .j1_valid      (j1_valid),
        .o_valid       (j3_new_valid),
        .j3_new        (j3_new)
    );


    wire signed [31:0] j2_new;
    wire j2_new_valid;

    j2_cal #(
        .J2_W(WIDTH_44),
        .H2_W(WIDTH_34),
        .J1_W(WIDTH_34)
    ) j2_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .j2            (j2),
        .h2            (h2),
        .j1            (j1),
        .j2_valid      (j2_valid),
        .h2_valid      (j1_valid),
        .j1_valid      (j1_valid),
        .o_valid       (j2_new_valid),
        .j2_new        (j2_new)
    );

    wire signed [31:0] s3_new;
    wire s3_new_valid;

    s3_cal #(
        .S3_W(WIDTH_32),
        .H3_W(WIDTH_28),
        .S1_W(WIDTH_28)
    ) s3_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .s3            (s3),
        .h3            (h3),
        .s1            (s1),
        .s3_valid      (s3_valid),
        .h3_valid      (k1_valid),
        .s1_valid      (s1_valid),
        .o_valid       (s3_new_valid),
        .s3_new        (s3_new)
    );


    wire signed [31:0] s2_new;
    wire s2_new_valid;

    s2_cal #(
        .S2_W(WIDTH_38),
        .H2_W(WIDTH_34),
        .S1_W(WIDTH_28)
    ) s2_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .s2            (s2),
        .h2            (h2),
        .s1            (s1),
        .s2_valid      (s2_valid),
        .h2_valid      (j1_valid),
        .s1_valid      (s1_valid),
        .o_valid       (s2_new_valid),
        .s2_new        (s2_new)
    );

    //=====================================================
    // step 3: final coef cal, output Qx.24
    //=====================================================

    wire signed [31:0] k3_final;
    wire k3_final_valid;

    k3_final_cal k3_final_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .k3_new        (k3_new),
        .j3_new        (j3_new),
        .k2_new        (k2_new),
        .j2_new        (j2_new),
        .k3_new_valid  (k3_new_valid),
        .j3_new_valid  (j3_new_valid),
        .k2_new_valid  (k2_new_valid),
        .j2_new_valid  (j2_new_valid),   
        .o_valid       (k3_final_valid),
        .k3_final      (k3_final)
    );

    wire signed [31:0] s3_final;
    wire s3_final_valid;

    s3_final_cal s3_final_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .s3_new        (s3_new),
        .j3_new        (j3_new),
        .s2_new        (s2_new),
        .j2_new        (j2_new),
        .s3_new_valid  (s3_new_valid),
        .j3_new_valid  (j3_new_valid),
        .s2_new_valid  (s2_new_valid),
        .j2_new_valid  (j2_new_valid), 
        .o_valid       (s3_final_valid),
        .s3_final      (s3_final)
    );

    //=====================================================
    // step 4: cal a, b, c, output Qx.24
    //=====================================================

    wire signed [31:0] c;
    wire c_valid;

    c_cal c_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .s3_final      (s3_final),
        .k3_final      (k3_final),
        .s3_final_valid(s3_final_valid),
        .k3_final_valid(k3_final_valid),
        .o_valid       (c_valid),
        .c             (c)
    );

    wire signed [31:0] b;
    wire b_valid;

    b_cal b_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),
        .s2_new        (s2_new),
        .k2_new        (k2_new),
        .c             (c),
        .j2_new        (j2_new),
        .s2_new_valid  (s2_new_valid),
        .k2_new_valid  (k2_new_valid),
        .c_valid       (c_valid),
        .j2_new_valid  (j2_new_valid),
        .o_valid       (b_valid),
        .b             (b)
    );

    wire signed [31:0] a;
    wire a_valid;

    a_cal #(
        .S1_W(WIDTH_28),
        .J1_W(WIDTH_34),
        .K1_W(WIDTH_28)
    ) a_cal_inst(
        .clk_200m      (clk_200m),
        .reset_200m    (reset_200m),    
        .s1            (s1),
        .j1            (j1),
        .k1            (k1),
        .c             (c),
        .b             (b),
        .s1_valid      (s1_valid),
        .j1_valid      (j1_valid),
        .k1_valid      (k1_valid),
        .c_valid       (c_valid),
        .b_valid       (b_valid),
        .o_valid       (a_valid),
        .a             (a)
    );


    assign a_out       = a;
    assign b_out       = b;
    assign c_out       = c;
    assign a_valid_out = a_valid;
    assign b_valid_out = b_valid;
    assign c_valid_out = c_valid;

    //=====================================================
    // step 5: cost engine
    //=====================================================

    cost_function_engine #(
        .ACC_WIDTH(64 + $clog2(2*(`MVT_CHANNEL))),
        .NUM_POINTS(2*(`MVT_CHANNEL))
    ) cost_function_engine_inst (
        .clk           (clk_200m),
        .rst_n         (reset_200m),
        .a             (a),
        .b             (b),
        .c             (c),
        .start         (a_valid), 
        .ti            (ti), 
        .ln_ti         (ln_ti),
        .ln_vi         (ln_vi),
        .done          (cost_valid), 
        .cost_out      (cost_out)  
    );


endmodule
 

 
 
 
 
 
 
 
 
 
 
 
 
