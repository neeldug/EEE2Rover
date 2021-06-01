module BB_Finder(
input eop,
input [10:0]stream1,stream2,stream3,
output reg [10:0]x_min,x_max
);

always @ (*)
	if (!eop) begin
		if (stream2!=0) begin //quit quickly if blank line (majority case)
			
		end
	end else begin
		x_min <= 0;
		x_max <= 0;
	end
endmodule