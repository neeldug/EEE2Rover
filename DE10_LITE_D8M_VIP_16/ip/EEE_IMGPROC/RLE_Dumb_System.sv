module RLE_Dumb_System (
    input logic clk,
    input logic valid_in,
    input logic rst,
    input logic [23:0] pixelin,
    input logic [23:0] colour,
    output logic [23:0] pixelout
);


  // pixelin == 3 8 bit RGB numbers
  // pixel_in = 1 bit bool

  logic output_symbol;
  logic pixel_in;
  logic [7:0] red, green, blue;

  assign red   = pixelin[7:0];
  assign green = pixelin[13:7];
  assign blue  = pixelin[23:14];


  always_comb begin
    pixel_in = !( (red==0) && (green == 0) && (blue == 0) ); // always 1 except if all pixel content is 0. placeholder.
    pixelout = output_symbol ? colour : {8'h0, 8'h0, 8'h0};
  end

  rle_filter my_inst(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .pixel_in(pixel_in)
  );

endmodule
