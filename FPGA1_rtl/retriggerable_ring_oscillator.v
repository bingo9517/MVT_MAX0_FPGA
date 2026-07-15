`include "./param.v"
module retriggerable_ring_oscillator(
/*test delay*/
/*     input   Ta_Enable_w,
    input   clk_200m,
    output  reg Tosc_r */
	input 	clk_200m,
	input 	reset_200m,
    output  reg Tosc

    );

/*test delay*/
/*     reg     Ta_Enable;
    wire    Tosc;

    always@(posedge clk_200m)begin
        Ta_Enable   <= Ta_Enable_w;
        Tosc_r      <= Tosc;
    end
    
    assign LCELL_wire[0] = Ta_Enable;
    assign Tosc          = LCELL_wire[LCELL_NUM]; */


    parameter               LCELL_NUM = `CARRYCHAIN_LENGTH;

    wire    [LCELL_NUM:0]   LCELL_wire;
	reg Tosc_r;
	always @ (*)
	begin
		if(~reset_200m)
		begin
			Tosc <= 'd0;
		end
		else
		begin
			Tosc <= ~LCELL_wire[LCELL_NUM];
		end
	end
    
	assign LCELL_wire[0] = Tosc;
    //assign Tosc = ~LCELL_wire[LCELL_NUM];

    genvar n;
    //reg [7:0] delay = 90;
    
    generate
        for(n = 0; n < LCELL_NUM; n = n + 1)
        begin: U_carry_chain
            lcell
            U_lcell
            (
                .in         (LCELL_wire[n]      ),
                //.delay      (delay),
                .out        (LCELL_wire[n+1]    )
            );
        end
    endgenerate
    


endmodule