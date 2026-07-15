// Author: lib
// Date: 2025-12-02
// Description: Asynchronous FIFO with Data Valid indicator.

module async_fifo #(
  parameter WIDTH_D = 25,
  parameter DEPTH = 16,
  parameter WIDTH_A = 4
)(
  input w_clk,
  input rst_n,
  input w_req,
  input [WIDTH_D-1 : 0] w_data,

  input r_clk,
  input r_req,
  output [WIDTH_D-1 : 0] r_data,
  output w_full,
  output r_empty,
  output reg r_data_valid 
);

wire [WIDTH_A : 0] w_addr;
wire [WIDTH_A : 0] w_gaddr;
wire [WIDTH_A : 0] w_gaddr_syn;
wire [WIDTH_A : 0] r_addr;
wire [WIDTH_A : 0] r_gaddr;
wire [WIDTH_A : 0] r_gaddr_syn;
wire read_allow;
  
assign read_allow = r_req & !r_empty;
always @(posedge r_clk or negedge rst_n) begin
  if (!rst_n) 
    r_data_valid <= 1'b0;
  else 
    r_data_valid <= read_allow;
end

write_part #(
  .WIDTH_A(WIDTH_A)
)write_control(
  .w_clk(w_clk),
  .w_rst(rst_n),
  .w_req(w_req),
  .r_gaddr(r_gaddr_syn),
  .w_full(w_full),
  .w_addr(w_addr),
  .w_gaddr(w_gaddr)
);


syn #(
 .WIDTH_D(WIDTH_A) 
) syn_w_2_r(
  .syn_clk(r_clk),
  .syn_rst(rst_n),
  .data_in(w_gaddr),
  .syn_data(w_gaddr_syn)
);

syn #(
 .WIDTH_D(WIDTH_A) 
) syn_r_2_w(
  .syn_clk(w_clk),
  .syn_rst(rst_n),
  .data_in(r_gaddr),
  .syn_data(r_gaddr_syn)
);


read_part #(
  .WIDTH_A(WIDTH_A)
)read_control(
  .r_clk(r_clk),
  .r_rst(rst_n),
  .r_req(r_req),
  .w_gaddr(w_gaddr_syn),
  .r_empty(r_empty),
  .r_addr(r_addr),
  .r_gaddr(r_gaddr)
);

  dp_ram #(
  .RAM_DEPTH(DEPTH), 
  .RAM_WIDTH(WIDTH_D), 
  .ADDR_WIDTH(WIDTH_A)
  ) U_RAM (
    .read_clock(r_clk),
    .write_clock(w_clk),
    .read_allow(read_allow), 
    .write_allow(w_req & !w_full),
    .read_addr(r_addr),
    .write_addr(w_addr),
    .write_data(w_data),
    .read_data(r_data)
  );

endmodule







module bin_to_gray #(
parameter WIDTH_D = 5
)(
  input [WIDTH_D-1 : 0] bin_c,
  output [WIDTH_D-1 : 0] gray_c
);

wire h_b;
assign h_b = bin_c[WIDTH_D-1];
reg [WIDTH_D-2 : 0] gray_c_d;
integer i;

always @(*) begin 
  for(i=0; i<WIDTH_D-1; i=i+1)
    gray_c_d[i] = bin_c[i] ^ bin_c[i+1];
end

assign gray_c = {h_b,gray_c_d};

endmodule






module dp_ram #(

parameter RAM_WIDTH = 8,
parameter RAM_DEPTH = 256,
parameter ADDR_WIDTH = 8
)(
write_clock,
read_clock,
write_allow,
read_allow,
write_addr,
read_addr,
write_data,
read_data
);

input                    write_clock;
input                    read_clock;
input                    write_allow;
input                    read_allow;
input [ADDR_WIDTH-1 : 0] write_addr;
input [ADDR_WIDTH-1 : 0] read_addr;
output [RAM_WIDTH-1 : 0] read_data;
input [RAM_WIDTH-1 : 0]  write_data;

reg [RAM_WIDTH-1 : 0] read_data;

reg [RAM_WIDTH-1 : 0] memory [RAM_DEPTH-1 : 0];

always @(posedge write_clock) begin 
  if (write_allow) 
    memory [write_addr] <=  write_data;
end

always @(posedge read_clock) begin 
  if (read_allow) 
   read_data <=   memory [read_addr];
end

endmodule





module write_part #(
 parameter WIDTH_A = 8
)(
  inout w_clk,
  input w_rst,
  input w_req,
  input [WIDTH_A : 0] r_gaddr,
  output w_full,
  output [WIDTH_A-1 : 0] w_addr,
  output reg [WIDTH_A : 0] w_gaddr
);

wire [WIDTH_A : 0] w_gaddr_r;
reg [WIDTH_A : 0] w_addr_e;

always @(posedge w_clk) begin
  if (!w_rst) 
    w_addr_e <= 'h0;
  else if (w_req && (!w_full))
    w_addr_e <= w_addr_e + 1'b1;
end

assign w_addr = w_addr_e[WIDTH_A-1 : 0];

bin_to_gray #(.WIDTH_D(WIDTH_A+1)) U2_bin_to_gray 
(
  .bin_c(w_addr_e),
  .gray_c(w_gaddr_r)
);

always @(posedge w_clk) begin
  if (!w_rst) 
    w_gaddr <= 'h0;
  else 
    w_gaddr <= w_gaddr_r;
end

assign w_full = ({~w_gaddr_r[WIDTH_A], ~w_gaddr_r[WIDTH_A-1], w_gaddr_r[WIDTH_A-2 : 0]} == r_gaddr) ? 1 : 0;

endmodule






module read_part #(
 parameter WIDTH_A = 8 
)(
  inout r_clk,
  input r_rst,
  input r_req,
  input [WIDTH_A : 0] w_gaddr,
  output r_empty,
  output [WIDTH_A-1 : 0] r_addr,
  output reg [WIDTH_A : 0] r_gaddr
);

reg [WIDTH_A : 0] r_addr_e;
wire [WIDTH_A : 0] r_gaddr_w;

always @(posedge r_clk) begin
  if (!r_rst) 
    r_addr_e <= 'h0;
  else if (r_req && (!r_empty))
    r_addr_e <= r_addr_e + 1'b1;
end

assign r_addr = r_addr_e[WIDTH_A-1 :0];

bin_to_gray #(
.WIDTH_D(WIDTH_A+1)
)
U1_bin_to_gray 
(
  .bin_c(r_addr_e),
  .gray_c(r_gaddr_w)
);

always @(posedge r_clk) begin
  if (!r_rst) 
    r_gaddr <= 'h0;
  else 
    r_gaddr <= r_gaddr_w;
end

assign r_empty = (w_gaddr == r_gaddr_w) ? 1 : 0;

endmodule







module syn #(
 parameter WIDTH_D = 5
)(
  input syn_clk,
  input syn_rst,
  input [WIDTH_D : 0] data_in,
  output [WIDTH_D : 0] syn_data
);

reg [WIDTH_D : 0] syn_reg_1, syn_reg_2;

always @(posedge syn_clk) begin
  if (!syn_rst) begin
     syn_reg_1 <= 'h0;
     syn_reg_2 <= 'h0;
  end
  else begin
     syn_reg_1 <= data_in;
     syn_reg_2 <= syn_reg_1;
  end
end

assign syn_data = syn_reg_2;

endmodule






