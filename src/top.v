module top (
	input clock,
	input rst_n,
	
	input ir,
	output [3:0] dig,
	output [7:0] seg,
	
	output [2:0] music_sel,
	output [1:0] game_mode,
	
	output stop_music,
	
	output [2:0] vga_rgb,
	output hsync,
	output vsync,

	output [3:0] record_t,
	output [3:0] record_u,
	output [3:0] points_t,
	output [3:0] points_u
);

	wire up, down, left, right;
	wire check_bomb_cmd;
	wire h_sync;
	wire v_sync;

	ir_protocol ir_protocol_inst (
		.clk(clock),
		.rst_n(rst_n),
		.IR(ir),
		.led_cs(dig),
		.led_db(seg),	
		.sel(music_sel),
		.mode(game_mode),
		.stop_music(stop_music),
		.up_movement(up),
		.down_movement(down),
		.left_movement(left),
		.right_movement(right),
		.check_bomb_cmd(check_bomb_cmd)
	);
	
	Game game_inst (
		.clk(clock),
		.rgb(vga_rgb),
		.h_sync(h_sync),
		.v_sync(v_sync),
		.game_mode(game_mode),
		.up(up),
		.down(down),
		.left(left),
		.right(right),
		.check_bomb(check_bomb_cmd),
		.record_t(record_t),
		.record_u(record_u),
		.points_t(points_t),
		.points_u(points_u)
	);
	
	assign hsync = h_sync;
	assign vsync = v_sync;

endmodule