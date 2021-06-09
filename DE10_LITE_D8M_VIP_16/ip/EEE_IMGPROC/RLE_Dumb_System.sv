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
    pixelout = output_symbol ? colour : {
      8'h0, 8'h0, 8'h0
   };
	end

/*
     * Takes largest run of consecutive pixels
     * Output buffer is a line of pixels
     * Now need to take this and defragment it into
     *
     */

    logic im_end;

    parameter minimum_run = 50;

    logic[10:0] largest_run;

    logic[10:0] largest_run_start;

    logic[10:0] pixel_count;

    localparam line_width = 640;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pixel_count <= 'b0;
        end
        else begin
            if (valid_in) begin
                if (pixel_count == line_width-1) begin
                    pixel_count <= 'b0;
                end
                else begin
                    pixel_count <= pixel_count+11'b1;
                end
            end
        end
    end


    logic[10:0] curr_run_start;
    logic[10:0] curr_run_length;

    logic final_pix;

    always_comb begin
        im_end = (pixel_count == 0);
        final_pix = (pixel_count == line_width);
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            largest_run <= 'b0;
            largest_run_start <= 'b0;
            curr_run_start <= 'b0;
            curr_run_length <= 'b0;
        end else begin
            if (valid_in) begin
                if (pixel_count == 0) begin
                    largest_run <= 'b0;
                    largest_run_start <= 'b0;
                    curr_run_start <= 'b0;
                    curr_run_length <= 'b0;
                end
                else begin
                    if (pixel_in) begin
                        if (curr_run_length == 'b0) begin
                            // start new run
                            curr_run_start <= pixel_count;
                            curr_run_length <= 11'b1;
                        end
                        else begin
                            curr_run_length <= curr_run_length+11'b1;
                            // add to curr_run_length
                            if (pixel_count == line_width-1) begin
                                largest_run <= (largest_run < curr_run_length && curr_run_length > minimum_run) ? curr_run_length:largest_run;
                                largest_run_start <= (largest_run < curr_run_length && curr_run_length > minimum_run) ? curr_run_start:largest_run_start;
                            end
                        end
                    end
                    else begin
                        largest_run <= (largest_run < curr_run_length && curr_run_length > minimum_run) ? curr_run_length:largest_run;
                        largest_run_start <= (largest_run < curr_run_length && curr_run_length > minimum_run) ? curr_run_start:largest_run_start;
                        curr_run_length <= 'b0;
                        // run has ended
                    end
                end
            end
        end
    end

    logic [10:0] zeros;
    logic [10:0] ones;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            output_symbol <= 'b0;
        end
        else begin
            if (valid_in) begin
                if (im_end) begin
                    zeros <= largest_run_start - 1;
                    ones <= largest_run - 4;
                end
                else if (final_pix) begin
                    output_symbol <= 1'b0;
                    ones <= 'b0;
                end
                else begin
                    if (zeros != 'b0) begin
                        zeros <= zeros - 1;
                        output_symbol <= 1'b0;
                    end
                    else if (ones != 'b0) begin
                        ones <= ones - 1;
                        output_symbol <= 1'b1;
                    end
                    else begin
                        output_symbol <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
