module rle_filter (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic pixel_in,
    output logic output_symbol
);

  /*
     * Takes largest run of consecutive pixels
     * Output buffer is a line of pixels
     * Now need to take this and defragment it into
     *
     */

  logic im_end;

  localparam byte MinimumRun = 20;

  logic [10:0] largest_run;

  logic [10:0] largest_run_start;

  logic [10:0] pixel_count;

  parameter shortint IMAGE_W = 640;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      pixel_count <= 'b0;
    end else begin
      if (valid_in) begin
        if (pixel_count == LINE_WIDTH- 1) begin
          pixel_count <= 'b0;
        end else begin
          pixel_count <= pixel_count + 11'b00000000001;
        end
      end
    end
  end


  logic [10:0] curr_run_start;
  logic [10:0] curr_run_length;

  logic final_pix;

  always_comb begin
    im_end = (pixel_count == 0);
    final_pix = (pixel_count == LINE_WIDTH);
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
        end else begin
          if (pixel_in) begin
            if (curr_run_length == 'b0) begin
              // start new run
              curr_run_start  <= pixel_count;
              curr_run_length <= 11'b00000000001;
            end else begin
              curr_run_length <= curr_run_length + 11'b00000000001;
              // add to curr_run_length
              if (pixel_count == LINE_WIDTH- 1) begin
                largest_run <= (largest_run < curr_run_length && curr_run_length > MinimumRun) ? curr_run_length:largest_run;
                largest_run_start <= (largest_run < curr_run_length && curr_run_length > MinimumRun) ? curr_run_start:largest_run_start;
              end
            end
          end else begin
            largest_run <= (largest_run < curr_run_length && curr_run_length > MinimumRun) ? curr_run_length:largest_run;
            largest_run_start <= (largest_run < curr_run_length && curr_run_length > MinimumRun) ? curr_run_start:largest_run_start;
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
    end else begin
      if (valid_in) begin
        if (im_end) begin
          zeros <= largest_run_start;
          ones  <= largest_run;
        end else if (final_pix) begin
          output_symbol <= 1'b0;
          ones <= 'b0;
        end else begin
          if (zeros != 'b0) begin
            zeros <= zeros - 1;
            output_symbol <= 1'b0;
          end else if (ones != 'b0) begin
            ones <= ones - 1;
            output_symbol <= 1'b1;
          end else begin
            output_symbol <= 1'b0;
          end
        end
      end
    end
  end

endmodule
