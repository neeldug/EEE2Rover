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
  input [319:0] data_in;

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
  reg [8:0] bitcnt;

  reg byte_received;  // high when a byte has been received
  reg [7:0] byte_data_received;

  always @(posedge clk) begin
    if (~SSEL_active) bitcnt <= 9'b000000000;
    else if (SCK_risingedge) begin
      if (bitcnt == 9'b100111111) bitcnt <= 'b0;
      else bitcnt <= bitcnt + 'b1;
      // implement a shift-left register (since we receive the data MSB first)
      byte_data_received <= {byte_data_received[7:0], MOSI_data};
    end
  end

  assign tx = (bitcnt == 9'b100111111) | (bitcnt == 'b0);  // pull new data in to SPI

  always @(posedge clk)
    byte_received <= SSEL_active && SCK_risingedge && (bitcnt == 9'b100111111);  // sets high when

  // we use the LSB of the data received to control an LED
  reg LED;
  // always @(posedge clk) if (byte_received) LED <= byte_data_received;

  reg [319:0] byte_data_sent;

  always @(posedge clk) begin
    if (tx) begin
		LED <= 1'b1;
        byte_data_sent <= data_in;
    end
    else LED <= 1'b0;
    if (SSEL_active & toggle_out) begin
      if (SCK_fallingedge) begin
        byte_data_sent <= {byte_data_sent[318:0], 1'b0};
      end
    end else begin
      byte_data_sent <= 'b0;
    end
  end

  // always @(posedge clk) LED[2] <= byte_data_sent[7];
  // send MSB first
  assign MISO = byte_data_sent[319];
  // we assume that there is only one slave on the SPI bus
  // so we don't bother with a tri-state buffer for MISO
  // otherwise we would need to tri-state MISO when SSEL is inactive


endmodule



