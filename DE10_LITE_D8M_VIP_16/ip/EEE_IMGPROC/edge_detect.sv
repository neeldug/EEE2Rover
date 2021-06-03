module edge_detect (
    input clk,
    input rst,
    input valid_in,
    input [8:0] hue,
    input [7:0] value,
    output reg edge_detected
);

    /*
     * Detects edges by checking gradient changes of brightness over consecutive pixels
     * In case of anomalous cases we check against two differences
     * Check previous pixel and previous previous pixel difference to current pixel to determine differential
     * Set arbitrary adjacency thresholds
     */

  logic   [15:0] prev_values;
  logic   [ 7:0] curr_value;
  logic [ 7:0] prev_det;
  logic [ 7:0] prev_prev_det;

  parameter adjacent_threshold = 6;
  parameter next_adjacent_threshold = 9;

  assign prev_det = (value>prev_values[7:0]) ? value - prev_values[7:0] : prev_values[7:0] - value;
  assign prev_prev_det = (value>prev_values[15:8]) ? value - prev_values[15:8] : prev_values[15:8] - value;

  logic [10:0] pixel_count;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pixel_count <= 'b0;
        end
        else begin
            if (valid_in) begin
                if (pixel_count == 639) pixel_count <= 'b0;
                else pixel_count <= pixel_count + 'b1;
            end
        end
    end


  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      prev_values <= 'b0;
    end else begin
      if (valid_in) begin
          if (pixel_count == 'b0 | pixel_count == 'b1) begin
              edge_detected <= 1'b0;
              prev_values <= 'b0;
          end
        else begin
            edge_detected <= (prev_det > adjacent_threshold | prev_prev_det > next_adjacent_threshold) & (hue < 30 || hue > 315);
            prev_values <= prev_values << 8;
            prev_values[7:0] <= value;
        end
      end
    end
  end

endmodule