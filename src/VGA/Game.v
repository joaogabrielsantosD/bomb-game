`include "VgaUtils.v"

module Game (
    input  wire       clk,    // Pin 23, 50MHz
    output wire [2:0] rgb,    // Pins 106, 105, 104
    output wire       h_sync, // Pin 101
    output wire       v_sync, // Pin 103
    input  wire       up,
    input  wire       down,
    input  wire       left,
    input  wire       right,
    input 		[1:0] game_mode
);

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
    wire should_draw_vline;
    wire should_draw_hline;

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

    assign should_draw_vline  = (game_mode == 2'b00) && `VGRID_LINES(hpos, vpos, LINE_SPACING, LINE_THICKNESS);

    assign should_draw_hline  = (game_mode == 2'b01) && `HGRID_LINES(hpos, vpos, LINE_SPACING, LINE_THICKNESS);
	
    // Divide-by-2 clock divider (Generation of 25 MHz VGA clock from 50 MHz)
    always @(posedge clk) 
    begin
        vga_clk <= ~vga_clk;
    end

    // Color assignment logic (Pixel)
    always @(posedge vga_clk) begin
        if (should_draw_square) begin
            rgb_input <= `COLOR_GREEN;
        end else if (should_draw_vline) begin
		    case (vline_index % 4)
                0 : rgb_input <= `COLOR_RED;
                1 : rgb_input <= `COLOR_GREEN;
                2 : rgb_input <= `COLOR_YELLOW;
                3 : rgb_input <= `COLOR_WATER;
            endcase
        end else if (should_draw_hline) begin
            case (hline_index % 4)
	            0 : rgb_input <= `COLOR_RED;
                1 : rgb_input <= `COLOR_GREEN;
                2 : rgb_input <= `COLOR_YELLOW;
                3 : rgb_input <= `COLOR_WATER;
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