module top (
	input clock,
	input rst_n,
	input ir,
	output [3:0] dig,
	output [7:0] seg,
	output [2:0] music_sel,
	output stop_music
);

ir_protocol ir_protocol_inst (
	.clk(clock),
	.rst_n(rst_n),
	.IR(ir),
	.led_cs(dig),
	.led_db(seg),	
	.sel(music_sel),
	.stop_music(stop_music)
);


endmodule