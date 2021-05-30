module RLE_Dumb_System(
input CLK,
input pixelin,
output decode_out,
output im_reset,
output [9:0] stream1,stream2,stream3
);

wire new_im;


RLE_Dumb_Encoder Encoder(
.CLK(CLK),
.pixelin(pixelin),
.stream1(stream1),
.stream2(stream2),
.stream3(stream3),
.im_end(im_reset)
);

RLE_Dumb_Decoder Decoder(
.CLK(CLK),
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
// FURTHERMORE, WHITE STREAKS NEAR THE EDGE SCREW THINGS UP HORRIBLY.\
// TODO: INTEGRATE ONTO IMAGEPROC
