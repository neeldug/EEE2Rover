module SPI_slave (
    input logic clk,
    input logic toggle_out,
    input logic SCK,
    input logic MOSI,
    output logic MISO,
    input logic SSEL,
    input logic [319:0] data_in,
    output logic LED
);

  /*
   * Modified version of https://www.fpga4fun.com/SPI1.html
   * Sends bus data of data_in to ESP32 using bitcnt to shift it
   * Setup basic counter to reset the tx flag to pull in fresh data
   * Synchronise Clock detects rising and falling edges of SCK
   * Only need unidirectional communication, so can discard byte_data_received
   */

  logic tx;

  // sync SCK to the FPGA clock using a 3-bits shift register
  logic [2:0] SCKr;
  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
  logic SCK_risingedge;  // now we can detect SCK rising edges
  logic SCK_fallingedge;  // and falling edges

  always_comb begin
    SCK_risingedge  = (SCKr[2:1] == 2'b01);
    SCK_fallingedge = (SCKr[2:1] == 2'b10);
  end

  // same thing for SSEL
  logic [2:0] SSELr;
  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
  logic SSEL_active;
  always_comb SSEL_active = ~SSELr[1];  // SSEL is active low
  logic SSEL_startmessage;
  always_comb SSEL_startmessage = (SSELr[2:1] == 2'b10);  // message starts at falling edge
  logic SSEL_endmessage;
  always_comb SSEL_endmessage = (SSELr[2:1] == 2'b01);  // message stops at rising edge

  // and for MOSI
  logic [1:0] MOSIr;
  always_ff @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  logic MOSI_data;
  always_comb MOSI_data = MOSIr[1];

  // we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
  logic [8:0] bitcnt;

  logic byte_received;  // high when a byte has been received
  logic [7:0] byte_data_received;

  always_ff @(posedge clk) begin
    if (~SSEL_active) bitcnt <= 9'b000000000;
    else if (SCK_risingedge) begin
      if (bitcnt == 9'b100111111) bitcnt <= 'b0;
      else bitcnt <= bitcnt + 'b1;
      // implement a shift-left register (since we receive the data MSB first)
      byte_data_received <= {byte_data_received[7:0], MOSI_data};
    end
  end

  assign tx = (bitcnt == 9'b100111111) | (bitcnt == 'b0);  // pull new data in to SPI

  always_ff @(posedge clk)  // sets high when we've reached the full message
    byte_received <= SSEL_active && SCK_risingedge && (bitcnt == 9'b100111111);

  logic [319:0] byte_data_sent;

  always_ff @(posedge clk) begin
    if (tx) begin
      LED <= 1'b1;
      byte_data_sent <= data_in;
    end else LED <= 1'b0;
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



