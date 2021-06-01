module rgb_hsv (
    input            clk,
    input            rst,
    input            valid_in,
    input      [7:0] red,
    input      [7:0] green,
    input      [7:0] blue,
    output reg [8:0] hue,
    output reg [7:0] sat,
    output reg [7:0] val
);

  reg [ 7:0] top;
  reg [13:0] top_60;
  reg [ 2:0] rgb_se;
  reg [ 2:0] rgb_se_n;
  reg [ 7:0] max;
  reg [ 7:0] min;
  reg [ 7:0] max_min;
  reg [ 7:0] sat_m;
  reg [ 7:0] max_n;
  reg [ 7:0] division;

  wire g_b, r_g, r_b;


  assign r_g = (red > green) ? 1'b1 : 1'b0;  // if red dominates green
  assign r_b = (red > blue) ? 1'b1 : 1'b0;  // if red dominates blue
  assign g_b = (green > blue) ? 1'b1 : 1'b0;  // if green dominates blue
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      max <= 8'b0;
      min <= 8'b0;
      top <= 8'b0;
      rgb_se <= 3'b010;
    end else begin
      // case structure for dominant colour
      case ({
        r_g, r_b, g_b
      })

        3'b000: begin
          max <= blue;
          min <= red;
          top <= green - red;
          rgb_se <= 3'b000;
        end
        3'b001: begin
          max <= green;
          min <= red;
          top <= blue - red;
          rgb_se <= 3'b001;
        end
        3'b011: begin
          max <= green;
          min <= blue;
          top <= red - blue;
          rgb_se <= 3'b011;
        end
        3'b100: begin
          max <= blue;
          min <= green;
          top <= red - green;
          rgb_se <= 3'b100;
        end
        3'b110: begin
          max <= red;
          min <= green;
          top <= blue - green;
          rgb_se <= 3'b110;
        end
        3'b111: begin
          max <= red;
          min <= blue;
          top <= green - blue;
          rgb_se <= 3'b111;
        end
        default begin
          max <= 8'd0;
          min <= 8'd0;
          top <= 8'd0;
          rgb_se <= 3'b010;
        end
      endcase
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      top_60 <= 14'd0;
      rgb_se_n <= 3'b010;
      max_min <= 8'd0;
      max_n <= 8'd0;
    end else begin
      top_60 <= {top, 6'b000000} - {top, 2'b00};
      rgb_se_n <= rgb_se;
      max_min <= max - min;
      max_n <= max;
    end
  end

  always @(*) begin
    division = (max_min > 8'd0) ? top_60 / max_min : 8'd240;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) hue <= 9'd0;

    else begin
      case (rgb_se_n)

        3'b000: hue <= 9'd240 - division;

        3'b001: hue <= 9'd120 + division;

        3'b011: hue <= 9'd120 - division;

        3'b100: hue <= 9'd240 + division;

        3'b110: hue <= 9'd360 - division;

        3'b111: hue <= division;

        default hue <= 9'b0;
      endcase
    end
  end


  always @(*) begin
    sat_m = (max_n > 8'b0) ? {max_min[7:0], 8'b00000000} / max_n : 8'b0;
  end
  always @(posedge clk or negedge rst) begin
    if (!rst) sat <= 8'b0;
    else sat <= sat_m;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) val <= 8'b0;
    else val <= max_n;
  end
endmodule
