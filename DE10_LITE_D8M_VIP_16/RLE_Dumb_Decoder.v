module RLE_Dumb_Decoder(
input[9:0] stream1,stream2,stream3,
input CLK,
input new_im,
output fifo_in
);

// THIS CURRENTLY WORKS FOR ANY 3-WORD INPUT. WILL NEED REDESIGN FOR COMPLICATED NON-DETERMINISTIC FILTERS.

reg[9:0] count = 0;
reg[2:0] num = 0;
reg[9:0] active_stream;

reg[9:0] reg_stream1,reg_stream2,reg_stream3 = 1023; // UNASSAILABLE NUMBER, WILL ENFORCE START AT NEW_IM.

reg symbol = 0;

always @ (posedge CLK)
begin
	case(num)
		0:
			active_stream <= reg_stream1;
		2'd1:
			active_stream <= reg_stream2;
		2'd2:
			active_stream <= reg_stream3;
		default:
			active_stream <= active_stream;
	endcase
	if (!new_im) begin // acts as reset
		if (active_stream == count) begin
			count <= 1;
			num <= num + 1;
			symbol <= !symbol;
		end else
			count <= count + 1;
	end else begin
		reg_stream1 <= stream1;
		reg_stream2 <= stream2;
		reg_stream3 <= stream3;
		num <= 0;
		count <= 0;
		symbol <= 0;
	end

end

assign fifo_in = symbol;
endmodule