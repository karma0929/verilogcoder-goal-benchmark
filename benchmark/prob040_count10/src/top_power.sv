module TopModule (
  input  clk,
  input  reset,
  output reg [3:0] q
);
  wire at9 = (q == 4'd9);
  wire [3:0] q_next = at9 ? 4'd0 : (q + 4'd1);

  always @(posedge clk) begin
    if (reset) begin
      q <= 4'd0;
    end else begin
      q <= q_next;
    end
  end
endmodule
