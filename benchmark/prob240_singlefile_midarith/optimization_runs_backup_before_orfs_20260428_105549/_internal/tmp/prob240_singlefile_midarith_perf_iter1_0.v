module TopModule
(
  input  logic       clk,
  input  logic       reset,
  input  logic [7:0] in,
  output logic [7:0] out,
  input  logic       in_valid,
  input  logic [7:0] in_a,
  input  logic [7:0] in_b,
  input  logic       in_mode,
  output logic       out_valid,
  output logic [7:0] out_y,
  output logic       out_tag
);

  // Sequential logic to register the 8-bit input 'in'
  logic [7:0] reg_in;

  always @(posedge clk) begin
    if (reset) begin
      reg_in <= 0;
    end else if (in_valid) begin
      reg_in <= in;
    end
  end

  // Combinational logic to increment the registered value
  always @(*) begin
    out = reg_in + 1;
    if (in_valid) begin
      out_y = reg_in + 1; // Adjusted logic for out_y based on in_valid
    end
    out_valid = in_valid; // Sync out_valid with in_valid
    out_tag = in_mode; // Sync out_tag with in_mode
  end

endmodule