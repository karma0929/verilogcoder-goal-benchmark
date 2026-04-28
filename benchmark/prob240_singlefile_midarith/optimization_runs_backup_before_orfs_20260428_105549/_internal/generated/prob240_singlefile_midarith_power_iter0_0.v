module TopModule
(
  input  logic        clk,
  input  logic        reset,
  input  logic        in_valid,
  input  logic [15:0] in_a,
  input  logic [15:0] in_b,
  input  logic [1:0]  in_mode,
  output logic        out_valid,
  output logic [31:0] out_y,
  output logic [7:0]  out_tag
);

  logic [7:0] tag_counter;

  always @(posedge clk) begin
    if (reset) begin
      tag_counter <= 8'd0;
    end else if (in_valid) begin
      tag_counter <= tag_counter + 8'd1;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_tag <= 8'd0;
    end else if (in_valid) begin
      out_tag <= tag_counter;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_y <= 32'd0;
    end else if (in_valid) begin
      case (in_mode)
        2'b00: begin
          out_y <= {16'd0, in_a} + {16'd0, in_b};
        end
        2'b01: begin
          out_y <= {16'd0, in_a} * {16'd0, in_b};
        end
        2'b10: begin
          out_y <= {16'd0, in_a} ^ {16'd0, in_b};
        end
        2'b11: begin
          out_y <= ({16'd0, in_a} << 1) + ({16'd0, in_b} << 2);
        end
        default: begin
          out_y <= 32'd0;
        end
      endcase
    end
  end

endmodule