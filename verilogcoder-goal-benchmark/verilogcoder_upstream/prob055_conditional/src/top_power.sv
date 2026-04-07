module TopModule (
  input  logic [7:0] a,
  input  logic [7:0] b,
  input  logic [7:0] c,
  input  logic [7:0] d,
  output logic [7:0] min
);

  logic [7:0] t0, t1, t2;

  // Structured compare-update flow
  assign t0  = (a < b) ? a : b;
  assign t1  = (t0 < c) ? t0 : c;
  assign t2  = (t1 < d) ? t1 : d;
  assign min = t2;

endmodule
