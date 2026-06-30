module ir_protocol (
  input clk,
  input rst_n,
  input IR,
  output reg [3:0] led_cs,
  output reg [7:0] led_db,
  output reg [2:0] sel,
  output reg [1:0] mode,
  output reg stop_music
);
  
  reg [7:0]  led1, led2, led3, led4;    // represents each 7-segment display
  reg [15:0] irda_data;                 // stores the IrDA data and then sends it to the 7-segment displays
  reg [31:0] get_data;                  // stores the 32 bits of IrDA data
  reg [5:0]  data_cnt;                  // counter for the 32 bits of the IrDA data
  reg [2:0]  current_state, next_state; // FSM state registers
  reg error_flag;                       // Error flag during the 32 bits of IrDA data.

  reg irda_reg0;     // unstable value
  reg irda_reg1;     // receives irda_reg0 for stabilization
  reg irda_reg2;     // receives irda_reg1, helps determine the IrDA edge
  wire irda_negedge; // determines the falling edge of the IrDA signal
  wire irda_posedge; // determines the IrDA rising edge
  wire irda_change;  // determines the IrDA edge transition

  reg received_packet;
  // reg [7:0] cmd_value;
   
	always @(posedge clk) 
  begin
    if (!rst_n)
      received_packet <= 1'b0;
    else
      received_packet <= (current_state == DATA_STATE) && 
                         (next_state == IDLE_STATE)    && 
                         (data_cnt == 6'd32)           && 
                         !error_flag;
  end
	
  always @(posedge clk) // synchronizes the irda registers
  begin
    if(!rst_n) begin     // Asynchronous reset of IrDA registers
      irda_reg0 <= 1'b0; // clears the irda_reg0 register
      irda_reg1 <= 1'b0; // clears the irda_reg1 register
      irda_reg2 <= 1'b0; // clears the irda_reg2 register
    end else begin
      //led_current_state <= 4'b0000; // updates the IrDA registers on the rising edge of the CLK
      irda_reg0 <= IR;                // receives the value read via IRDA
      irda_reg1 <= irda_reg0;         // updates with a stable value
      irda_reg2 <= irda_reg1;         // updates while ensuring a stable income tax value
    end
  end
     
  assign irda_change = irda_negedge | irda_posedge; // assigns 1 on an IrDA edge transition
  assign irda_negedge = irda_reg2 & (~irda_reg1);   // assigns 1 on the falling edge of IrDA
  assign irda_posedge = (~irda_reg2) & irda_reg1;   // assigns 1 on the falling edge of IrDA

  reg [10:0] cnt1;      // Divide-by-1750 frequency divider
  reg [8:0]  cnt2;      // counts the number of points after cnt1
  wire verify_900us;    // verifies the duration of 9ms = 900µs
  wire verify_450us;    // verifies the duration of 4.5 ms = 450 µs
  
  // Logic '1' – a 562.5 µs pulse burst followed by a 1.6875 ms space, with a total transmission time of 2.25 ms.
  wire high;            // check date="1"
  
  // Logic '0' – a 562.5 µs pulse burst followed by a 562.5 µs space, with a total transmission time of 1.125 ms.
  wire low;             // check date="0"


  always @(posedge clk)
  begin
    if (!rst_n)                // asynchronous reset
      cnt1 <= 11'd0;           // resets counter 1
    else if (irda_change)      // at the IrDA edge transition
      cnt1 <= 11'd0;           // resets counter 1
    else if (cnt1 == 11'd1750) // in case the counter overflows
      cnt1 <= 11'd0;           // resets counter 1
    else
      cnt1 <= cnt1 + 1'b1;     // increments the counter by 1
  end

  always @(posedge clk)
  begin     
    if (!rst_n)                // asynchronous reset
      cnt2 <= 9'd0;            // reset counter 2
    else if (irda_change)      // at the IrDA edge transition
      cnt2 <= 9'd0;            // reset counter 2
    else if (cnt1 == 11'd1750) // 1750 pulses at low level and 1750 pulses at high level
      cnt2 <= cnt2 +1'b1;      // increments the counter 2
  end

  // Ensures stability by evaluating the count interval instead of the exact value.
  assign verify_900us = ((217 < cnt2) & (cnt2 < 297));  // expected exact value 256 
  assign verify_450us = ((88 < cnt2) & (cnt2 < 168));   // expected exact value 128  
  assign high = ((38 < cnt2) & (cnt2 < 58));            // expected exact value 48
  assign low  = ((6 < cnt2) & (cnt2 < 26));             // expected exact value 16

  localparam IDLE_STATE  = 3'b000, // initial state
             DELAY_900us = 3'b001, // delay of 900us
             DELAY_450us = 3'b010, // delay of 450us
             DATA_STATE  = 3'b100; // data transfer state
 
  // FSM logic for current state control (sequential)
  always @(posedge clk)
  begin
    if (!rst_n) // asynchronous reset
      current_state <= IDLE_STATE; // restarts the FSM
    else
      current_state <= next_state; // updates the current state
  end
  
  // FSM Lógica para controle do estado atual (combinacional)
  always @(*)
  begin
    case (current_state)
      IDLE_STATE:
        if (~irda_reg1)
          next_state = DELAY_900us;
        else 
          next_state = IDLE_STATE;
   
      DELAY_900us:
        if (irda_posedge) begin
          if (verify_900us)
            next_state = DELAY_450us;
          else
            next_state = IDLE_STATE;
        end else  // 
          next_state = DELAY_900us;
   
      DELAY_450us:
        if (irda_negedge) begin
          if (verify_450us)
            next_state = DATA_STATE;
          else
            next_state = IDLE_STATE;
          end else // prevents latch inference
            next_state = DELAY_450us;
   
      DATA_STATE:
        if ((data_cnt == 6'd32) & irda_reg2 & irda_reg1) // checks if the 32 bits were received
          next_state = IDLE_STATE;
        else if (error_flag)       // in case there is an error in the IRDA data
          next_state = IDLE_STATE;
        else
          next_state = DATA_STATE;

      default: next_state = IDLE_STATE;
    endcase
  end

  // FSM logic for output control
  always @(posedge clk)
  begin
    if (!rst_n) begin
      data_cnt <= 6'd0;   // resets the IrDA data bit counter
      get_data <= 32'd0;  // Clears the registers for the 32 bits of IrDA data.
      error_flag <= 1'b0; // Clears the IrDA data error flag.
    end else if (current_state == IDLE_STATE) begin
      data_cnt <= 6'd0;   // resets the IrDA data bit counter
      get_data <= 32'd0;  // Clears the registers for the 32 bits of IrDA data.
      error_flag <= 1'b0; // Clears the IrDA data error flag.
    end else if (current_state == DATA_STATE) begin
      if (irda_posedge) begin // checks if it is a rising edge
        if (!low)             // if it is not a logic low level (logic level 0, 560 µs)
          error_flag <= 1'b1; // define error flag
      end else if (irda_negedge) begin // checks if it is a falling edge
        if (low)                       // in the case of a logic low level (logic level 0, 560 µs)
          get_data[0] <= 1'b0;
        else if (high) // if logic high (logic level 1, 1680 µs)
          get_data[0] <= 1'b1;
        else
          error_flag <= 1'b1; // caso contrário, define flag de erro

        get_data[31:1] <= get_data[30:0]; // updates the data register, shifting 1 bit
        data_cnt <= data_cnt + 1'b1;      // increments the data counter
      end
    end
  end

  
  // Logic for controlling BCD7SEG displays ----------------------------
  always @(posedge clk)
  begin
    if (!rst_n)
      irda_data <= 16'd0;
    else if ((data_cnt ==6'd32) & irda_reg1) begin
      led1 <= get_data[7:0];   // Data supplementation
      led2 <= get_data[15:8];  // Data code
      led3 <= get_data[23:16]; // User code
      led4 <= get_data[31:24];
    end
  end
 
  // Displays the key pressed on the IR remote control on the BCD 7-segment displays.
  always @(led2) 
  begin
		if (!rst_n) begin
			// cmd_value <= 8'd0;
			led_db    <= 8'hFF;
		end else if (received_packet) begin
			// cmd_value <= led2;
		  case(led2)
		    // IR remote control code: BCD-to-7-segment decoding
		    8'b01101000: led_db = 8'b1100_0000; // 0 
		    8'b00110000: led_db = 8'b1111_1001; // 1 
		    8'b00011000: led_db = 8'b1010_0100; // 2
		    8'b01111010: led_db = 8'b1011_0000; // 3
		    8'b00010000: led_db = 8'b1001_1001; // 4
		    8'b00111000: led_db = 8'b1001_0010; // 5
		    8'b01011010: led_db = 8'b1000_0010; // 6
		    8'b01000010: led_db = 8'b1111_1000; // 7
		    8'b01001010: led_db = 8'b1000_0000; // 8
		    8'b01010010: led_db = 8'b1001_0000; // 9
//		    8'b00100010: led_db = 8'b0111_1111; // Left
//		    8'b00000010: led_db = 8'b1011_1111; // Right
//		    8'b11000010: led_db = 8'b0011_1111; // Play
		    default:     led_db = led2;
		  endcase
		end
  end
  
  always @(posedge clk) 
  begin
    if (!rst_n)
		stop_music <= 1'b0;
    
    if (received_packet && (led2 == 8'b11000010))
      stop_music <= ~stop_music;
    
    if (received_packet && (led2 == 8'b00100010) && (stop_music == 1'b1)) begin
      case (sel)
        3'b000 : sel <= 3'b100;
        3'b001 : sel <= 3'b000;
        3'b010 : sel <= 3'b001;
        3'b011 : sel <= 3'b010;
        3'b100 : sel <= 3'b011;
      endcase
    end
    
    if (received_packet && (led2 == 8'b00000010) && (stop_music == 1'b1)) begin
      case (sel)
        3'b000 : sel <= 3'b001;
        3'b001 : sel <= 3'b010;
        3'b010 : sel <= 3'b011;
        3'b011 : sel <= 3'b100;
        3'b100 : sel <= 3'b000;
      endcase
    end
	 
	 if (received_packet && (led2 == 8'b10100010))
		mode <= 2'b00;
	 if (received_packet && (led2 == 8'b01100010))
		mode <= 2'b01;
	 if (received_packet && (led2 == 8'b11100010))
		mode <= 2'b10;
  end

endmodule 
