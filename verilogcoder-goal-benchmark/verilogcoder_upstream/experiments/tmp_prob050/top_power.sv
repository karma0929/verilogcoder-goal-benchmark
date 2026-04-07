module TopModule (
  input a,
  input b,
  input c,
  output out
);
  // out is 0 only when a=b=c=0
  assign out = a | b | c;
endmodule
