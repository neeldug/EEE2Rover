module rle_filter(
    input logic clk,
    input logic rst,
    input logic valid_in,
    input logic pixel_in,
    output logic [10:0] stream1, stream2, stream3,
    output logic im_end
);

    /*
     * Takes largest run of consecutive pixels
     * Output buffer is a line of pixels
     * Now need to take this and defragment it into
     *
     */

    parameter minimum_run = 5;

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
                    im_end <= 1'b1;
                end
                else begin
                    pixel_count <= pixel_count+11'b1;
                end
            end
        end
    end


    logic[10:0] curr_run_start;
    logic[10:0] curr_run_length;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            largest_run <= 'b0;
            largest_run_start <= 'b0;
            curr_run_start <= 'b0;
            curr_run_length <= 'b0;
        end else begin
            if (valid_in) begin
                if (pixel_count == 0) begin
                    im_end <= 1'b1;
                    stream1 <= largest_run_start + 1;
                    stream2 <= largest_run;
                    stream3 <= line_width - (largest_run_start + 1 + largest_run);
                    largest_run <= 'b0;
                    largest_run_start <= 'b0;
                    curr_run_start <= 'b0;
                    curr_run_length <= 'b0;
                end
                else begin
                    im_end <= 1'b0;
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

endmodule
