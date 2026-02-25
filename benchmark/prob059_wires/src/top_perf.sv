module TopModule (
  input  logic a,
  input  logic b,
  input  logic c,
  output logic w,
  output logic x,
  output logic y,
  output logic z
);
  // Pure wires (best timing)
  assign {w,x,y,z} = {a,b,b,c};
endmodule
