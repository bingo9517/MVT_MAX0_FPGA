module reset_control_block
(


	input      clk_200m,

	output  reset_200m,
    output  reset_50m,
	output  reset_10m
);
	
	localparam RESET_CYCLES_WIDTH = 10; 

    reg [RESET_CYCLES_WIDTH-1:0] counter_reg = {RESET_CYCLES_WIDTH{1'b0}};
    reg por_reset_reg = 1'b0;
    assign reset_200m = por_reset_reg;
    assign reset_10m = por_reset_reg;
    assign reset_50m = por_reset_reg;

    always @(posedge clk_200m) begin
        if (por_reset_reg == 1'b0) begin
            if (&counter_reg) begin
                por_reset_reg <= 1'b1;
            end
            else begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end


	
	
endmodule
	