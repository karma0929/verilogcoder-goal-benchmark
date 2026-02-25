module miter (
  input clk,
  input load,
  input [9:0] data
);
  wire tc_ref;
  wire tc_dut;

  RefModule u_ref(.clk(clk), .load(load), .data(data), .tc(tc_ref));
  TopModule u_dut(.clk(clk), .load(load), .data(data), .tc(tc_dut));

  always @(posedge clk) begin
    assert(tc_ref == tc_dut);
  end
endmodule
