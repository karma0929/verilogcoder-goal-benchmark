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

  logic [7:0]  tag_count;
  logic [31:0] a_ext;
  logic [31:0] b_ext;
  logic [31:0] y_calc;

  assign a_ext = {16'd0, in_a};
  assign b_ext = {16'd0, in_b};

  always @(*) begin
    y_calc = 32'd0;
    case (in_mode)
      2'b00: begin
        y_calc = a_ext + b_ext;
      end
      2'b01: begin
        y_calc = a_ext * b_ext;
      end
      2'b10: begin
        y_calc = a_ext ^ b_ext;
      end
      2'b11: begin
        y_calc = (a_ext << 1) + (b_ext << 2);
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      tag_count <= 8'd0;
      out_valid <= 1'b0;
      out_y     <= 32'd0;
      out_tag   <= 8'd0;
    end else begin
      out_valid <= in_valid;
      out_y     <= y_calc;
      out_tag   <= tag_count;
      if (in_valid) begin
        tag_count <= tag_count + 8'd1;
      end
    end
  end

endmodule
