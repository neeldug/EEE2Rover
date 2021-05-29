module SPI_slave (
    clk,
    toggle_out,
    SCK,
    MOSI,
    MISO,
    SSEL,
    data_in,
    LED
);
  input clk;
  input toggle_out;
  input [63:0] data_in;

  input SCK, SSEL, MOSI;
  output MISO;
  wire tx;

  output LED;

  // sync SCK to the FPGA clock using a 3-bits shift register
  reg [2:0] SCKr;
  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
  wire SCK_risingedge = (SCKr[2:1] == 2'b01);  // now we can detect SCK rising edges
  wire SCK_fallingedge = (SCKr[2:1] == 2'b10);  // and falling edges

  // same thing for SSEL
  reg [2:0] SSELr;
  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
  wire SSEL_active = ~SSELr[1];  // SSEL is active low
  wire SSEL_startmessage = (SSELr[2:1] == 2'b10);  // message starts at falling edge
  wire SSEL_endmessage = (SSELr[2:1] == 2'b01);  // message stops at rising edge

  // and for MOSI
  reg [1:0] MOSIr;
  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  wire MOSI_data = MOSIr[1];

  // we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
  reg [5:0] bitcnt;

  reg byte_received;  // high when a byte has been received
  reg [7:0] byte_data_received;

  always @(posedge clk) begin
    if (~SSEL_active) bitcnt <= 6'b000000;
    else if (SCK_risingedge) begin
      bitcnt <= bitcnt + 6'b00001;

      // implement a shift-left register (since we receive the data MSB first)
      byte_data_received <= {byte_data_received[7:0], MOSI_data};
    end
  end

  assign tx = (bitcnt == {6{1'b1}}) | (bitcnt == 'b0);  // pull new data in to SPI

  always @(posedge clk)
    byte_received <= SSEL_active && SCK_risingedge && (bitcnt == 6'b111111);  // sets high when

  // we use the LSB of the data received to control an LED
  reg LED;
  // always @(posedge clk) if (byte_received) LED <= byte_data_received;

  reg [63:0] byte_data_sent;

  reg [31:0] cnt = 'b0;
  // always @(posedge clk) if(SSEL_startmessage) cnt<=cnt+8'h1;  // count the messages
  always @(posedge clk) begin
    if (tx) begin
		LED <= 1'b1;
        byte_data_sent <= data_in;
    end

    if (SSEL_active & toggle_out) begin
      if (byte_data_received == 8'hff) begin
        byte_data_sent <= {8'b01010101, 56'b0};
      end
      if (SCK_fallingedge) begin
        cnt <= cnt + 1'b1;
        byte_data_sent <= {byte_data_sent[62:0], 1'b0};
      end
    end else begin
      byte_data_sent <= 'b0;
    end
  end

  // always @(posedge clk) LED[2] <= byte_data_sent[7];
  // send MSB first
  assign MISO = byte_data_sent[63];
  // we assume that there is only one slave on the SPI bus
  // so we don't bother with a tri-state buffer for MISO
  // otherwise we would need to tri-state MISO when SSEL is inactive


endmodule



