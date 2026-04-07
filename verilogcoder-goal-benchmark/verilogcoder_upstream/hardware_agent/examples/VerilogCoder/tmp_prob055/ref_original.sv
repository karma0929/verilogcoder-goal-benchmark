module TopModuleRef (
  input  logic [7:0] a,
  input  logic [7:0] b,
  input  logic [7:0] c,
  input  logic [7:0] d,
  output logic [7:0] min
);
  logic [7:0] m1, m2;

  always_comb begin
    m1  = (a < b) ? a : b;
    m2  = (c < d) ? c : d;
    min = (m1 < m2) ? m1 : m2;
  end
endmodule