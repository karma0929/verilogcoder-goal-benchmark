module TopModule (
  input  logic a,
  input  logic b,
  input  logic c,
  output logic w,
  output logic x,
  output logic y,
  output logic z
);
  // Minimal wiring
  assign w = a;
  assign x = b;
  assign y = b;
  assign z = c;
endmodule
