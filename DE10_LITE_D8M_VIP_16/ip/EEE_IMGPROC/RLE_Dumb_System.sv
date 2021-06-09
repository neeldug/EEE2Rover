module RLE_Dumb_System (
    input logic CLK,
    input logic enable,
    input logic [23:0] pixelin,
    input logic [23:0] colour,
    output logic [23:0] pixelout,
    output logic im_reset,
    output logic [10:0] stream1,
    stream2,
    stream3  //debug outs
);

  logic bit_in;
  logic decode_out;
  logic [7:0] red, green, blue;

  assign red   = pixelin[7:0];
  assign green = pixelin[13:7];
  assign blue  = pixelin[23:14];


  always_comb begin
    bit_in = !( (red==0) && (green == 0) && (blue == 0) ); // always 1 except if all pixel content is 0. placeholder.
    pixelout = decode_out ? colour : {
      8'h0, 8'h0, 8'h0
    };
  end


  RLE_Dumb_Encoder Encoder (
      .CLK(CLK),
      .pixelin(bit_in),
      .enable(enable),
      .stream1(stream1),
      .stream2(stream2),
      .stream3(stream3),
      .im_end(im_reset)
  );

  RLE_Dumb_Decoder Decoder (
      .CLK(CLK),
      .enable(enable),
      .stream1(stream1),
      .stream2(stream2),
      .stream3(stream3),
      .new_im(im_reset),
      .fifo_in(decode_out)
  );

endmodule

// CURRENT PROBLEM:
// SEPARATION! THE STATE-MACHINE-LIKE ENCODER CANNOT RELIABLY HANDLE RAPIDLY CHANGING STREAKS IN CLOSE PROXIMITY.
// POTENTIALLY UNSOLVEABLE PROBLEM. REQUIRES LOOKING INTO.
// FURTHERMORE, WHITE STREAKS NEAR THE EDGE SCREW THINGS UP HORRIBLY.
