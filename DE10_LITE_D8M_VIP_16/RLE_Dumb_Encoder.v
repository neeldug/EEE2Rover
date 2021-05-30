module RLE_Dumb_Encoder(
input pixelin,
input CLK,
output reg [9:0]stream1,stream2,stream3,buffer,
output reg im_end);

// THIS DUMB RLE ENCODER PERFORMS DUMB FILTERING BY ONLY KEEPING THE LARGEST SEQUENCES PER LINE.\
// TODO: DELETE ALL SEQUENCES UNDER A CONST TO COMPLETE DUMB FILTERING.

parameter IMAGE_W = 11'd25;

reg prev = 0;
reg[9:0] tally = 0;
reg[10:0] indx = 0;
reg[2:0] num = 0;


always @ (posedge CLK)
begin

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
	case(num) // WE ARE HANDLING REBASING USING NUM -- THIS ASSUMES OUR BLOCK DOESNT END IN BLACK. WONT BE A PROBLEM GENERALLY
				// BUT MIGHT NEED TO BE CHECKED.
		0:
			stream1 <= tally; //WHITE
		3'd1:
			stream2 <= tally; //BLACK
		3'd2:
			stream3 <= tally; //WHITE
		3'd3:
			buffer <= tally; // fill buffer with 2nd black seq
		3'd4: // handle 2nd black seq now.
		begin
			if (buffer > stream2) begin //rebase
				stream1 <= indx-buffer-1;
				stream2 <= buffer;
				tally <= 2;
			end else begin // ignore seq.
				tally <= stream3+buffer+2;
			end
			num <= 2;
			buffer <= 0;
		end
	endcase
end


		
endmodule