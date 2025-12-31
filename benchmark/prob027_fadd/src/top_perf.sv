module TopModule (
  input  a,
  input  b,
  input  cin,
  output cout,
  output sum
);
  wire p = a ^ b;
  assign sum  = p ^ cin;
  assign cout = (a & b) | (p & cin);
endmodule