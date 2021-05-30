module RLE_Dumb_Encoder(
input pixelin,
input CLK,
output reg [9:0]stream1,stream2,stream3,
output reg im_end);

// THIS RLE ENCODER IS SEVERELY CRIPPLED, AND ONLY CONSIDERS THE FIRST 3 STREAKS.
// IT NEEDS SERIOUS OVERHAUL WITH (PROBABLY) AN EMBEDDED FIFO FOR PROPER USAGE.

parameter IMAGE_W = 11'd25;

reg prev = 0;
reg[9:0] tally = 0;
reg[10:0] indx = 0;
reg[1:0] num = 0;

always @ (posedge CLK)
begin
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
	if (indx != IMAGE_W) begin
		if (indx==0) begin
			stream1 <= 0;
			stream2 <= 0;
			stream3 <= 0;
		end
		im_end <= 0;
		indx <= indx + 1;
		if (pixelin == prev) begin
			tally <= tally + 1;
		end else begin
			tally <= 1;
			num <= num + 1;
		end

		prev <= pixelin;
	end else begin
		indx <= 0;
		num <= 0;
		im_end <= 1;
		prev <= 0;
		tally <= 0;
	end
end


		
endmodule