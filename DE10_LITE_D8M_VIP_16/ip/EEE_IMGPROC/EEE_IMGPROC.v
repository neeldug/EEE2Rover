module EEE_IMGPROC (
    // global clock & reset
    clk,
    reset_n,

    // mm slave
    s_chipselect,
    s_read,
    s_write,
    s_readdata,
    s_writedata,
    s_address,

    // stream sink
    sink_data,
    sink_valid,
    sink_ready,
    sink_sop,
    sink_eop,

    // streaming source
    source_data,
    source_valid,
    source_ready,
    source_sop,
    source_eop,

    // conduit
    mode,

    // SPI
    LED,
    MISO,
    MOSI,
    SCK,
    SSEL,
    toggle_out,

    // switches
    red_switch,
    blue_switch,
    yellow_switch,
    green_switch,
    pink_switch
);


  // global clock & reset
  input clk;
  input reset_n;

  // mm slave
  input s_chipselect;
  input s_read;
  input s_write;
  output	reg [31:0] s_readdata;
  input [31:0] s_writedata;
  input [2:0] s_address;


  // streaming sink
  input [23:0] sink_data;
  input sink_valid;
  output sink_ready;
  input sink_sop;
  input sink_eop;

  // streaming source
  output [23:0] source_data;
  output source_valid;
  input source_ready;
  output source_sop;
  output source_eop;

  // conduit export
  input mode;

  // SPI
  output LED;
  output MISO;
  input MOSI;
  input SCK;
  input SSEL;
  input toggle_out;

  // Switches
  input red_switch;
  input blue_switch;
  input yellow_switch;
  input green_switch;
  input pink_switch;

  ////////////////////////////////////////////////////////////////////////
  //
  parameter IMAGE_W = 11'd640;
  parameter IMAGE_H = 11'd480;
  parameter MESSAGE_BUF_MAX = 256;
  parameter MSG_INTERVAL = 6;
  parameter BB_COL_DEFAULT = 24'h00ff00;


  wire [7:0] red, green, blue, grey, black;
  wire [8:0] hue;
  wire [7:0] sat, val;
  wire [7:0] red_out, green_out, blue_out;

  wire sop, eop, in_valid, out_ready;
  ////////////////////////////////////////////////////////////////////////

  // Detect red areas
  wire red_detect;

  // Detect blue areas
  wire blue_detect;

  // Detect pink areas
  wire pink_detect;

  // Detect green areas
  wire green_detect;

  // Detect yellow areas
  wire yellow_detect;

  assign red_detect = ((hue < 20 || hue > 340) && val > 95 && sat > 46) ? 1'b1 : 1'b0;
  assign blue_detect = ((hue < 240 && hue > 200) && val > 60) ? 1'b1 : 1'b0;
  assign pink_detect = ((hue < 310 && hue > 90) && sat < 102) ? 1'b1 : 1'b0;  // todo: fix this
  assign green_detect = ((hue < 170 && hue > 150) && sat > 40) ? 1'b1 : 1'b0;
  assign yellow_detect = 1'b0;  //todo: implement yellow threshold
  // Find boundary of cursor box

  // Highlight detected areas
  wire [23:0] red_high;
  wire [23:0] blue_high;
  wire [23:0] pink_high;
  wire [23:0] green_high;
  wire [23:0] yellow_high;

  assign grey  = green[7:1] + red[7:2] + blue[7:2];  //Grey = green/2 + red/4 + blue/4
  assign black = 0;

  wire [7:0] sw_colour = 0 ? grey : black;  //todo: change later.

  assign red_high = red_detect ? {8'hff, 8'h0, 8'h0} : {sw_colour, sw_colour, sw_colour};
  assign blue_high = blue_detect ? {8'h0, 8'h0, 8'hff} : {sw_colour, sw_colour, sw_colour};
  assign pink_high = pink_detect ? {8'hff, 8'hc0, 8'hcb} : {sw_colour, sw_colour, sw_colour};
  assign green_high = green_detect ? {8'h00, 8'hff, 8'h00} : {sw_colour, sw_colour, sw_colour};
  assign yellow_high = yellow_detect ? {8'hff, 8'hff, 8'h00} : {sw_colour, sw_colour, sw_colour};

  // Show bounding box
  wire [23:0] new_image;
  wire bb_active;
  assign bb_active = (x == left) | (x == right) | (y == top) | (y == bottom);

  wire [23:0] red_high_rle;
  wire [23:0] blue_high_rle;
  wire [23:0] pink_high_rle;
  wire [23:0] green_high_rle;
  wire [23:0] yellow_high_rle;

  reg [23:0] active_high_rle;

  always @(*) begin
	  if (red_switch) active_high_rle = red_high_rle;
	  else if (blue_switch) active_high_rle = blue_high_rle;
	  else if (pink_switch) active_high_rle = pink_high_rle;
	  else if (green_switch) active_high_rle = green_high_rle;
	  else if (yellow_switch) active_high_rle = yellow_high_rle;
	  else active_high_rle = red_high_rle;
  end

  assign new_image = bb_active ? bb_col : active_high_rle;

  // Switch output pixels depending on mode switch
  // Don't modify the start-of-packet word - it's a packet discriptor
  // Don't modify data in non-video packets
  assign {red_out, green_out, blue_out} = (mode & ~sop & packet_video) ? new_image : {
    red, green, blue
  };

  //Count valid pixels to tget the image coordinates. Reset and detect packet type on Start of Packet.
  reg [10:0] x, y;
  reg packet_video;
  always @(posedge clk) begin
    if (sop) begin
      x <= 11'h0;
      y <= 11'h0;
      packet_video <= (blue[3:0] == 3'h0);  // Signifies its a video packet
    end else if (in_valid) begin
      if (x == IMAGE_W - 1) begin
        // if reach border, i.e. x has reached max, reset x to zero and increment y
        x <= 11'h0;
        y <= y + 11'h1;
      end else begin
        x <= x + 11'h1;
        // otherwise increment x
      end
    end
  end

  //Find first and last red pixels
  reg [10:0] red_x_min, red_y_min, red_x_max, red_y_max;
  reg [10:0] blue_x_min, blue_y_min, blue_x_max, blue_y_max;
  reg [10:0] pink_x_min, pink_y_min, pink_x_max, pink_y_max;
  reg [10:0] green_x_min, green_y_min, green_x_max, green_y_max;
  reg [10:0] yellow_x_min, yellow_y_min, yellow_x_max, yellow_y_max;
  always @(posedge clk) begin
    if (in_valid) begin  //Update bounds when the pixel is red
      if (red_high_rle) begin
        if (x < red_x_min) red_x_min <= x;
        if (x > red_x_max) red_x_max <= x;
        if (y < red_y_min) red_y_min <= y;
        if (y > red_y_max) red_y_max <= y;
      end
      if (blue_high_rle) begin
        if (x < blue_x_min) blue_x_min <= x;
        if (x > blue_x_max) blue_x_max <= x;
        if (y < blue_y_min) blue_y_min <= y;
        if (y > blue_y_max) blue_y_max <= y;
      end
      if (pink_high_rle) begin
        if (x < pink_x_min) pink_x_min <= x;
        if (x > pink_x_max) pink_x_max <= x;
        if (y < pink_y_min) pink_y_min <= y;
        if (y > pink_y_max) pink_y_max <= y;
      end
      if (green_high_rle) begin
        if (x < green_x_min) green_x_min <= x;
        if (x > green_x_max) green_x_max <= x;
        if (y < green_y_min) green_y_min <= y;
        if (y > green_y_max) green_y_max <= y;
      end
      if (yellow_high_rle) begin
        if (x < yellow_x_min) yellow_x_min <= x;
        if (x > yellow_x_max) yellow_x_max <= x;
        if (y < yellow_y_min) yellow_y_min <= y;
        if (y > yellow_y_max) yellow_y_max <= y;
      end
    end
    if (sop & in_valid) begin  //Reset bounds on start of packet
      red_x_min <= IMAGE_W - 11'h1;
      red_x_max <= 0;
      red_y_min <= IMAGE_H - 11'h1;
      red_y_max <= 0;

      blue_x_min <= IMAGE_W - 11'h1;
      blue_x_max <= 0;
      blue_y_min <= IMAGE_H - 11'h1;
      blue_y_max <= 0;

      pink_x_min <= IMAGE_W - 11'h1;
      pink_x_max <= 0;
      pink_y_min <= IMAGE_H - 11'h1;
      pink_y_max <= 0;

      green_x_min <= IMAGE_W - 11'h1;
      green_x_max <= 0;
      green_y_min <= IMAGE_H - 11'h1;
      green_y_max <= 0;

      yellow_x_min <= IMAGE_W - 11'h1;
      yellow_x_max <= 0;
      yellow_y_min <= IMAGE_H - 11'h1;
      yellow_y_max <= 0;
    end
  end

  //Process bounding box at the end of the frame.
  reg [1:0] msg_state;
  reg [10:0] left, right, top, bottom;
  reg [7:0] frame_count;
  always @(posedge clk) begin
    if (eop & in_valid & packet_video) begin  //Ignore non-video packets
      //Latch edges for display overlay on next frame
      if (red_switch) begin
          left <= red_x_min;
          right <= red_x_max;
          top <= red_y_min;
          bottom <= red_y_max;
      end
      else if (blue_switch) begin
          left <= blue_x_min;
          right <= blue_x_max;
          top <= blue_y_min;
          bottom <= blue_y_max;
      end
      else if (green_switch) begin
          left <= green_x_min;
          right <= green_x_max;
          top <= green_y_min;
          bottom <= green_y_max;
      end
      else if (yellow_switch) begin
          left <= yellow_x_min;
          right <= yellow_x_max;
          top <= yellow_y_min;
          bottom <= yellow_y_max;
      end
      else if (pink_switch) begin
          left <= pink_x_min;
          right <= pink_x_max;
          top <= pink_y_min;
          bottom <= pink_y_max;
      end
      else begin
          //default red
          left <= red_x_min;
          right <= red_x_max;
          top <= red_y_min;
          bottom <= red_y_max;
      end


      //Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
      frame_count <= frame_count - 1;

      if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX - 3) begin
        msg_state   <= 2'b01;
        frame_count <= MSG_INTERVAL - 1;
      end
    end

    //Cycle through message writer states once started
    if (msg_state != 2'b00) msg_state <= msg_state + 2'b01;

  end

  //Generate output messages for CPU
  reg [31:0] msg_buf_in;
  wire [31:0] msg_buf_out;
  reg msg_buf_wr;
  wire msg_buf_rd, msg_buf_flush;
  wire [7:0] msg_buf_size;
  wire msg_buf_empty;

  `define RED_BOX_MSG_ID "RBB"
  `define BLUE_BOX_MSG_ID "BBB"
  `define PINK_BOX_MSG_ID "PBB"
  `define GREEN_BOX_MSG_ID "GBB"
  `define YELLOW_BOX_MSG_ID "YBB"

  always @(*) begin  //Write words to FIFO as state machine advances
    case (msg_state)
      2'b00: begin
        msg_buf_in = 32'b0;  // why is this necessary if we have no write enable high?
        msg_buf_wr = 1'b0;
      end
      2'b01: begin
        msg_buf_in = `RED_BOX_MSG_ID;  //Message ID
        msg_buf_wr = 1'b1;
      end
      2'b10: begin
        msg_buf_in = {5'b0, red_x_min, 5'b0, red_y_min};  //Top left coordinate
        msg_buf_wr = 1'b1;
      end
      2'b11: begin
        msg_buf_in = {5'b0, red_x_max, 5'b0, red_y_max};  //Bottom right coordinate
        msg_buf_wr = 1'b1;
      end
    endcase
  end

  reg [63:0] data_in;

  always @(posedge clk) begin
    data_in <= {5'b0, red_x_min, 5'b0, red_y_min, 5'b0, red_x_max, 5'b0, red_y_max};
  end




  //Output message FIFO
  MSG_FIFO MSG_FIFO_inst (
      .clock(clk),
      .data(msg_buf_in),
      .rdreq(msg_buf_rd),
      .sclr(~reset_n | msg_buf_flush),
      .wrreq(msg_buf_wr),
      .q(msg_buf_out),
      .usedw(msg_buf_size),
      .empty(msg_buf_empty)
  );


  //Streaming registers to buffer video signal
  STREAM_REG #(
      .DATA_WIDTH(26)
  ) in_reg (
      .clk(clk),
      .rst_n(reset_n),
      .ready_out(sink_ready),
      .valid_out(in_valid),
      .data_out({red, green, blue, sop, eop}),
      .ready_in(out_ready),
      .valid_in(sink_valid),
      .data_in({sink_data, sink_sop, sink_eop})
  );

  STREAM_REG #(
      .DATA_WIDTH(26)
  ) out_reg (
      .clk(clk),
      .rst_n(reset_n),
      .ready_out(out_ready),
      .valid_out(source_valid),
      .data_out({source_data, source_sop, source_eop}),
      .ready_in(source_ready),
      .valid_in(in_valid),
      .data_in({red_out, green_out, blue_out, sop, eop})
  );

  rgb_hsv rgb_hsv_inst (
      .clk(clk),
      .rst(reset_n),
      .red(red),
      .green(green),
      .blue(blue),
      .hue(hue),
      .sat(sat),
      .val(val),
      .valid_in(in_valid)
  );

  SPI_slave SPI_slave_inst (
      .clk(clk),
      .toggle_out(toggle_out),
      .SCK(SCK),
      .MOSI(MOSI),
      .MISO(MISO),
      .data_in(data_in),
      .SSEL(SSEL),
      .LED(LED)
  );

    /////////////////////////////////
    /// RLE Instantiation		 ////
    /////////////////////////////////

  RLE_Dumb_System RLE_Dumb_System_red_inst (
      .CLK(clk),  // input  CLK_sig
      .pixelin(red_high),  // input [23:0] pixelin_sig
      .pixelout(red_high_rle),  // output [23:0] pixelout_sig
      .enable(~sop & packet_video & in_valid)
  );

  RLE_Dumb_System RLE_Dumb_System_blue_inst (
      .CLK(clk),  // input  CLK_sig
      .pixelin(blue_high),  // input [23:0] pixelin_sig
      .pixelout(blue_high_rle),  // output [23:0] pixelout_sig
      .enable(~sop & packet_video & in_valid)
  );

  RLE_Dumb_System RLE_Dumb_System_yellow_inst (
      .CLK(clk),  // input  CLK_sig
      .pixelin(yellow_high),  // input [23:0] pixelin_sig
      .pixelout(yellow_high_rle),  // output [23:0] pixelout_sig
      .enable(~sop & packet_video & in_valid)
  );

  RLE_Dumb_System RLE_Dumb_System_green_inst (
      .CLK(clk),  // input  CLK_sig
      .pixelin(green_high),  // input [23:0] pixelin_sig
      .pixelout(green_high_rle),  // output [23:0] pixelout_sig
      .enable(~sop & packet_video & in_valid)
  );

  RLE_Dumb_System RLE_Dumb_System_pink_inst (
      .CLK(clk),  // input  CLK_sig
      .pixelin(pink_high),  // input [23:0] pixelin_sig
      .pixelout(pink_high_rle),  // output [23:0] pixelout_sig
      .enable(~sop & packet_video & in_valid)
  );

  /////////////////////////////////
  /// Memory-mapped port		 /////
  /////////////////////////////////

  // Addresses
  `define REG_STATUS 0
  `define READ_MSG 1
  `define READ_ID 2
  `define REG_BBCOL 3

  //Status register bits
  // 31:16 - unimplemented
  // 15:8 - number of words in message buffer (read only)
  // 7:5 - unused
  // 4 - flush message buffer (write only - read as 0)
  // 3:0 - unused


  // Process write

  reg [ 7:0] reg_status;
  reg [23:0] bb_col;

  always @(posedge clk) begin
    if (~reset_n) begin
      reg_status <= 8'b0;
      bb_col <= BB_COL_DEFAULT;
    end else begin
      if (s_chipselect & s_write) begin
        if (s_address == `REG_STATUS) reg_status <= s_writedata[7:0];
        if (s_address == `REG_BBCOL) bb_col <= s_writedata[23:0];
      end
    end
  end


  //Flush the message buffer if 1 is written to status register bit 4
  assign msg_buf_flush = (s_chipselect & s_write & (s_address == `REG_STATUS) & s_writedata[4]);


  // Process reads
  reg read_d;  //Store the read signal for correct updating of the message buffer

  // Copy the requested word to the output port when there is a read.
  always @(posedge clk) begin
    if (~reset_n) begin
      s_readdata <= {32'b0};
      read_d <= 1'b0;
    end else if (s_chipselect & s_read) begin
      if (s_address == `REG_STATUS) s_readdata <= {16'b0, msg_buf_size, reg_status};
      if (s_address == `READ_MSG) s_readdata <= {msg_buf_out};
      if (s_address == `READ_ID) s_readdata <= 32'h1234EEE2;
      if (s_address == `REG_BBCOL) s_readdata <= {8'h0, bb_col};
    end

    read_d <= s_read;
  end

  //Fetch next word from message buffer after read from READ_MSG
  assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);



endmodule

