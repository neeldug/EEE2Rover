module RLE_Dumb_Decoder (
    input logic [10:0] stream1,
    stream2,
    stream3,
    input logic CLK,
    input logic new_im,
    input logic enable,
    output logic fifo_in
);

  // THIS CURRENTLY WORKS FOR ANY 3-WORD INPUT. WILL NEED REDESIGN FOR COMPLICATED NON-DETERMINISTIC FILTERS.

  logic [10:0] count = 0;
  logic [ 2:0] num = 0;
  logic [10:0] active_stream;

  logic [10:0]
      reg_stream1,
      reg_stream2,
      reg_stream3 = 11'd1023;  // UNASSAILABLE NUMBER, WILL ENFORCE START AT NEW_IM.

  logic symbol = 0;

  always_latch begin
    if (enable) begin
      case (num)
        2'b00:   active_stream = reg_stream1;
        2'b01:   active_stream = reg_stream2;
        2'b10:   active_stream = reg_stream3;
        default: active_stream = 'bx;
      endcase
    end
  end

  always_ff @(posedge CLK) begin
    if (enable) begin
      if (!new_im) begin  // acts as reset
        if (active_stream == count) begin
          count <= 1;
          num <= num + 1;
          symbol <= !symbol;
        end else count <= count + 1;
      end else begin
        reg_stream1 <= stream1;
        reg_stream2 <= stream2;
        reg_stream3 <= stream3;
        num <= 0;
        count <= 0;
        symbol <= 0;
      end
    end
  end

  assign fifo_in = symbol;
endmodule
