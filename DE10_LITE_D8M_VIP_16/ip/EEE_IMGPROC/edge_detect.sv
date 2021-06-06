module edge_detect (
    input logic clk,
    input logic rst,
    input logic valid_in,
    input logic [8:0] hue,
    input logic [7:0] value,
    output logic edge_detected
);

  /*
     * Detects edges by checking gradient changes of brightness over consecutive pixels
     * In case of anomalous cases we check against two differences
     * Check previous pixel and previous previous pixel difference to current pixel to determine differential
     * Set arbitrary adjacency thresholds
     */

  logic [15:0] prev_values;
  logic [ 7:0] curr_value;
  logic [ 7:0] prev_det;
  logic [ 7:0] prev_prev_det;
  logic [ 1:0] moving_average_previous;


  localparam integer AdjacentThreshold = 3;
  localparam integer NextAdjacentThreshold = 5;

  assign prev_det = (value>prev_values[7:0]) ? value - prev_values[7:0] : prev_values[7:0] - value;
  assign prev_prev_det = (value>prev_values[15:8]) ? value - prev_values[15:8] : prev_values[15:8] - value;

  logic [10:0] pixel_count;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      pixel_count <= 'b0;
    end else begin
      if (valid_in) begin
        if (pixel_count == 639) pixel_count <= 'b0;
        else pixel_count <= pixel_count + 11'b00000000001;
      end
    end
  end


  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      prev_values <= 'b0;
      moving_average_previous <= 'b0;
    end else begin
      if (valid_in) begin
        if (pixel_count == 'b0 | pixel_count == 'b1) begin
          moving_average_previous <= 'b0;
          prev_values <= 'b0;
        end else begin
          moving_average_previous <= {
            moving_average_previous[0],
            ((prev_det > AdjacentThreshold | prev_prev_det > NextAdjacentThreshold) & (hue < 30 | hue > 315))
          };
          prev_values <= prev_values << 8;
          prev_values[7:0] <= value;
        end
        edge_detected <= moving_average_previous[1] & moving_average_previous[0];
      end
    end
  end

endmodule
