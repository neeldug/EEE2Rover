module rgb_hsv (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] red,
    input  logic [7:0] green,
    input  logic [7:0] blue,
    input  logic       valid_in,
    output logic [8:0] hue,
    output logic [7:0] sat,
    output logic [7:0] val


);

  logic [ 7:0] top;
  logic [13:0] top_60;
  logic [ 2:0] rgb_se;
  logic [ 2:0] rgb_se_n;
  logic [ 7:0] max;
  logic [ 7:0] min;
  logic [ 7:0] max_min;
  logic [ 7:0] sat_m;
  logic [ 7:0] max_n;
  logic [ 7:0] division;

  logic g_b, r_g, r_b;


  assign r_g = (red > green) ? 1'b1 : 1'b0;  // if red dominates green
  assign r_b = (red > blue) ? 1'b1 : 1'b0;  // if red dominates blue
  assign g_b = (green > blue) ? 1'b1 : 1'b0;  // if green dominates blue
  always_ff @(posedge clk or negedge rst) begin
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

  always_ff @(posedge clk or negedge rst) begin
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

  always_comb begin
    division = (max_min > 8'd0) ? top_60 / max_min : 8'd240;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) hue <= 9'd0;

    else begin
      if (valid_in) begin
        case (rgb_se_n)

          3'b000: hue <= 9'd240 - division;

          3'b001: hue <= 9'd120 + division;

          3'b011: hue <= 9'd120 - division;

          3'b100: hue <= 9'd240 + division;

          3'b110: hue <= 9'd360 - division;

          3'b111: hue <= division;

          default hue <= 9'd0;
        endcase
      end
    end
  end


  always_comb begin
    sat_m = (max_n > 8'd0) ? {max_min[7:0], 8'b00000000} / max_n : 8'd0;
  end
  always_ff @(posedge clk or negedge rst) begin
    if (!rst) sat <= 8'd0;
    else if (valid_in) sat <= sat_m;
  end

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) val <= 8'd0;
    else if (valid_in) val <= max_n;
  end
endmodule
