// VgaUtils.h

`ifndef VGA_UTILS_VH
`define VGA_UTILS_VH

// Color Settings (3 bits: R, G, B)
`define COLOR_WHITE  3'b111;
`define COLOR_YELLOW 3'b110;
`define COLOR_PURPLE 3'b101;
`define COLOR_RED    3'b100
`define COLOR_WATER  3'b011
`define COLOR_GREEN  3'b010
`define COLOR_BLUE   3'b001
`define COLOR_BLACK  3'b000

// Values ​​for 640x480 resolution
`define HSYNC_END   95
`define HDATA_BEGIN 143
`define HDATA_END   783
`define HLINE_END   799

`define VSYNC_END   1
`define VDATA_BEGIN 34
`define VDATA_END   514
`define VLINE_END   524

`define H_EIGHTH    (640 / 8)
`define H_HALF      (640 / 2)
`define H_QUARTER   (640 / 4)
`define V_EIGHTH    (480 / 8)
`define V_HALF      (480 / 2)
`define V_QUARTER   (480 / 4)

// Macro equivalent to the Square procedure
`define SQUARE_DRAW(hcur, vcur, hpos, vpos, size)  ((hcur > hpos) && (hcur < (hpos + size)) && (vcur > vpos) && (vcur < (vpos + size)))

`define VGRID_LINES(hcur, vcur, spacing, thickness) ((((hcur - `HDATA_BEGIN) % spacing) < thickness) && (vcur >= `VDATA_BEGIN) && (vcur < `VDATA_END))

`define HGRID_LINES(hcur, vcur, spacing, thickness) ((((vcur - `VDATA_BEGIN) % spacing) < thickness) && (hcur >= `HDATA_BEGIN) && (hcur < `HDATA_END))

`endif
