module RLE_Encoder(
input pixelin,
input CLK,
output stream);

reg prev;
reg[9:0] count;

always @ (posedge CLK)
begin
	if (pixelin == prev)
		begin
			