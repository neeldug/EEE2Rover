module RLE_Dumb_Encoder(
input pixelin,
input CLK,
output reg [9:0]stream1,stream2,stream3,
output im_new);

// THIS RLE ENCODER IS SEVERELY CRIPPLED, AND ONLY CONSIDERS THE FIRST 3 STREAKS.
// IT NEEDS SERIOUS OVERHAUL WITH (PROBABLY) AN EMBEDDED FIFO FOR PROPER USAGE.

parameter IMAGE_W = 11'd15;

reg prev = 0;
reg[9:0] tally = 0;
reg[10:0] indx = 0;
reg[1:0] num = 0;

always @ (posedge CLK)
begin
	if (indx != IMAGE_W) begin
		indx <= indx + 1;
		if (pixelin == prev)
			tally <= tally + 1;
		else begin
			tally <= 1;
			case(num)

				0:
					stream1 <= tally;
				2'd1:
					stream2 <= tally;
				2'd2:
					stream3 <= tally;
				default:
					begin
					stream1 <= 0;
					stream2 <= 0;
					stream3 <= 0;
					end
			endcase
			num <= num + 1;
		end
		prev <= pixelin;
	end else begin
		if (stream3 == 0)
			stream3 <= tally;
		indx <= 0;
		num <= 0;
	end
end

assign im_new = (indx == 0);

		
endmodule