module TopModule
(
  input  logic clk,
  input  logic reset,
  input  logic in_valid,
  input  logic [7:0] in_a,
  input  logic [7:0] in_b,
  input  logic [1:0] in_mode,
  output logic out_valid,
  output logic [7:0] out_y,
  output logic [2:0] out_tag
);

  // Register to store the 8-bit input
  logic [7:0] reg_in_a, reg_in_b;
  logic [1:0] reg_in_mode;
  logic reg_in_valid;

  // Buffer stage to stabilize inputs
  logic [7:0] buf_in_a, buf_in_b;
  logic [1:0] buf_in_mode;
  logic buf_in_valid;

  always @(posedge clk) begin
    if (reset) begin
      reg_in_a <= 8'b0;
      reg_in_b <= 8'b0;
      reg_in_mode <= 2'b0;
      reg_in_valid <= 1'b0;
    end else begin
      reg_in_a <= in_a;
      reg_in_b <= in_b;
      reg_in_mode <= in_mode;
      reg_in_valid <= in_valid;
    end
  end

  always @(posedge clk) begin
    buf_in_a <= reg_in_a;
    buf_in_b <= reg_in_b;
    buf_in_mode <= reg_in_mode;
    buf_in_valid <= reg_in_valid;
  end

  // Combinational logic based on mode
  always @(*) begin
    case(buf_in_mode)
      2'b00: out_y = buf_in_a + buf_in_b;
      2'b01: out_y = buf_in_a - buf_in_b;
      2'b10: out_y = buf_in_a & buf_in_b;
      2'b11: out_y = buf_in_a | buf_in_b;
    endcase
    out_valid = buf_in_valid;
    out_tag = {1'b0, buf_in_mode};
  end

endmodule