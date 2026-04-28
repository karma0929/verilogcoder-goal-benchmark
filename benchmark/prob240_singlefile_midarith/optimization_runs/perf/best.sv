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

  logic [7:0]  issue_tag;
  logic [31:0] add_y;
  logic [31:0] mul_y;
  logic [31:0] xor_y;
  logic [31:0] wsum_y;
  logic [31:0] selected_y;

  assign add_y  = {16'd0, in_a} + {16'd0, in_b};
  assign mul_y  = {16'd0, in_a} * {16'd0, in_b};
  assign xor_y  = {16'd0, in_a} ^ {16'd0, in_b};
  assign wsum_y = ({16'd0, in_a} << 1) + ({16'd0, in_b} << 2);

  assign selected_y = in_mode[1] ? (in_mode[0] ? wsum_y : xor_y)
                                 : (in_mode[0] ? mul_y  : add_y);

  always @(posedge clk) begin
    if (reset) begin
      issue_tag <= 8'd0;
      out_valid <= 1'b0;
      out_y     <= 32'd0;
      out_tag   <= 8'd0;
    end else begin
      out_valid <= in_valid;

      if (in_valid) begin
        out_y     <= selected_y;
        out_tag   <= issue_tag;
        issue_tag <= issue_tag + 8'd1;
      end
    end
  end

endmodule
