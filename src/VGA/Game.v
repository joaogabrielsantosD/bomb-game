`include "VgaUtils.v"

module Game 
#(
   parameter difficult = 2'b00
)
(
    input  wire       clk,    // Pin 23, 50MHz
    output wire [2:0] rgb,    // Pins 106, 105, 104
    output wire       h_sync, // Pin 101
    output wire       v_sync, // Pin 103
    input  wire       up,
    input  wire       down,
    input  wire       left,
    input  wire       right,
    input 		[1:0] game_mode,
    input             check_bomb,

    output reg  [3:0] record_t,
    output reg  [3:0] record_u,

    output reg  [3:0] points_t,
    output reg  [3:0] points_u
);

    localparam DIFFICULT_LEVEL = difficult == 2'b00 ? `COLOR_YELLOW : 
                                 difficult == 2'b01 ? `COLOR_WATER  : 
                                 difficult == 2'b10 ? `COLOR_PURPLE : `COLOR_BLACK;

	localparam BOMB_SQUARE_SIZE = 15;

    reg [15:0] lfsr_x = 16'hACE1;
    reg [15:0] lfsr_y = 16'hBEEF;
 
    wire lfsr_x_fb = lfsr_x[15] ^ lfsr_x[13] ^ lfsr_x[12] ^ lfsr_x[10];
    wire lfsr_y_fb = lfsr_y[15] ^ lfsr_y[14] ^ lfsr_y[12] ^ lfsr_y[3];

    always @(posedge clk) 
    begin
        lfsr_x <= {lfsr_x[14:0], lfsr_x_fb};
        lfsr_y <= {lfsr_y[14:0], lfsr_y_fb};
    end
 
    reg [31:0] bomb_x = `HDATA_BEGIN + `H_HALF - (BOMB_SQUARE_SIZE / 2);
    reg [31:0] bomb_y = `VDATA_BEGIN + `V_HALF - (BOMB_SQUARE_SIZE / 2);
	 
	 reg [31:0] pos_x = 0;
	 reg [31:0] pos_y = 0;

    localparam SQUARE_SIZE  = 30;
    localparam SQUARE_SPEED = 100000;
	
    localparam LINE_SPACING   = 40;
    localparam LINE_THICKNESS = 4;

    reg        vga_clk = 1'b0;
    reg  [2:0] rgb_input;
    wire [2:0] rgb_output;
    wire       vga_h_sync;
    wire       vga_v_sync;
    wire [31:0] hpos;
    wire [31:0] vpos;

    // Centered initial positions based on VgaUtils macros
    reg [31:0] square_x = `HDATA_BEGIN + `H_HALF - (SQUARE_SIZE / 2);
    reg [31:0] square_y = `VDATA_BEGIN + `V_HALF - (SQUARE_SIZE / 2);
    reg [31:0] square_speed_count = 0;
    
	wire [31:0] vline_index = (hpos - `HDATA_BEGIN) / LINE_SPACING;
    wire [31:0] hline_index = (vpos - `VDATA_BEGIN) / LINE_SPACING;

    wire move_square_en;
    wire should_move_square;
    wire should_draw_square;
    wire should_draw_bomb;
    wire should_draw_vline;
    wire should_draw_hline;

    wire on_bomb;

    VgaController controller (
        .clk(vga_clk),
        .rgb_in(rgb_input),
        .rgb_out(rgb_output),
        .h_sync(vga_h_sync),
        .v_sync(vga_v_sync),
        .hpos(hpos),
        .vpos(vpos)
    );

    assign rgb   = rgb_output;
    assign h_sync = vga_h_sync;
    assign v_sync = vga_v_sync;

    // Combinational logic
    assign move_square_en     = up ^ down ^ left ^ right;
    assign should_move_square = (square_speed_count == SQUARE_SPEED);
	
    // Macro call simulating the VHDL procedure
    assign should_draw_square = (game_mode != 2'b00) && (game_mode != 2'b01) && `SQUARE_DRAW(hpos, vpos, square_x, square_y, SQUARE_SIZE);

    assign should_draw_bomb   = (game_mode != 2'b00) && (game_mode != 2'b01) && `SQUARE_DRAW(hpos, vpos, bomb_x, bomb_y, BOMB_SQUARE_SIZE);

    assign should_draw_vline  = (game_mode == 2'b00) && `VGRID_LINES(hpos, vpos, LINE_SPACING, LINE_THICKNESS);

    assign should_draw_hline  = (game_mode == 2'b01) && `HGRID_LINES(hpos, vpos, LINE_SPACING, LINE_THICKNESS);
	
    assign on_bomb = (square_x < bomb_x + SQUARE_SIZE) && (square_x + SQUARE_SIZE > bomb_x) && 
                     (square_y < bomb_y + SQUARE_SIZE) && (square_y + SQUARE_SIZE > bomb_y);

    // Divide-by-2 clock divider (Generation of 25 MHz VGA clock from 50 MHz)
    always @(posedge clk) 
    begin
        vga_clk <= ~vga_clk;
    end

    always @(posedge check_bomb) 
    begin
         if (on_bomb) begin
            if (points_u < 4'd9) begin
                points_u <= points_u + 1;
            end else begin
                points_u <= 4'd0;
                if (points_t < 4'd9)
                    points_t <= points_t + 1;
                else
                    points_t <= 4'd9;
            end
        end else begin
            if ((points_t > record_t) || ((points_t == record_t) && (points_u > record_u))) begin
                record_t <= points_t;
                record_u <= points_u;
            end
            
            points_t <= 4'd0;
            points_u <= 4'd0;
        end

		pos_x  <= `HDATA_BEGIN + (lfsr_x % (`H_SIZE - SQUARE_SIZE));
        bomb_x <= pos_x >= (`HDATA_END - SQUARE_SIZE) ? `HDATA_END - SQUARE_SIZE : pos_x <= `HDATA_BEGIN ? `HDATA_BEGIN : pos_x;

        pos_y  <=  `VDATA_BEGIN + (lfsr_y % (`V_SIZE - SQUARE_SIZE));
        bomb_y <= pos_y >= (`VDATA_END - SQUARE_SIZE) ? `VDATA_END - SQUARE_SIZE : pos_x <= `VDATA_BEGIN ? `VDATA_BEGIN : pos_y;
    end

    // Color assignment logic (Pixel)
    always @(posedge vga_clk) begin
        if (should_draw_square) begin
            rgb_input <= `COLOR_GREEN;
        end else if (should_draw_bomb) begin
            rgb_input <= DIFFICULT_LEVEL;
        end else if (should_draw_vline) begin
		    case (vline_index % 4)
                0 : rgb_input <= `COLOR_RED;
                1 : rgb_input <= `COLOR_GREEN;
                2 : rgb_input <= `COLOR_BLUE;
                3 : rgb_input <= `COLOR_WHITE;
            endcase
        end else if (should_draw_hline) begin
            case (hline_index % 4)
	            0 : rgb_input <= `COLOR_RED;
                1 : rgb_input <= `COLOR_GREEN;
                2 : rgb_input <= `COLOR_BLUE;
                3 : rgb_input <= `COLOR_WHITE;
			endcase
        end else begin
            rgb_input <= `COLOR_BLACK;
        end
    end

    // Logic for updating the square's speed and position
    always @(posedge vga_clk)
    begin
        if (move_square_en && (game_mode != 2'b00) && (game_mode != 2'b01)) begin
            if (should_move_square) begin
                square_speed_count <= 0;
            end else begin
                square_speed_count <= square_speed_count + 1;
            end
        end else begin
            square_speed_count <= 0;
        end

        if (should_move_square && (game_mode != 2'b00) && (game_mode != 2'b01)) begin
            // UP Movement (Active in 0)
            if (up) begin
                if (square_y <= `VDATA_BEGIN) begin
                    square_y <= `VDATA_BEGIN;
                end else begin
                    square_y <= square_y - 1;
                end
            end

            // DOWN Movement (Active in 0)
            if (down) begin
                if (square_y >= `VDATA_END - SQUARE_SIZE) begin
                    square_y <= `VDATA_END - SQUARE_SIZE;
                end else begin
                    square_y <= square_y + 1;
                end
            end

            // LEFT Movement (Active in 0)
            if (left) begin
                if (square_x <= `HDATA_BEGIN) begin
                    square_x <= `HDATA_BEGIN;
                end else begin
                    square_x <= square_x - 1;
                end
            end

            // RIGHT Movement (Active in 0)
            if (right) begin
                if (square_x >= `HDATA_END - SQUARE_SIZE) begin
                    square_x <= `HDATA_END - SQUARE_SIZE;
                end else begin
                    square_x <= square_x + 1;
                end
            end
		end
    end

endmodule