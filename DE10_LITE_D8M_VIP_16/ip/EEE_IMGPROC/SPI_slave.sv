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
  always_ff @(posedge clk) SCKr <= {SCKr[1:0], SCK};
  logic SCK_risingedge;  // now we can detect SCK rising edges
  logic SCK_fallingedge;  // and falling edges

  always_comb begin
    SCK_risingedge  = (SCKr[2:1] == 2'b01);
    SCK_fallingedge = (SCKr[2:1] == 2'b10);
  end

  // same thing for SSEL
  logic [2:0] SSELr;
  always_ff @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
  logic SSEL_active;
  always_comb SSEL_active = ~SSELr[1];  // SSEL is active low

  // and for MOSI
  logic [1:0] MOSIr;
  always_ff @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  logic MOSI_data;
  always_comb MOSI_data = MOSIr[1];

  logic [319:0] byte_data_sent;

  always_ff @(posedge clk) begin
    if (~SSEL_active) begin
      LED <= 1'b1;
      byte_data_sent <= data_in;  // fetch new data when SSEL is not active
    end else LED <= 1'b0;
    if (SSEL_active & toggle_out) begin
      if (SCK_fallingedge) begin
        byte_data_sent <= {byte_data_sent[318:0], 1'b0};
      end
    end else begin
      byte_data_sent <= 'b0;
    end
  end

  // send MSB first
  assign MISO = byte_data_sent[319];
  // we assume that there is only one slave on the SPI bus
  // so we don't bother with a tri-state buffer for MISO
  // otherwise we would need to tri-state MISO when SSEL is inactive


endmodule



