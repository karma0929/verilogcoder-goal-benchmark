module TopModule (
  input  a,
  input  b,
  input  c,
  input  d,
  input  e,
  output [24:0] out
);
  // compact vector form (regular structure, avoids extra intermediate ops)
  assign out = ~({ {5{a}}, {5{b}}, {5{c}}, {5{d}}, {5{e}} } ^ {5{a,b,c,d,e}});
endmodule
