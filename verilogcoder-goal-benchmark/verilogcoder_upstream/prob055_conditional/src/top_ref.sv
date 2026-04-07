module TopModule (
  input  logic [7:0] a,
  input  logic [7:0] b,
  input  logic [7:0] c,
  input  logic [7:0] d,
  output logic [7:0] min
);

  always_comb begin
    min = a;
    if (min > b) min = b;
    if (min > c) min = c;
    if (min > d) min = d;
  end

endmodule
