`include "VgaUtils.v"

module VgaController (
   input  wire       clk,
   input  wire [2:0] rgb_in,
   output wire [2:0] rgb_out,
   output wire       h_sync,
   output wire       v_sync,
   output wire [31:0] hpos,
   output wire [31:0] vpos
);

   reg [31:0] hcount = 0;
   reg [31:0] vcount = 0;

   wire should_reset_vcount;
   wire should_reset_hcount;
   wire should_output_data;

   assign should_reset_vcount = (vcount == `VLINE_END);
   assign should_reset_hcount = (hcount == `HLINE_END);
	
   assign should_output_data  = (hcount >= `HDATA_BEGIN) && (hcount < `HDATA_END) && 
                                (vcount >= `VDATA_BEGIN) && (vcount < `VDATA_END);

   assign h_sync  = (hcount > `HSYNC_END) ? 1'b1 : 1'b0;
   assign v_sync  = (vcount > `VSYNC_END) ? 1'b1 : 1'b0;
   assign rgb_out = should_output_data ? rgb_in : 3'b000;
	
   assign hpos    = hcount;
   assign vpos    = vcount;

   // Horizontal counter
   always @(posedge clk) 
	begin
      if (should_reset_hcount) begin
         hcount <= 0;
      end else begin
         hcount <= hcount + 1;
      end
   end

   // Vertical Counter (synchronized with the horizontal reset)
   always @(posedge clk) 
	begin
      if (should_reset_hcount) begin
         if (should_reset_vcount) begin
            vcount <= 0;
         end else begin
            vcount <= vcount + 1;
         end
      end
   end

endmodule