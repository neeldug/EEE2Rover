module RLE_Dumb_System(
input CLK,
input[23:0] pixelin,
output reg[23:0] pixelout,
output im_reset,
output [9:0] stream1,stream2,stream3 //debug outs
);

reg bit;
wire decode_out;
wire[7:0] red,green,blue;

assign red = pixelin[7:0];
assign green = pixelin[13:7];
assign blue = pixelin[23:14];


always @(*)
begin
	bit <= !( (red==0) && (green == 0) && (blue == 0) ); // always 1 except if all pixel content is 0. placeholder.
	pixelout <= decode_out ? {8'hff, 8'h0, 8'h0} : {8'h0, 8'h0, 8'h0}; //pixel out always red. placeholder.
end

RLE_Dumb_Encoder Encoder(
.CLK(CLK),
.pixelin(bit),
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
// FURTHERMORE, WHITE STREAKS NEAR THE EDGE SCREW THINGS UP HORRIBLY.
// TODO: INTEGRATE ONTO IMAGEPROC
