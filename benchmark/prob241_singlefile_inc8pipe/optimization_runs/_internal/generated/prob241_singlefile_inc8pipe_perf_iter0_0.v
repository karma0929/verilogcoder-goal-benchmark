module TopModule
(
  input  logic       clk,
  input  logic       reset,
  input  logic       in_valid,
  input  logic [7:0] in,
  output logic       out_valid,
  output logic [7:0] out
);

  always @(posedge clk) begin
    if (reset) begin
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out <= 8'd0;
    end else begin
      out <= in + 8'd1;
    end
  end

endmodule