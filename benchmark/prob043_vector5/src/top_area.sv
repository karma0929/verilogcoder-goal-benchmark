module TopModule (
  input  a,
  input  b,
  input  c,
  input  d,
  input  e,
  output [24:0] out
);
  wire [24:0] rows = { {5{a}}, {5{b}}, {5{c}}, {5{d}}, {5{e}} };
  wire [24:0] cols = {5{a,b,c,d,e}};
  assign out = rows ~^ cols;  // bitwise XNOR
endmodule
