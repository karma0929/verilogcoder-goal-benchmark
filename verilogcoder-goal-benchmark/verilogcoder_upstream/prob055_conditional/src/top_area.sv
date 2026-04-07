module TopModule (
  input  logic [7:0] a,
  input  logic [7:0] b,
  input  logic [7:0] c,
  input  logic [7:0] d,
  output logic [7:0] min
);
  logic [7:0] m1, m2;

  assign m1 = (a < b) ? a : b;
  assign m2 = (c < d) ? c : d;
  assign min = (m1 < m2) ? m1 : m2;
endmodule
