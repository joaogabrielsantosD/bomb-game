module ClockDivider 
#(
   parameter divide_by = 1000000 // 1E6
) 
(
   input  wire clk_in,
   output wire clk_out
);

   reg [31:0] count = 0;
   reg        output_reg = 1'b0;
   wire       should_reset;

   assign should_reset = (count == divide_by);
   assign clk_out      = output_reg;

   always @(posedge clk_in) 
	begin
		if (should_reset) begin
			count      <= 0;
         output_reg <= ~output_reg;
      end else begin
         count <= count + 1;
      end
   end

endmodule