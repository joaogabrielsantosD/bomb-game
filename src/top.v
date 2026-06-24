module top (
	input clock,
	input rst_n,
	input ir,
	output [1:0] selection,
	output [1:0] st,
	output [3:0] dig,
	output [7:0] seg
);

ir_verilog ir_verilog_inst (
	.clk(clock),
	.rst_n(rst_n),
	.IR(ir),
	.led_cs(dig),
	.led_db(seg),
	.select(selection),
	.state(st)
);


endmodule